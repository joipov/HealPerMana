-- Unit tests for the pure parts of Heal Per Mana.
--   luajit tests/run.lua
--   lua5.1 tests/run.lua
-- Files that create frames (UI.lua, Events.lua, Options.lua) are not loaded.

local root = (arg and arg[0] or "tests/run.lua"):match("^(.*)[/\\]tests[/\\]") or "."

issecretvalue = function() return false end
canaccessvalue = function() return true end
issecrettable = function() return false end
canaccesstable = function() return true end
C_Spell = {}
C_SpellBook = {}
C_TooltipInfo = {}
C_Timer = { After = function() end }
Enum = {
	SpellBookSpellBank = { Player = 0 },
	SpellBookItemType = { Spell = 0 },
	PowerType = { Mana = 0 },
}
TooltipUtil = nil
UnitClass = function() return "Priest", "PRIEST" end
UnitPower = function() return 2000 end

local ns = {}
local function load(file)
	local chunk, err = loadfile(root .. "/" .. file)
	assert(chunk, err)
	chunk("HealPerMana", ns)
end

load("Data.lua")
load("Locales/enUS.lua")
load("Locales.lua")
load("Secrets.lua")
load("Database.lua")
load("Parse.lua")
load("Recommender.lua")

local passed, failed = 0, 0

local function eq(actual, expected, label)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s", label or "value", tostring(expected), tostring(actual)), 2)
	end
end

local function near(actual, expected, label)
	if type(actual) ~= "number" or math.abs(actual - expected) > 0.01 then
		error(string.format("%s: expected %s, got %s", label or "value", tostring(expected), tostring(actual)), 2)
	end
end

local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed = passed + 1
	else
		failed = failed + 1
		print("FAIL " .. name .. ": " .. tostring(err))
	end
end

-- Parse -----------------------------------------------------------------------

test("StripInline removes colors and textures", function()
	eq(ns.StripInline("|cffff0000Heal|r"), "Heal")
	eq(ns.StripInline("|TInterface\\Icons\\x:16|tFlash"), "Flash")
end)

test("ParseHealText range", function()
	local p = ns.ParseHealText("Heals a friendly target for 295 to 341.")
	eq(p.kind, "range")
	eq(p.min, 295)
	eq(p.max, 341)
	near(p.avg, 318)
end)

test("ParseHealText HoT", function()
	local p = ns.ParseHealText("Heals 45 over 15 sec.")
	eq(p.kind, "hot")
	eq(p.avg, 45)
	eq(p.duration, 15)
end)

test("ParseHealText absorb", function()
	local p = ns.ParseHealText("Absorbs 440 damage.")
	eq(p.kind, "absorb")
	eq(p.avg, 440)
end)

test("ParseHealText single heal", function()
	local p = ns.ParseHealText("Heals a friendly target for 318.")
	eq(p.min, 318)
	eq(p.max, 318)
end)

test("ParseHealText rejects empty", function()
	eq(ns.ParseHealText(""), nil)
	eq(ns.ParseHealText(nil), nil)
end)

test("ParseRankSubtext", function()
	eq(ns.ParseRankSubtext("Rank 3"), 3)
	eq(ns.ParseRankSubtext("|cffaaaaaaRank 10|r"), 10)
	eq(ns.ParseRankSubtext(""), nil)
end)

-- Secrets ---------------------------------------------------------------------

test("ReadableNumber and ReadableString", function()
	eq(ns.ReadableNumber(12), 12)
	eq(ns.ReadableNumber("12"), nil)
	eq(ns.ReadableString("Heal"), "Heal")
	eq(ns.ReadableString(""), nil)
end)

test("IsPriest when UnitClass is readable", function()
	eq(ns.IsPriest(), true)
end)

-- Database --------------------------------------------------------------------

test("LoadDB fills defaults", function()
	local db = ns.LoadDB(nil)
	eq(db.sortKey, "hpm")
	eq(db.sortAsc, false)
	eq(db.showUnlearned, false)
	eq(db.version, ns.DB_VERSION)
end)

test("LoadDB rejects bad sort keys", function()
	local db = ns.LoadDB({ sortKey = "fit" })
	eq(db.sortKey, "hpm")
end)

test("LoadDB migrates leftover planner keys", function()
	local db = ns.LoadDB({
		version = 1,
		sortKey = "hps",
		deficit = 800,
		showHUD = true,
	})
	eq(db.sortKey, "hpm")
	eq(db.deficit, nil)
	eq(db.showHUD, nil)
	eq(db.version, 2)
end)

-- HPM / sort ------------------------------------------------------------------

local flash4 = { id = 9474, name = "Flash Heal", rank = 4, castSec = 1.5, mana = 215, healAvg = 426 }
local heal3 = { id = 6063, name = "Heal", rank = 3, castSec = 3, mana = 305, healAvg = 643 }
local gh1 = { id = 2060, name = "Greater Heal", rank = 1, castSec = 3, mana = 370, healAvg = 956 }

test("HealPerMana is heal / mana", function()
	near(ns.HealPerMana(flash4), 426 / 215)
	near(ns.HealPerMana(heal3), 643 / 305)
	eq(ns.HealPerMana({ mana = 0, healAvg = 100 }), 0)
end)

test("SortSpellsBy HPM descending puts Greater Heal first", function()
	local list = { heal3, flash4, gh1 }
	ns.SortSpellsBy(list, "hpm", false)
	eq(list[1].id, 2060)
	eq(list[3].id, 9474)
end)

test("SortSpellsBy mana ascending", function()
	local list = { gh1, heal3, flash4 }
	ns.SortSpellsBy(list, "mana", true)
	eq(list[1].id, 9474)
	eq(list[3].id, 2060)
end)

test("MacroText is a mouseover macro", function()
	eq(ns.MacroText(heal3), "#showtooltip Heal(Rank 3)\n/cast [@mouseover] Heal(Rank 3); Heal(Rank 3)")
	eq(ns.MacroText({ name = "Renew", rank = 0 }), "#showtooltip Renew\n/cast [@mouseover] Renew; Renew")
end)

if failed > 0 then
	print(string.format("%d passed, %d failed", passed, failed))
	os.exit(1)
end
print(string.format("%d passed", passed))
