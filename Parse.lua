local _, ns = ...

local C_Spell = C_Spell
local C_TooltipInfo = C_TooltipInfo

-- Heal-amount extraction. Regex helpers are pure and tested without a
-- client. Live tooltip / description fetch lives in FetchHealText.
--
-- The client fills $s1-style formulas before we see the text. A party heal
-- stays one target, because the tooltip never states a party size. A bolt
-- count, jump count, or chain falloff is a fixed multiplier, so those add up.

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

local function Normalize(text)
	text = ns.StripInline(text)
	if text == "" then
		return ""
	end
	text = text:gsub("(%d),(%d)", "%1%2")
	text = text:gsub("(%d),(%d)", "%1%2")
	return text:lower()
end

-- "instantly and every X sec for Y sec" is the opening bolt plus one bolt
-- each interval. Penance pays its mana once for that whole channel.
local function ChannelBolts(text)
	local every, dur = text:match("instantly and every (%d+) sec for (%d+) sec")
	every = tonumber(every)
	dur = tonumber(dur)
	if every and dur and every > 0 then
		return 1 + math.floor(dur / every)
	end
	return 1
end

local function Result(lo, hi, kind, duration)
	lo = tonumber(lo)
	hi = tonumber(hi)
	if not lo or not hi or hi < lo or lo <= 0 then
		return nil
	end
	return {
		kind = kind or "range",
		min = lo,
		max = hi,
		avg = (lo + hi) / 2,
		duration = duration,
	}
end

local function Pulse(amount, every, dur)
	amount = tonumber(amount)
	every = tonumber(every)
	dur = tonumber(dur)
	if not amount or not every or not dur or amount <= 0 or every <= 0 or dur <= 0 then
		return nil
	end
	local total = amount * (dur / every)
	return total, total
end

-- Resurrection restores a corpse. It is not a heal on a living target.
local function IsResurrection(text)
	return text:find("back to life", 1, true)
		or text:find("dead target", 1, true)
		or text:find("dead player", 1, true)
end

local function AllyHeal(text)
	local bolts = ChannelBolts(text)
	local lo, hi = text:match("(%d+)%s+to%s+(%d+)%s+healing to an ally")
	if lo then
		return tonumber(lo) * bolts, tonumber(hi) * bolts
	end
	local one = text:match("(%d+)%s+healing to an ally")
	if one then
		one = tonumber(one) * bolts
		return one, one
	end
	return nil
end

-- Each later target is the stated percent of the previous one.
local function ChainHeal(text)
	local targets = tonumber(text:match("(%d+)%s+total targets"))
	local pct = tonumber(text:match("(%d+)%%%s+as effective"))
	if not targets or not pct or targets < 1 then
		return nil
	end
	local lo, hi = text:match("for%s+(%d+)%s+to%s+(%d+)")
	if not lo then
		local one = text:match("for%s+(%d+)")
		if not one then
			return nil
		end
		lo, hi = one, one
	end
	lo, hi = tonumber(lo), tonumber(hi)
	if not lo or not hi then
		return nil
	end
	local ratio = pct / 100
	local factor, step, n = 0, 1, 0
	while n < targets do
		factor = factor + step
		step = step * ratio
		n = n + 1
	end
	return lo * factor, hi * factor
end

-- "Yourself and a friendly target" is two heals for one cast.
local function TwoTarget(text)
	if not text:find("yourself and a friendly", 1, true)
		and not text:find("you and a friendly", 1, true) then
		return nil
	end
	local lo, hi = text:match("for%s+(%d+)%s+to%s+(%d+)")
	if lo then
		return tonumber(lo) * 2, tonumber(hi) * 2
	end
	local one = text:match("for%s+(%d+)")
	if not one or text:match("for%s+" .. one .. "%%") then
		return nil
	end
	one = tonumber(one)
	return one * 2, one * 2
end

-- "Jumps up to N times" is the number of heals, each for the stated amount.
local function JumpHeal(text)
	local jumps = tonumber(text:match("jumps up to%s+(%d+)%s+times"))
	if not jumps or jumps < 1 then
		return nil
	end
	local lo, hi = text:match("heals them for%s+(%d+)%s+to%s+(%d+)")
	if not lo then
		local one = text:match("heals them for%s+(%d+)")
		if not one or text:match("heals them for%s+" .. one .. "%%") then
			return nil
		end
		lo, hi = one, one
	end
	lo, hi = tonumber(lo), tonumber(hi)
	return lo * jumps, hi * jumps
end

