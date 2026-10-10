local _, ns = ...

-- Pure HPM and sort. No WoW API. tests/run.lua loads this file directly.

function ns.HealPerMana(spell)
	if not spell then
		return nil
	end
	local mana = spell.mana
	local heal = spell.healAvg
	if type(mana) ~= "number" or type(heal) ~= "number" then
		return nil
	end
	if mana <= 0 or heal <= 0 then
		return nil
	end
	return heal / mana
end

function ns.SortValue(spell, key)
	if key == "name" then
		local name = spell.name
		if type(name) ~= "string" or name == "" then
			return nil
		end
		return name
	end
	if key == "rank" then
		return spell.rank
	end
	if key == "cast" then
		return spell.castSec
	end
	if key == "mana" then
		return spell.mana
	end
	if key == "heal" then
		return spell.healAvg
	end
	return ns.HealPerMana(spell)
end

local function TieBreak(a, b)
	local ar, br = a.rank, b.rank
	if ar == br then
		return (a.id or 0) < (b.id or 0)
	end
	if ar == nil then
		return false
	end
	if br == nil then
		return true
	end
	return ar < br
end

function ns.SortSpellsBy(spells, key, asc)
	table.sort(spells, function(a, b)
		local va = ns.SortValue(a, key)
		local vb = ns.SortValue(b, key)
		if va == vb then
			return TieBreak(a, b)
		end
		if va == nil then
			return false
		end
		if vb == nil then
			return true
		end
		if asc then
			return va < vb
		end
		return va > vb
	end)
end

function ns.CastName(spell)
	if not spell then
		return ""
	end
	local name = spell.name
	if type(name) ~= "string" or name == "" then
		return ""
	end
	local rank = spell.rank
	if type(rank) == "number" and rank > 0 then
		return name .. "(Rank " .. rank .. ")"
	end
	return name
end

function ns.MacroText(spell)
	local cast = ns.CastName(spell)
	if cast == "" then
		return ""
	end
	return "#showtooltip " .. cast .. "\n/cast [@mouseover] " .. cast .. "; " .. cast
end
