local _, ns = ...

-- Spellbook + catalog probe. The list is kept until the spellbook or a setting changes.
-- A row is any non-passive spell whose tooltip states a heal or an absorb and
-- whose cost is mana. The class catalog only adds unlearned ranks.

local C_Spell = C_Spell
local C_SpellBook = C_SpellBook
local Enum = Enum

local cachedSpells

function ns.InvalidateCache()
	cachedSpells = nil
	ns.spells = nil
	ns.unparsed = nil
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

-- "mana" plus a number, "other" when the cost is rage or energy, "none" when
-- the spell is free, "unknown" when combat hides the cost.
local function ReadManaState(spellID)
	if not (C_Spell and C_Spell.GetSpellPowerCost) then
		return nil, "unknown"
	end
	-- A hidden combat cost throws. That skips the row's number, it does not stop the scan.
	local ok, costs = pcall(C_Spell.GetSpellPowerCost, spellID)
	if not ok or type(costs) ~= "table" or not ns.CanIndex(costs) then
		return nil, "unknown"
	end
	if #costs == 0 then
		return nil, "none"
	end
	local manaType = Enum and Enum.PowerType and Enum.PowerType.Mana
	local sawOther = false
	local sawSecret = false
	for i = 1, #costs do
		local entry = costs[i]
		if ns.CanIndex(entry) then
			local costType = entry.type
			if ns.SecretBlocked(costType) then
				sawSecret = true
			elseif manaType and costType ~= manaType then
				sawOther = true
			else
				local cost = ns.ReadableNumber(entry.cost)
				if cost then
					return cost, "mana"
				end
				sawSecret = true
			end
		else
			sawSecret = true
		end
	end
	if sawOther and not sawSecret then
		return nil, "other"
	end
	if sawSecret then
		return nil, "unknown"
	end
	return nil, "other"
end

local function CostsMana(cost, state)
	if state == "mana" then
		return cost > 0
	end
	return state == "unknown"
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

-- "health" contains the letters of "heal", so strip it before the word test.
local function MentionsHeal(text)
	text = text:lower()
	if text:find("absorb", 1, true) then
		return true
	end
	text = text:gsub("health", "")
	return text:find("heal", 1, true) ~= nil
end

local function AddSpell(list, byID, spell)
	if not spell or byID[spell.id] then
		return
	end
	byID[spell.id] = spell
	list[#list + 1] = spell
end

local function Consider(list, byID, seen, spellID, known, fromBook)
	if seen[spellID] or byID[spellID] then
		return
	end
	seen[spellID] = true
	if C_Spell and C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(spellID) then
		return
	end
	local name = ReadName(spellID)
	local text, source = ns.FetchHealText(spellID)
	local parsed = text and ns.ParseHealText(text)
	if not parsed then
		if fromBook and name and text and MentionsHeal(text) then
			ns.unparsed[#ns.unparsed + 1] = { id = spellID, name = name }
		end
		return
	end
	local cost, state = ReadManaState(spellID)
	if not CostsMana(cost, state) or not name then
		return
	end
	AddSpell(list, byID, {
		id = spellID,
		name = name,
		familyKey = name,
		kind = parsed.kind,
		rank = ReadRank(spellID),
		castSec = ReadCastSec(spellID),
		mana = cost,
		healMin = parsed.min,
		healMax = parsed.max,
		healAvg = parsed.avg,
		icon = ReadIcon(spellID),
		known = known and true or false,
		source = source,
	})
end

local function ScanSpellbook(list, byID, seen)
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
					if type(sid) == "number" then
						local isSpell = not Enum.SpellBookItemType
							or spellType == Enum.SpellBookItemType.Spell
						if isSpell then
							Consider(list, byID, seen, sid, true, true)
						end
					end
				end
			end
		end
	end
end

local function WantUnlearned(entry)
	if not (ns.db and ns.db.showUnlearned) then
		return false
	end
	local token = ns.PlayerClassToken()
	return token ~= nil and token == entry.class
end

local function ProbeCatalog(list, byID, seen)
	for i = 1, #ns.CATALOG do
		local entry = ns.CATALOG[i]
		if not seen[entry.id] and not byID[entry.id] then
			local known = KnownInBook(entry.id)
			if known or WantUnlearned(entry) then
				Consider(list, byID, seen, entry.id, known, false)
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
	local seen = {}
	ns.unparsed = {}
	ScanSpellbook(list, byID, seen)
	ProbeCatalog(list, byID, seen)
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
