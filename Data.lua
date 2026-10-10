local _, ns = ...

ns.TITLE = "Heal Per Mana Table"
ns.VERSION = "1.1.0"
ns.GCD = 1.5
ns.HOT_TICKS = 5

ns.KIND_DIRECT = "direct"
ns.KIND_HOT = "hot"
ns.KIND_AOE = "aoe"
ns.KIND_ABSORB = "absorb"

-- English family names used when the live API has no name yet. Localized
-- names are resolved from the first catalog spell ID at scan time.
ns.FAMILIES = {
	LESSER_HEAL = {
		key = "LESSER_HEAL",
		name = "Lesser Heal",
		kind = ns.KIND_DIRECT,
		core = true,
	},
	HEAL = {
		key = "HEAL",
		name = "Heal",
		kind = ns.KIND_DIRECT,
		core = true,
	},
	GREATER_HEAL = {
		key = "GREATER_HEAL",
		name = "Greater Heal",
		kind = ns.KIND_DIRECT,
		core = true,
	},
	FLASH_HEAL = {
		key = "FLASH_HEAL",
		name = "Flash Heal",
		kind = ns.KIND_DIRECT,
		core = true,
	},
	RENEW = {
		key = "RENEW",
		name = "Renew",
		kind = ns.KIND_HOT,
		core = false,
	},
	PRAYER_OF_HEALING = {
		key = "PRAYER_OF_HEALING",
		name = "Prayer of Healing",
		kind = ns.KIND_AOE,
		core = false,
	},
	HOLY_NOVA = {
		key = "HOLY_NOVA",
		name = "Holy Nova",
		kind = ns.KIND_AOE,
		core = false,
	},
	POWER_WORD_SHIELD = {
		key = "POWER_WORD_SHIELD",
		name = "Power Word: Shield",
		kind = ns.KIND_ABSORB,
		core = false,
	},
}

-- Catalog numbers are Classic-era fallbacks only. Live tooltip/description
-- always wins. Tagged "est." in the UI when used.
-- { id, family, rank, mana, castSec, healMin, healMax, hotDuration }
local catalog = {
	-- Lesser Heal
	{ 2050, "LESSER_HEAL", 1, 47, 1.5, 46, 56 },
	{ 2052, "LESSER_HEAL", 2, 76, 2.0, 71, 85 },
	{ 2053, "LESSER_HEAL", 3, 116, 2.5, 135, 157 },
	-- Heal
	{ 2054, "HEAL", 1, 187, 3.0, 295, 341 },
	{ 2055, "HEAL", 2, 245, 3.0, 429, 491 },
	{ 6063, "HEAL", 3, 305, 3.0, 604, 682 },
	{ 6064, "HEAL", 4, 365, 3.0, 754, 848 },
	-- Greater Heal
	{ 2060, "GREATER_HEAL", 1, 370, 3.0, 899, 1013 },
	{ 10963, "GREATER_HEAL", 2, 455, 3.0, 1149, 1289 },
	{ 10964, "GREATER_HEAL", 3, 545, 3.0, 1437, 1609 },
	{ 10965, "GREATER_HEAL", 4, 655, 3.0, 1796, 2006 },
	{ 25314, "GREATER_HEAL", 5, 710, 3.0, 1966, 2194 },
	-- Flash Heal
	{ 2061, "FLASH_HEAL", 1, 125, 1.5, 193, 221 },
	{ 9472, "FLASH_HEAL", 2, 155, 1.5, 258, 294 },
	{ 9473, "FLASH_HEAL", 3, 185, 1.5, 327, 371 },
	{ 9474, "FLASH_HEAL", 4, 215, 1.5, 400, 452 },
	{ 10915, "FLASH_HEAL", 5, 265, 1.5, 518, 582 },
	{ 10916, "FLASH_HEAL", 6, 315, 1.5, 644, 724 },
	{ 10917, "FLASH_HEAL", 7, 380, 1.5, 812, 912 },
	-- Renew (total over 15s, 5 ticks)
	{ 139, "RENEW", 1, 30, 0, 45, 45, 15 },
	{ 6074, "RENEW", 2, 65, 0, 100, 100, 15 },
	{ 6075, "RENEW", 3, 105, 0, 175, 175, 15 },
	{ 6076, "RENEW", 4, 140, 0, 245, 245, 15 },
	{ 6077, "RENEW", 5, 170, 0, 315, 315, 15 },
	{ 6078, "RENEW", 6, 205, 0, 400, 400, 15 },
	{ 10927, "RENEW", 7, 250, 0, 510, 510, 15 },
	{ 10928, "RENEW", 8, 305, 0, 650, 650, 15 },
	{ 10929, "RENEW", 9, 365, 0, 810, 810, 15 },
	{ 25315, "RENEW", 10, 410, 0, 970, 970, 15 },
	-- Prayer of Healing (per target)
	{ 596, "PRAYER_OF_HEALING", 1, 410, 3.0, 312, 333 },
	{ 996, "PRAYER_OF_HEALING", 2, 560, 3.0, 458, 487 },
	{ 10960, "PRAYER_OF_HEALING", 3, 770, 3.0, 675, 713 },
	{ 10961, "PRAYER_OF_HEALING", 4, 1030, 3.0, 939, 991 },
	{ 25316, "PRAYER_OF_HEALING", 5, 1070, 3.0, 1041, 1099 },
	-- Holy Nova
	{ 15237, "HOLY_NOVA", 1, 185, 0, 54, 63 },
	{ 15430, "HOLY_NOVA", 2, 290, 0, 89, 101 },
	{ 15431, "HOLY_NOVA", 3, 400, 0, 124, 140 },
	{ 27799, "HOLY_NOVA", 4, 520, 0, 165, 184 },
	{ 27800, "HOLY_NOVA", 5, 635, 0, 202, 224 },
	{ 27801, "HOLY_NOVA", 6, 750, 0, 239, 264 },
	-- Power Word: Shield (absorb)
	{ 17, "POWER_WORD_SHIELD", 1, 45, 0, 44, 44 },
	{ 592, "POWER_WORD_SHIELD", 2, 80, 0, 88, 88 },
	{ 600, "POWER_WORD_SHIELD", 3, 130, 0, 158, 158 },
	{ 3747, "POWER_WORD_SHIELD", 4, 175, 0, 234, 234 },
	{ 6065, "POWER_WORD_SHIELD", 5, 210, 0, 301, 301 },
	{ 6066, "POWER_WORD_SHIELD", 6, 250, 0, 381, 381 },
	{ 10898, "POWER_WORD_SHIELD", 7, 300, 0, 484, 484 },
	{ 10899, "POWER_WORD_SHIELD", 8, 355, 0, 605, 605 },
	{ 10900, "POWER_WORD_SHIELD", 9, 425, 0, 763, 763 },
	{ 10901, "POWER_WORD_SHIELD", 10, 500, 0, 942, 942 },
}

ns.CATALOG = {}
ns.CATALOG_BY_ID = {}
ns.FAMILY_BY_NAME = {}

for _, family in pairs(ns.FAMILIES) do
	ns.FAMILY_BY_NAME[family.name] = family
end

for i = 1, #catalog do
	local row = catalog[i]
	local familyKey = row[2]
	local entry = {
		id = row[1],
		familyKey = familyKey,
		family = ns.FAMILIES[familyKey],
		rank = row[3],
		mana = row[4],
		castSec = row[5],
		healMin = row[6],
		healMax = row[7],
		hotDuration = row[8],
	}
	ns.CATALOG[#ns.CATALOG + 1] = entry
	ns.CATALOG_BY_ID[entry.id] = entry
end
