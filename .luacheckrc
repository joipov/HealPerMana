-- Lua 5.1, explicit WoW globals. Modeled on GatherSkillTooltip / BigWigs.
std = "lua51"
max_line_length = false
self = false

exclude_files = {
	".release/",
	".annotations/",
}

files["tests/"] = {
	std = "lua51",
	globals = {
		"issecretvalue",
		"canaccessvalue",
		"issecrettable",
		"canaccesstable",
		"C_Spell",
		"C_SpellBook",
		"C_TooltipInfo",
		"C_Timer",
		"Enum",
		"TooltipUtil",
		"UnitClass",
		"UnitPower",
		"print",
	},
}

globals = {
	"HealPerManaDB",
	"HealPerMana_OnAddonCompartmentClick",
	"SLASH_HPM1",
	"SLASH_HPM2",
	SlashCmdList = { fields = { "HPM" } },
}

read_globals = {
	"issecretvalue",
	"canaccessvalue",
	"issecrettable",
	"canaccesstable",

	"C_Spell",
	"C_SpellBook",
	"C_TooltipInfo",
	"C_Timer",
	"Enum",
	"TooltipUtil",

	"CreateFrame",
	"JoipovAddons_RegisterHint",
	"JoipovAddons_Print",
	"GetLocale",
	"PlaySound",
	"SOUNDKIT",
	"UIParent",
	"Settings",
	"UnitClass",
	"UnitPower",
	"HealPickDB",
}
