local _, ns = ...

-- Spellbook + catalog probe. Builds ns.spells. Cached until InvalidateCache.

local C_Spell = C_Spell
local C_SpellBook = C_SpellBook
local Enum = Enum

local cache = {
	spells = {},
	byID = {},
	familyNames = {},
	valid = false,
}

function ns.InvalidateCache()
	cache.valid = false
	cache.spells = {}
	cache.byID = {}
end

local function FamilyName(family)
	local resolved = cache.familyNames[family.key]
	if resolved then
		return resolved
	end
	local firstID
	for i = 1, #ns.CATALOG do
		local entry = ns.CATALOG[i]
		if entry.familyKey == family.key then
			firstID = entry.id
			break
		end
	end
	if firstID and C_Spell and C_Spell.GetSpellName then
		local live = ns.ReadableString(C_Spell.GetSpellName(firstID))
		if live then
			cache.familyNames[family.key] = live
			return live
		end
	end
	return family.name
end

local function LookupFamilyByName(name)
	if not name then
		return nil
	end
	local direct = ns.FAMILY_BY_NAME[name]
	if direct then
		return direct
	end
	for _, family in pairs(ns.FAMILIES) do
		if FamilyName(family) == name then
			return family
		end
	end
	return nil
end

local function KnownInBook(spellID)
	if not C_SpellBook or not C_SpellBook.IsSpellInSpellBook then
		return false
	end
	local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
	if bank then
		if C_SpellBook.IsSpellInSpellBook(spellID, bank, true) then
			return true
		end
	elseif C_SpellBook.IsSpellInSpellBook(spellID) then
		return true
	end
	if C_Spell and C_Spell.GetBaseSpell then
		local base = ns.ReadableNumber(C_Spell.GetBaseSpell(spellID))
		if base and base ~= spellID then
			if bank then
				return C_SpellBook.IsSpellInSpellBook(base, bank, true) and true or false
			end
			return C_SpellBook.IsSpellInSpellBook(base) and true or false
		end
	end
	return false
end

local function ReadCastSec(spellID, fallback)
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellID)
		if ns.CanIndex(info) then
			local ms = ns.ReadableNumber(info.castTime)
			if ms then
				return ms / 1000
			end
		end
	end
	return fallback
end

local function ReadMana(spellID, fallback)
	if not (C_Spell and C_Spell.GetSpellPowerCost) then
		return fallback
	end
	local costs = C_Spell.GetSpellPowerCost(spellID)
	if type(costs) ~= "table" or not ns.CanIndex(costs) then
		return fallback
	end
	local manaType = Enum and Enum.PowerType and Enum.PowerType.Mana
	for i = 1, #costs do
		local entry = costs[i]
		if ns.CanIndex(entry) then
			local costType = entry.type
			if not ns.SecretBlocked(costType) and (not manaType or costType == manaType) then
				local cost = ns.ReadableNumber(entry.cost)
				if cost then
					return cost
				end
			end
		end
	end
	return fallback
end

local function ReadRank(spellID, fallback)
	if C_Spell and C_Spell.GetSpellSubtext then
		local sub = ns.ReadableString(C_Spell.GetSpellSubtext(spellID))
		local rank = ns.ParseRankSubtext(sub)
		if rank then
			return rank
		end
	end
	return fallback
end

local function ReadIcon(spellID)
	if C_Spell and C_Spell.GetSpellTexture then
		local icon = C_Spell.GetSpellTexture(spellID)
		if type(icon) == "number" or type(icon) == "string" then
			if not ns.SecretBlocked(icon) then
				return icon
			end
		end
	end
	return 135913
end

local function HealFromLiveOrCatalog(spellID, catalogEntry, family)
	local text, source = ns.FetchHealText(spellID)
	local parsed = text and ns.ParseHealText(text)
	if parsed then
		local duration = parsed.duration
		if family.kind == ns.KIND_HOT and not duration and catalogEntry then
			duration = catalogEntry.hotDuration
		end
		return parsed.min, parsed.max, parsed.avg, duration, source
	end
	if catalogEntry then
		local minH = catalogEntry.healMin
		local maxH = catalogEntry.healMax
		return minH, maxH, (minH + maxH) / 2, catalogEntry.hotDuration, "catalog"
	end
	return nil, nil, nil, nil, nil
end

