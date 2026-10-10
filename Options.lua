local _, ns = ...

local Settings = Settings

function ns.OpenSettings()
	if not ns.settingsCategory then
		ns.InitOptions()
	end
	if not ns.settingsCategory then
		ns.Print(ns.L.OPEN_FAILED)
		return
	end
	Settings.OpenToCategory(ns.settingsCategory:GetID())
end

function _G.HealPerMana_OnAddonCompartmentClick()
	ns.ToggleMainFrame()
end

function ns.InitOptions()
	if ns.settingsCategory or not ns.db then
		return
	end

	local L = ns.L
	local category = Settings.RegisterVerticalLayoutCategory(ns.TITLE)
	ns.settingsCategory = category

	local function AddCheckbox(key, label, tooltip, default, onChanged)
		if default == nil then
			default = true
		end
		local setting = Settings.RegisterAddOnSetting(
			category,
			"HPM_" .. key:upper(),
			key,
			ns.db,
			Settings.VarType.Boolean,
			label,
			default
		)
		if onChanged then
			setting:SetValueChangedCallback(onChanged)
		end
		return Settings.CreateCheckbox(category, setting, tooltip)
	end

	AddCheckbox("enabled", L.ENABLE:format(ns.TITLE), L.ENABLE_TIP, true, function()
		if not ns.db.enabled and ns.mainFrame then
			ns.mainFrame:Hide()
		end
	end)
	AddCheckbox("showUnlearned", L.SHOW_UNLEARNED, L.SHOW_UNLEARNED_TIP, false, function()
		ns.InvalidateCache()
		if ns.mainFrame and ns.mainFrame:IsShown() then
			ns.RefreshUI()
		end
	end)

	Settings.RegisterAddOnCategory(category)
end

_G.SLASH_HPM1 = "/hpm"
_G.SLASH_HPM2 = "/healpermana"
_G.SlashCmdList.HPM = function(msg)
	msg = (msg and msg:match("^%s*(.-)%s*$") or ""):lower()
	if msg == "debug" then
		if ns.db then
			ns.db.debug = not ns.db.debug
			ns.Print("debug " .. (ns.db.debug and ns.L.DEBUG_ON or ns.L.DEBUG_OFF))
			if ns.db.debug then
				local spells = ns.GetSpells()
				ns.Debug("ranks", #spells)
				for i = 1, #spells do
					local s = spells[i]
					ns.Debug(s.id, s.name, s.rank, s.mana, s.castSec, s.healMin, s.healMax, s.source, s.known, ns.HealPerMana(s))
				end
			end
		end
		return
	end
	if msg == "settings" or msg == "config" or msg == "opt" then
		ns.OpenSettings()
		return
	end
	if msg == "help" then
		ns.Print(ns.L.SLASH_HELP)
		return
	end
	if ns.db and not ns.db.enabled then
		ns.db.enabled = true
	end
	ns.ToggleMainFrame()
end
