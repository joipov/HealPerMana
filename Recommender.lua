local _, ns = ...

-- Pure HPM and sort. No WoW API. tests/run.lua loads this file directly.

function ns.HealPerMana(spell)
	local mana = spell and spell.mana or 0
	local heal = spell and spell.healAvg or 0
	if mana <= 0 or heal <= 0 then
		return 0
	end
	return heal / mana
end

function ns.SortValue(spell, key)
	if key == "name" then
		return spell.name or ""
	end
	if key == "rank" then
		return spell.rank or 0
	end
	if key == "cast" then
		return spell.castSec or 0
	end
	if key == "mana" then
		return spell.mana or 0
	end
	if key == "heal" then
		return spell.healAvg or 0
	end
	return ns.HealPerMana(spell)
end

function ns.SortSpellsBy(spells, key, asc)
	table.sort(spells, function(a, b)
		local va = ns.SortValue(a, key)
		local vb = ns.SortValue(b, key)
		if va == vb then
			if a.rank == b.rank then
				return (a.id or 0) < (b.id or 0)
			end
			return (a.rank or 0) < (b.rank or 0)
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
	local name = spell.name or "Heal"
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
