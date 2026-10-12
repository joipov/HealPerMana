local _, ns = ...

-- Spellbook + catalog probe. The list is kept until the spellbook or a setting changes.

local C_Spell = C_Spell
local C_SpellBook = C_SpellBook
local Enum = Enum

local familyNames = {}
local cachedSpells

function ns.InvalidateCache()
	familyNames = {}
	cachedSpells = nil
	ns.spells = nil
end

local function FamilyName(family)
	local resolved = familyNames[family.key]
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
			familyNames[family.key] = live
			return live
		end
	end
	return nil
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

local function ReadName(spellID)
	if C_Spell and C_Spell.GetSpellName then
		return ns.ReadableString(C_Spell.GetSpellName(spellID))
	end
	return nil
end

local function ReadCastSec(spellID)
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellID)
		if ns.CanIndex(info) then
			local ms = ns.ReadableNumber(info.castTime)
			if ms then
				return ms / 1000
			end
		end
	end
	return nil
end

local function ReadMana(spellID)
	if not (C_Spell and C_Spell.GetSpellPowerCost) then
		return nil
	end
	local costs = C_Spell.GetSpellPowerCost(spellID)
	if type(costs) ~= "table" or not ns.CanIndex(costs) then
		return nil
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
	return nil
end

local function ReadRank(spellID)
	if C_Spell and C_Spell.GetSpellSubtext then
		local sub = ns.ReadableString(C_Spell.GetSpellSubtext(spellID))
		return ns.ParseRankSubtext(sub)
	end
	return nil
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
	return nil
end

local function ReadHeal(spellID)
	local text, source = ns.FetchHealText(spellID)
	local parsed = text and ns.ParseHealText(text)
	if parsed then
		return parsed.min, parsed.max, parsed.avg, source
	end
	return nil, nil, nil, nil
end

local function MakeSpell(spellID, family, known)
	local minH, maxH, avg, source = ReadHeal(spellID)
	return {
		id = spellID,
		name = ReadName(spellID),
		familyKey = family.key,
		kind = family.kind,
		rank = ReadRank(spellID),
		castSec = ReadCastSec(spellID),
		mana = ReadMana(spellID),
		healMin = minH,
		healMax = maxH,
		healAvg = avg,
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
									end
								end
								if not family and C_Spell and C_Spell.GetSpellName then
									family = LookupFamilyByName(ns.ReadableString(C_Spell.GetSpellName(sid)))
								end
								if family then
									AddSpell(list, byID, MakeSpell(sid, family, true))
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
				AddSpell(list, byID, MakeSpell(entry.id, entry.family, known))
			end
		end
	end
end

local function RankBefore(a, b)
	if a == b then
		return false
	end
	if a == nil then
		return false
	end
	if b == nil then
		return true
	end
	return a < b
end

local function SortSpells(list)
	table.sort(list, function(a, b)
		if a.familyKey ~= b.familyKey then
			return a.familyKey < b.familyKey
		end
		if a.rank ~= b.rank then
			return RankBefore(a.rank, b.rank)
		end
		return a.id < b.id
	end)
end

function ns.ScanSpells()
	local list = {}
	local byID = {}
	familyNames = {}
	ScanSpellbook(list, byID)
	ProbeCatalog(list, byID)
	SortSpells(list)
	cachedSpells = list
	ns.spells = list
	ns.Debug("scanned", #list, "ranks")
	return list
end

function ns.GetSpells()
	if cachedSpells then
		return cachedSpells
	end
	return ns.ScanSpells()
end