local function Periodic(text)
	local mins, amount, every = text:match("for%s+(%d+)%s+min.-(%d+)%s+every%s+(%d+)%s+sec")
	if mins then
		local dur = tonumber(mins) * 60
		return Pulse(amount, every, dur)
	end
	amount, every, mins = text:match("(%d+)%s+every%s+(%d+)%s+sec%s+over%s+(%d+)")
	if amount then
		return Pulse(amount, every, mins)
	end
	amount, every, mins = text:match("(%d+)%s+every%s+(%d+)%s+sec%s+for%s+(%d+)%s+sec")
	if amount then
		return Pulse(amount, every, mins)
	end
	amount, every, mins = text:match("(%d+)%s+health.-every%s+(%d+)%s+sec.-lasts%s+(%d+)")
	if amount then
		return Pulse(amount, every, mins)
	end
	amount, mins = text:match("(%d+)%s+health every second.-lasts%s+(%d+)")
	if amount then
		return Pulse(amount, 1, mins)
	end
	return nil
end

local function ChargeHeal(text)
	local amount = text:match("heal the shielded target for%s+(%d+)")
	local charges = text:match("(%d+)%s+charges")
	if not amount or not charges then
		return nil
	end
	if text:match("for%s+" .. amount .. "%%") then
		return nil
	end
	amount = tonumber(amount) * tonumber(charges)
	return amount, amount
end

-- Direct, trailing HoT, and absorb on one tooltip are one cast.
local function Components(text)
	local lo, hi = 0, 0
	local kind, duration, parts = nil, nil, 0

	local function add(a, b, k, dur)
		a, b = tonumber(a), tonumber(b)
		if not a or not b or b < a or a <= 0 then
			return
		end
		lo = lo + a
		hi = hi + b
		parts = parts + 1
		if not kind then
			kind = k
			duration = dur
		else
			if kind ~= k then
				kind = "range"
			end
			duration = nil
		end
	end

	local function consume(pat, apply)
		local startAt = 1
		while true do
			local s, e, a, b = text:find(pat, startAt)
			if not s then
				return
			end
			if text:sub(s, e + 1):find("%d%%", 1) then
				startAt = s + 1
			else
				apply(a, b)
				local mid = text:sub(s, e):gsub("%d", " ")
				text = text:sub(1, s - 1) .. mid .. text:sub(e + 1)
				startAt = s
			end
		end
	end

	consume("heal%a*.-for%s+(%d+)%s+to%s+(%d+)", function(a, b)
		add(a, b, "range")
	end)
	consume("another%s+(%d+)%s+over%s+(%d+)", function(a, b)
		add(a, a, "hot", tonumber(b))
	end)
	consume("additional%s+(%d+)%s+over%s+(%d+)", function(a, b)
		add(a, a, "hot", tonumber(b))
	end)
	consume("for%s+(%d+)%s+health%s+over%s+(%d+)", function(a, b)
		add(a, a, "hot", tonumber(b))
	end)
	consume("of%s+(%d+)%s+damage%s+over%s+(%d+)", function(a, b)
		add(a, a, "hot", tonumber(b))
	end)
	consume("for%s+(%d+)%s+over%s+(%d+)", function(a, b)
		add(a, a, "hot", tonumber(b))
	end)
	consume("(%d+)%s+over%s+(%d+)", function(a, b)
		add(a, a, "hot", tonumber(b))
	end)
	consume("absorb%a*%s+a maximum of%s+(%d+)", function(a)
		add(a, a, "absorb")
	end)
	consume("absorb%a*%s+(%d+)", function(a)
		add(a, a, "absorb")
	end)
	consume("heal%a*.-for%s+(%d+)", function(a)
		add(a, a, "range")
	end)

	if parts == 0 then
		return nil
	end
	return lo, hi, kind, duration
end

-- Returns { kind, min, max, avg, duration } or nil.
-- kind is "range", "hot", or "absorb". A mixed tooltip reports "range".
function ns.ParseHealText(text)
	if type(text) ~= "string" or text == "" then
		return nil
	end
	text = Normalize(text)
	if text == "" or IsResurrection(text) then
		return nil
	end

	local lo, hi = AllyHeal(text)
	if lo then
		return Result(lo, hi, "range")
	end
	lo, hi = ChainHeal(text)
	if lo then
		return Result(lo, hi, "range")
	end
	lo, hi = TwoTarget(text)
	if lo then
		return Result(lo, hi, "range")
	end
	lo, hi = JumpHeal(text)
	if lo then
		return Result(lo, hi, "range")
	end
	lo, hi = Periodic(text)
	if lo then
		return Result(lo, hi, "hot")
	end
	lo, hi = ChargeHeal(text)
	if lo then
		return Result(lo, hi, "range")
	end

	local kind, duration
	lo, hi, kind, duration = Components(text)
	if not lo then
		return nil
	end
	return Result(lo, hi, kind, duration)
end

-- Concatenate tooltip left-text lines. Uses C_TooltipInfo, never a GameTooltipTemplate.
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
