local _, ns = ...

ns.TITLE = "Heal Per Mana Table"
ns.VERSION = "1.1.3"

ns.KIND_DIRECT = "direct"
ns.KIND_HOT = "hot"
ns.KIND_AOE = "aoe"
ns.KIND_ABSORB = "absorb"

-- English names match a spellbook spell whose ID is not in the catalog.
-- The window shows the name the client returns for that spell ID.
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

-- Spell IDs to ask the client about. Heal, mana, and cast come from the APIs.
-- { id, family }
local catalog = {
	-- Lesser Heal
	{ 2050, "LESSER_HEAL" },
	{ 2052, "LESSER_HEAL" },
	{ 2053, "LESSER_HEAL" },
	-- Heal
	{ 2054, "HEAL" },
	{ 2055, "HEAL" },
	{ 6063, "HEAL" },
	{ 6064, "HEAL" },
	-- Greater Heal
	{ 2060, "GREATER_HEAL" },
	{ 10963, "GREATER_HEAL" },
	{ 10964, "GREATER_HEAL" },
	{ 10965, "GREATER_HEAL" },
	{ 25314, "GREATER_HEAL" },
	-- Flash Heal
	{ 2061, "FLASH_HEAL" },
	{ 9472, "FLASH_HEAL" },
	{ 9473, "FLASH_HEAL" },
	{ 9474, "FLASH_HEAL" },
	{ 10915, "FLASH_HEAL" },
	{ 10916, "FLASH_HEAL" },
	{ 10917, "FLASH_HEAL" },
	-- Renew
	{ 139, "RENEW" },
	{ 6074, "RENEW" },
	{ 6075, "RENEW" },
	{ 6076, "RENEW" },
	{ 6077, "RENEW" },
	{ 6078, "RENEW" },
	{ 10927, "RENEW" },
	{ 10928, "RENEW" },
	{ 10929, "RENEW" },
	{ 25315, "RENEW" },
	-- Prayer of Healing
	{ 596, "PRAYER_OF_HEALING" },
	{ 996, "PRAYER_OF_HEALING" },
	{ 10960, "PRAYER_OF_HEALING" },
	{ 10961, "PRAYER_OF_HEALING" },
	{ 25316, "PRAYER_OF_HEALING" },
	-- Holy Nova
	{ 15237, "HOLY_NOVA" },
	{ 15430, "HOLY_NOVA" },
	{ 15431, "HOLY_NOVA" },
	{ 27799, "HOLY_NOVA" },
	{ 27800, "HOLY_NOVA" },
	{ 27801, "HOLY_NOVA" },
	-- Power Word: Shield
	{ 17, "POWER_WORD_SHIELD" },
	{ 592, "POWER_WORD_SHIELD" },
	{ 600, "POWER_WORD_SHIELD" },
	{ 3747, "POWER_WORD_SHIELD" },
	{ 6065, "POWER_WORD_SHIELD" },
	{ 6066, "POWER_WORD_SHIELD" },
	{ 10898, "POWER_WORD_SHIELD" },
	{ 10899, "POWER_WORD_SHIELD" },
	{ 10900, "POWER_WORD_SHIELD" },
	{ 10901, "POWER_WORD_SHIELD" },
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
	}
	ns.CATALOG[#ns.CATALOG + 1] = entry
	ns.CATALOG_BY_ID[entry.id] = entry
end
