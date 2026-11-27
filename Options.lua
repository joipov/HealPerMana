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
	ns.OpenSettings()
end

function _G.HealPerMana_OnAddonCompartmentEnter(_, owner)
	if not GameTooltip then
		return
	end
	GameTooltip:SetOwner(owner or UIParent, "ANCHOR_LEFT")
	GameTooltip:AddLine(ns.TITLE)
	GameTooltip:AddLine(ns.L.CLICK_SETTINGS, 1, 1, 1)
	GameTooltip:Show()
end

function _G.HealPerMana_OnAddonCompartmentLeave()
	if GameTooltip then
		GameTooltip:Hide()
	end
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
			default = ns.defaults and ns.defaults[key]
		end
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
		local checkbox = Settings.CreateCheckbox(category, setting, tooltip)
		return checkbox, setting
	end

	local _, enabledSetting = AddCheckbox("enabled", L.ENABLE:format(ns.TITLE), L.ENABLE_TIP, nil, function()
		if not ns.db.enabled and ns.mainFrame then
			ns.mainFrame:Hide()
		end
	end)

	local function GateOn(initializer)
		if not initializer then
			return
		end
		if initializer.AddModifyPredicate then
			initializer:AddModifyPredicate(function()
				return enabledSetting:GetValue()
			end)
		end
		if initializer.AddEvaluateStateCVar then
			initializer:AddEvaluateStateCVar("HPM_ENABLED")
		end
	end

	local unlearnedCheckbox = AddCheckbox("showUnlearned", L.SHOW_UNLEARNED, L.SHOW_UNLEARNED_TIP, nil, function()
		ns.InvalidateCache()
		if ns.mainFrame and ns.mainFrame:IsShown() then
			ns.RefreshUI()
		end
	end)

	local function AddPixelSetting(key, label, tooltip, lo, hi)
		local setting = Settings.RegisterAddOnSetting(
			category,
			"HPM_" .. key:upper(),
			key,
			ns.db,
			Settings.VarType.Number,
			label,
			ns.defaults[key]
		)
		setting:SetValueChangedCallback(function()
			local n = tonumber(ns.db[key]) or ns.defaults[key]
			n = math.floor(n + 0.5)
			if n < lo then
				n = lo
			elseif n > hi then
				n = hi
			end
			ns.db[key] = n
			if ns.ApplyPosition then
				ns.ApplyPosition()
			end
		end)
		local control
		local initializer
		if Settings.CreateElementInitializer then
			initializer = Settings.CreateElementInitializer("SettingsListElementTemplate", {
				name = label,
				tooltipText = tooltip,
			})
		end
		if initializer and initializer.InitFrame then
			local origInit = initializer.InitFrame
			function initializer:InitFrame(frame)
				origInit(self, frame)
				local box = frame.pixelBox
				if not box then
					box = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
					box:SetAutoFocus(false)
					box:SetSize(70, 20)
					box:SetMaxLetters(7)
					box:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
					box:SetFontObject(GameFontHighlightSmall)
					box:SetJustifyH("CENTER")
					local function Commit()
						local n = tonumber(box:GetText())
						if type(n) == "number" and n == n then
							n = math.floor(n + 0.5)
							if n < lo then
								n = lo
							elseif n > hi then
								n = hi
							end
							setting:SetValue(n)
						else
							box:SetText(tostring(ns.db[key]))
						end
					end
					box:SetScript("OnEnterPressed", function()
						Commit()
						box:ClearFocus()
					end)
					box:SetScript("OnEscapePressed", function()
						box.reverting = true
						box:SetText(tostring(ns.db[key]))
						box:ClearFocus()
						box.reverting = false
					end)
					box:SetScript("OnEditFocusLost", function()
						if box.reverting then
							return
						end
						Commit()
					end)
					frame.pixelBox = box
				end
				if not box:HasFocus() then
					box:SetText(tostring(ns.db[key]))
				end
			end
			SettingsPanel:GetLayout(category):AddInitializer(initializer)
			control = initializer
		elseif Settings.CreateSliderOptions and Settings.CreateSlider then
			local options = Settings.CreateSliderOptions(lo, hi, 1)
			if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
				options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
					return string.format("%.0f", value)
				end)
			end
			control = Settings.CreateSlider(category, setting, options, tooltip)
		end
		return control, setting
	end

	local xControl, xSetting = AddPixelSetting("x", L.POS_X, L.POS_X_TIP, -2000, 2000)
	local yControl, ySetting = AddPixelSetting("y", L.POS_Y, L.POS_Y_TIP, -2000, 2000)
	ns.xSetting = xSetting
	ns.ySetting = ySetting

	GateOn(unlearnedCheckbox)
	GateOn(xControl)
	GateOn(yControl)

	AddCheckbox("showMinimapButton", L.SHOW_MINIMAP, L.SHOW_MINIMAP_TIP, nil, function()
		if ns.UpdateMinimapButton then
			ns.UpdateMinimapButton()
		end
	end)

	ns.AddProfileShareButtons(category)

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
				local missed = ns.unparsed or {}
				ns.Debug("unparsed", #missed)
				for i = 1, #missed do
					ns.Debug("unparsed", missed[i].id, missed[i].name)
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