local function MakeSpell(spellID, family, rank, known, catalogEntry)
	local name = FamilyName(family)
	if C_Spell and C_Spell.GetSpellName then
		local live = ns.ReadableString(C_Spell.GetSpellName(spellID))
		if live then
			name = live
		end
	end
	local fallbackCast = catalogEntry and catalogEntry.castSec or 0
	local fallbackMana = catalogEntry and catalogEntry.mana or 0
	local fallbackRank = rank or (catalogEntry and catalogEntry.rank)
	local minH, maxH, avg, duration, source = HealFromLiveOrCatalog(spellID, catalogEntry, family)
	if not avg then
		return nil
	end
	return {
		id = spellID,
		name = name,
		familyKey = family.key,
		kind = family.kind,
		rank = fallbackRank or 0,
		castSec = ReadCastSec(spellID, fallbackCast),
		mana = ReadMana(spellID, fallbackMana),
		healMin = minH,
		healMax = maxH,
		healAvg = avg,
		hotDuration = duration,
		hotTicks = ns.HOT_TICKS,
		icon = ReadIcon(spellID),
		known = known and true or false,
		source = source,
	}
end

local function AddSpell(list, byID, spell)
	if not spell or byID[spell.id] then
		return
	end
	byID[spell.id] = spell
	list[#list + 1] = spell
end

local function ScanSpellbook(list, byID)
	if not C_SpellBook then
		return
	end
	local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
	if not bank or not C_SpellBook.GetNumSpellBookSkillLines then
		return
	end
	local numTabs = C_SpellBook.GetNumSpellBookSkillLines() or 0
	for tab = 1, numTabs do
		local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(tab)
		if ns.CanIndex(lineInfo) and not lineInfo.shouldHide then
			local offSpec = lineInfo.offSpecID
			if not offSpec or offSpec == 0 then
				local offset = lineInfo.itemIndexOffset or 0
				local count = lineInfo.numSpellBookItems or 0
				for si = offset + 1, offset + count do
					local spellType, actionId, spellId = C_SpellBook.GetSpellBookItemType(si, bank)
					local sid = spellId or actionId
					if type(sid) == "number" and not byID[sid] then
						local isSpell = not Enum.SpellBookItemType
							or spellType == Enum.SpellBookItemType.Spell
						if isSpell then
							local passive = C_Spell and C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(sid)
							if not passive then
								local catalogEntry = ns.CATALOG_BY_ID[sid]
								local family = catalogEntry and catalogEntry.family
								if not family and C_Spell and C_Spell.GetBaseSpell then
									local base = ns.ReadableNumber(C_Spell.GetBaseSpell(sid))
									local baseEntry = base and ns.CATALOG_BY_ID[base]
									if baseEntry then
										family = baseEntry.family
										catalogEntry = catalogEntry or baseEntry
									end
								end
								if not family and C_Spell and C_Spell.GetSpellName then
									family = LookupFamilyByName(ns.ReadableString(C_Spell.GetSpellName(sid)))
								end
								if family then
									local rank = ReadRank(sid, catalogEntry and catalogEntry.rank)
									AddSpell(list, byID, MakeSpell(sid, family, rank, true, catalogEntry))
								end
							end
						end
					end
				end
			end
		end
	end
end

local function ProbeCatalog(list, byID)
	for i = 1, #ns.CATALOG do
		local entry = ns.CATALOG[i]
		if not byID[entry.id] then
			local known = KnownInBook(entry.id)
			if known or (ns.db and ns.db.showUnlearned) then
				AddSpell(list, byID, MakeSpell(entry.id, entry.family, entry.rank, known, entry))
			end
		end
	end
end

local function SortSpells(list)
	table.sort(list, function(a, b)
		if a.familyKey ~= b.familyKey then
			return a.familyKey < b.familyKey
		end
		if a.rank ~= b.rank then
			return a.rank < b.rank
		end
		return a.id < b.id
	end)
end

function ns.ScanSpells()
	if cache.valid then
		return cache.spells
	end
	local list = {}
	local byID = {}
	cache.familyNames = {}
	ScanSpellbook(list, byID)
	ProbeCatalog(list, byID)
	SortSpells(list)
	cache.spells = list
	cache.byID = byID
	cache.valid = true
	ns.spells = list
	ns.Debug("scanned", #list, "ranks")
	return list
end

function ns.GetSpells()
	return ns.ScanSpells()
end
