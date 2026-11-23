local _, ns = ...

ns.TITLE = "Heal Per Mana Table"

-- Spell IDs the Forever client names. Heal, mana, cast, and rank are read
-- from the client when the list is built. Nothing here is a heal amount.
-- Unlearned rows are limited to the logged-in class.
-- { id, class }
local catalog = {
	-- Priest. The rank IDs already resolved on this client, plus hotfix names.
	{ 2050, "PRIEST" },
	{ 2052, "PRIEST" },
	{ 2053, "PRIEST" },
	{ 2054, "PRIEST" },
	{ 2055, "PRIEST" },
	{ 6063, "PRIEST" },
	{ 6064, "PRIEST" },
	{ 2060, "PRIEST" },
	{ 10963, "PRIEST" },
	{ 10964, "PRIEST" },
	{ 10965, "PRIEST" },
	{ 25314, "PRIEST" },
	{ 2061, "PRIEST" },
	{ 9472, "PRIEST" },
	{ 9473, "PRIEST" },
	{ 9474, "PRIEST" },
	{ 10915, "PRIEST" },
	{ 10916, "PRIEST" },
	{ 10917, "PRIEST" },
	{ 139, "PRIEST" },
	{ 6074, "PRIEST" },
	{ 6075, "PRIEST" },
	{ 6076, "PRIEST" },
	{ 6077, "PRIEST" },
	{ 6078, "PRIEST" },
	{ 10927, "PRIEST" },
	{ 10928, "PRIEST" },
	{ 10929, "PRIEST" },
	{ 25315, "PRIEST" },
	{ 596, "PRIEST" },
	{ 996, "PRIEST" },
	{ 10960, "PRIEST" },
	{ 10961, "PRIEST" },
	{ 25316, "PRIEST" },
	{ 15237, "PRIEST" },
	{ 15430, "PRIEST" },
	{ 15431, "PRIEST" },
	{ 27799, "PRIEST" },
	{ 27800, "PRIEST" },
	{ 27801, "PRIEST" },
	{ 17, "PRIEST" },
	{ 592, "PRIEST" },
	{ 600, "PRIEST" },
	{ 3747, "PRIEST" },
	{ 6065, "PRIEST" },
	{ 6066, "PRIEST" },
	{ 10898, "PRIEST" },
	{ 10899, "PRIEST" },
	{ 10900, "PRIEST" },
	{ 10901, "PRIEST" },
	{ 22187, "PRIEST" },
	{ 402174, "PRIEST" },
	{ 1240720, "PRIEST" },
	{ 1240721, "PRIEST" },
	{ 1316995, "PRIEST" },
	{ 19338, "PRIEST" },
	{ 1328570, "PRIEST" },

	-- Druid.
	{ 5187, "DRUID" },
	{ 5188, "DRUID" },
	{ 5189, "DRUID" },
	{ 9889, "DRUID" },
	{ 8939, "DRUID" },
	{ 18562, "DRUID" },
	{ 408247, "DRUID" },
	{ 1280634, "DRUID" },

	-- Paladin.
	{ 458856, "PALADIN" },

	-- Shaman.
	{ 8010, "SHAMAN" },
	{ 974, "SHAMAN" },
	{ 408521, "SHAMAN" },
	{ 1239242, "SHAMAN" },
	{ 1239243, "SHAMAN" },

	-- Warlock.
	{ 689, "WARLOCK" },
	{ 699, "WARLOCK" },
	{ 709, "WARLOCK" },
	{ 7651, "WARLOCK" },
	{ 11699, "WARLOCK" },
	{ 11700, "WARLOCK" },
	{ 18265, "WARLOCK" },
	{ 18879, "WARLOCK" },
	{ 18880, "WARLOCK" },
	{ 18881, "WARLOCK" },

	-- Mage absorbs with a stated amount.
	{ 6143, "MAGE" },
	{ 8461, "MAGE" },
	{ 8462, "MAGE" },
	{ 10177, "MAGE" },
	{ 28609, "MAGE" },
	{ 11426, "MAGE" },
	{ 13031, "MAGE" },
	{ 13032, "MAGE" },
	{ 13033, "MAGE" },
}

ns.CATALOG = {}
ns.CATALOG_BY_ID = {}

for i = 1, #catalog do
	local row = catalog[i]
	local entry = {
		id = row[1],
		class = row[2],
	}
	ns.CATALOG[#ns.CATALOG + 1] = entry
	ns.CATALOG_BY_ID[entry.id] = entry
end
