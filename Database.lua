local _, ns = ...

-- SavedVariables: defaults, one-time migrations, load-time validation.
-- Plain Lua so tests/run.lua can exercise it without a client.

local defaults = {
	enabled = true,
	showMinimapButton = true,
	minimapAngle = 160,
	showUnlearned = false,
	debug = false,
	sortKey = "hpm",
	sortAsc = false,
	point = "CENTER",
	relPoint = "CENTER",
	x = 0,
	y = 0,
}

local allowedSort = {
	name = true,
	rank = true,
	cast = true,
	mana = true,
	heal = true,
	hpm = true,
}

-- Bump when a one-time migration is added to MigrateDB.
local DB_VERSION = 3

local function CopyDefaults(db)
	for key, value in pairs(defaults) do
		if type(db[key]) ~= type(value) then
			db[key] = value
		end
	end
	return db
end

local function ClampNumber(value, lo, hi, fallback)
	if type(value) ~= "number" then
		return fallback
	end
	if value < lo then
		return lo
	end
	if value > hi then
		return hi
	end
	return value
end

local function Validate(db)
	if not allowedSort[db.sortKey] then
		db.sortKey = defaults.sortKey
	end
	db.x = ClampNumber(db.x, -2000, 2000, 0)
	db.y = ClampNumber(db.y, -2000, 2000, 0)
	db.minimapAngle = ClampNumber(db.minimapAngle, -360, 360, defaults.minimapAngle)
	db.showMinimapButton = db.showMinimapButton ~= false
	if type(db.minimapIcon) ~= "table" then
		db.minimapIcon = {}
	end
	if type(db.point) ~= "string" or db.point == "" then
		db.point = defaults.point
	end
	if type(db.relPoint) ~= "string" or db.relPoint == "" then
		db.relPoint = defaults.relPoint
	end
end

local leftover = {
	"showHUD", "includeHoT", "includeAoE", "includeAbsorb", "usePlayerMana",
	"deficit", "windowSec", "manaBudget", "goal", "filter",
	"hudPoint", "hudRelPoint", "hudX", "hudY",
	"lastCustomDeficit", "lastCustomWindow",
}

local function MigrateDB(db)
	local version = type(db.version) == "number" and db.version or 0
	if version < 2 then
		if db.sortKey == "fit" or db.sortKey == "hps" then
			db.sortKey = "hpm"
			db.sortAsc = false
		end
		for i = 1, #leftover do
			db[leftover[i]] = nil
		end
	end
	if version < 3 then
		-- The button starts on. Existing saves did not have the key.
		db.showMinimapButton = true
	end
	db.version = DB_VERSION
end

function ns.LoadDB(saved)
	local db = type(saved) == "table" and saved or {}
	MigrateDB(db)
	CopyDefaults(db)
	Validate(db)
	return db
end

ns.DB_DEFAULTS = defaults
ns.DB_VERSION = DB_VERSION
