local _, ns = ...

-- Secret-value guards. Forever hands addons numbers and strings that look
-- like normal Lua values but cannot be compared, added, or used as table
-- keys. type() and truthiness on non-booleans are allowed.

local issecretvalue = issecretvalue
local canaccessvalue = canaccessvalue
local issecrettable = issecrettable
local canaccesstable = canaccesstable

local function Chat(text)
	print("|cffc4b5fdJoipov|r " .. ns.TITLE .. ": " .. tostring(text or ""))
end

function ns.Print(text)
	Chat(text)
end

local function JoinArgs(...)
	local count = select("#", ...)
	local parts = {}
	for i = 1, count do
		parts[i] = tostring(select(i, ...))
	end
	return table.concat(parts, " ")
end

function ns.Debug(...)
	if ns.db and ns.db.debug then
		Chat(JoinArgs(...))
	end
end

function ns.SecretBlocked(value)
	return issecretvalue(value) and not canaccessvalue(value)
end
local SecretBlocked = ns.SecretBlocked

function ns.ReadableString(value)
	if type(value) ~= "string" or SecretBlocked(value) then
		return nil
	end
	if value == "" then
		return nil
	end
	return value
end

function ns.ReadableNumber(value)
	if type(value) ~= "number" or SecretBlocked(value) then
		return nil
	end
	return value
end

function ns.CanIndex(value)
	if value == nil or SecretBlocked(value) then
		return false
	end
	if issecrettable(value) and not canaccesstable(value) then
		return false
	end
	return true
end

-- UnitClass token ("PRIEST") or nil when secret / missing. nil means
-- "unknown", not "not a priest" — the scanner still runs in that case.
function ns.PlayerClassToken()
	local token = select(2, UnitClass("player"))
	return ns.ReadableString(token)
end

function ns.IsPriest()
	local token = ns.PlayerClassToken()
	if not token then
		return nil
	end
	return token == "PRIEST"
end
