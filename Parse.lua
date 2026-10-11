local _, ns = ...

-- Heal-amount extraction. Regex helpers are pure and tested without a
-- client. Live tooltip / description fetch lives in FetchHealText.

function ns.StripInline(text)
	if type(text) ~= "string" then
		return ""
	end
	return text
		:gsub("|c%x%x%x%x%x%x%x%x", "")
		:gsub("|r", "")
		:gsub("|T.-|t", "")
		:gsub("|A.-|a", "")
end

function ns.ParseRankSubtext(text)
	text = ns.StripInline(text)
	local rank = text:match("(%d+)")
	if rank then
		return tonumber(rank)
	end
	return nil
end

-- Penance pays mana once for the whole channel. "instantly and every X sec
-- for Y sec" is the opening bolt plus one bolt each interval.
local function ChannelBolts(text)
	local every, dur = text:match("instantly and every (%d+) sec for (%d+) sec")
	every = tonumber(every)
	dur = tonumber(dur)
	if every and dur and every > 0 then
		return 1 + math.floor(dur / every)
	end
	return 1
end

-- Returns { kind, min, max, avg, duration } or nil.
-- kind is "range", "hot", or "absorb".
function ns.ParseHealText(text)
	if type(text) ~= "string" or text == "" then
		return nil
	end
	text = ns.StripInline(text)

	-- Before the "N to N" match. Penance names the damage first
	-- ("42 Holy damage to an enemy, or 126 healing to an ally"), and Holy Nova
	-- and Prayer of Healing name their damage before the group heal.
	local groupMin, groupMax = text:match("healing.-for%s+(%d+)%s+to%s+(%d+)")
	if groupMin then
		groupMin = tonumber(groupMin)
		groupMax = tonumber(groupMax)
		if groupMin and groupMax and groupMax >= groupMin then
			return {
				kind = "range",
				min = groupMin,
				max = groupMax,
				avg = (groupMin + groupMax) / 2,
			}
		end
	end

	local ally = text:match("(%d+)%s+healing to an ally")
	if ally then
		ally = tonumber(ally)
		if ally then
			local total = ally * ChannelBolts(text)
			return {
				kind = "range",
				min = total,
				max = total,
				avg = total,
			}
		end
	end

	local minH, maxH = text:match("(%d+)%s+to%s+(%d+)")
	if minH then
		minH = tonumber(minH)
		maxH = tonumber(maxH)
		if minH and maxH and maxH >= minH then
			return {
				kind = "range",
				min = minH,
				max = maxH,
				avg = (minH + maxH) / 2,
			}
		end
	end

	-- Renew reads "Heals the target of 45 damage over 15 sec", so the number
	-- is not always flush against "over".
	local hot, duration = text:match("(%d+)%D-over%s+(%d+)")
	if hot then
		hot = tonumber(hot)
		duration = tonumber(duration)
		if hot and duration and duration > 0 then
			return {
				kind = "hot",
				min = hot,
				max = hot,
				avg = hot,
				duration = duration,
			}
		end
	end

	local absorb = text:match("[Aa]bsorb%a*%s+(%d+)")
	if absorb then
		absorb = tonumber(absorb)
		if absorb then
			return {
				kind = "absorb",
				min = absorb,
				max = absorb,
				avg = absorb,
			}
		end
	end

	local one = text:match("[Hh]eals.-for%s+(%d+)")
	if one then
		one = tonumber(one)
		if one then
			return {
				kind = "range",
				min = one,
				max = one,
				avg = one,
			}
		end
	end

	return nil
end

-- Concatenate tooltip left-text lines. Shared with the item scanner in
-- EllesmereUI QoL: C_TooltipInfo, never a GameTooltipTemplate.
local function TooltipLinesToText(data)
	if not ns.CanIndex(data) or type(data.lines) ~= "table" then
		return nil
	end
	if TooltipUtil and TooltipUtil.SurfaceArgs then
		TooltipUtil.SurfaceArgs(data)
	end
	local parts = {}
	for i = 1, #data.lines do
		local line = data.lines[i]
		if ns.CanIndex(line) then
			local left = ns.ReadableString(line.leftText)
			if left then
				parts[#parts + 1] = left
			end
		end
	end
	if #parts == 0 then
		return nil
	end
	return table.concat(parts, " ")
end

function ns.FetchHealText(spellID)
	if type(spellID) ~= "number" then
		return nil, nil
	end
	local C_Spell = C_Spell
	local C_TooltipInfo = C_TooltipInfo
	if C_Spell and C_Spell.GetSpellLink and C_TooltipInfo and C_TooltipInfo.GetHyperlink then
		local link = C_Spell.GetSpellLink(spellID)
		link = ns.ReadableString(link)
		if link then
			local data = C_TooltipInfo.GetHyperlink(link)
			local text = TooltipLinesToText(data)
			if text then
				return text, "tooltip"
			end
		end
	end
	if C_Spell and C_Spell.GetSpellDescription then
		local desc = ns.ReadableString(C_Spell.GetSpellDescription(spellID))
		if desc then
			return desc, "description"
		end
	end
	return nil, nil
end
