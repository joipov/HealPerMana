local ADDON_NAME, ns = ...

-- Single event frame. API work at load is only this frame plus ADDON_LOADED.

local C_Timer = C_Timer

local eventFrame = CreateFrame("Frame")
local scanQueued = false

local function QueueRescan()
	if scanQueued then
		return
	end
	scanQueued = true
	C_Timer.After(0.15, function()
		scanQueued = false
		if not ns.db or not ns.db.enabled then
			return
		end
		ns.InvalidateCache()
		if ns.mainFrame and ns.mainFrame:IsShown() then
			ns.RefreshUI()
		end
	end)
end

local handlers = {}

function handlers.ADDON_LOADED(name)
	if name ~= ADDON_NAME then
		return
	end
	local saved = _G.HealPerManaDB
	_G.HealPerManaDB = ns.LoadDB(saved)
	ns.db = _G.HealPerManaDB
	eventFrame:UnregisterEvent("ADDON_LOADED")
	eventFrame:RegisterEvent("PLAYER_LOGIN")
	eventFrame:RegisterEvent("SPELLS_CHANGED")
	eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	if ns.InitOptions then
		ns.InitOptions()
	end
end

function handlers.PLAYER_LOGIN()
	if ns.CreateMinimapButton then
		ns.CreateMinimapButton()
	end
	ns.InvalidateCache()
	ns.Print("Type |cffffffff/hpm|r to toggle the list. |cffffffff/hpm settings|r opens settings.")
end

function handlers.SPELLS_CHANGED()
	QueueRescan()
end

function handlers.PLAYER_EQUIPMENT_CHANGED()
	QueueRescan()
end

eventFrame:SetScript("OnEvent", function(_, event, arg1)
	local handler = handlers[event]
	if handler then
		handler(arg1)
	end
end)
eventFrame:RegisterEvent("ADDON_LOADED")
