local _, ns = ...

local UIParent = UIParent
local CreateFrame = CreateFrame
local PlaySound = PlaySound
local SOUNDKIT = SOUNDKIT

local GOLD = { 0.91, 0.78, 0.42 }
local TEXT = { 0.93, 0.91, 0.86 }
local MUTED = { 0.62, 0.60, 0.55 }

local FRAME_W, FRAME_H = 520, 400
local ROW_H = 26
local COLS = {
	{ key = "name", w = 168 },
	{ key = "rank", w = 42 },
	{ key = "cast", w = 48 },
	{ key = "mana", w = 52 },
	{ key = "heal", w = 88 },
	{ key = "hpm", w = 64 },
}

local frame
local widgets = {}
local rows = {}

local function Color(fs, c)
	fs:SetTextColor(c[1], c[2], c[3])
end

local function Solid(parent, r, g, b, a)
	local t = parent:CreateTexture(nil, "BACKGROUND")
	t:SetColorTexture(r, g, b, a or 1)
	return t
end

local function Font(parent, size, flags)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont("Fonts\\FRIZQT__.TTF", size or 12, flags)
	fs:SetShadowOffset(1, -1)
	fs:SetShadowColor(0, 0, 0, 0.7)
	Color(fs, TEXT)
	return fs
end

local function Edge(parent, r, g, b, a)
	local function Line(p1, p2, w, h)
		local t = parent:CreateTexture(nil, "BORDER")
		t:SetColorTexture(r, g, b, a or 0.9)
		t:SetPoint(p1)
		t:SetPoint(p2)
		if w then t:SetWidth(w) end
		if h then t:SetHeight(h) end
	end
	Line("TOPLEFT", "TOPRIGHT", nil, 1)
	Line("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
	Line("TOPLEFT", "BOTTOMLEFT", 1, nil)
	Line("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
end

local function ClickSound()
	if PlaySound and SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
end

local function FormatCast(sec)
	if type(sec) ~= "number" then
		return ns.L.NA
	end
	if sec <= 0 then
		return ns.L.INSTANT
	end
	return string.format("%.1f", sec)
end

local function FormatHeal(spell)
	if type(spell.healMin) ~= "number" or type(spell.healMax) ~= "number" then
		return ns.L.NA
	end
	if spell.healMin == spell.healMax then
		return tostring(math.floor(spell.healMin + 0.5))
	end
	return math.floor(spell.healMin + 0.5) .. "-" .. math.floor(spell.healMax + 0.5)
end

local function FormatMana(mana)
	if type(mana) ~= "number" then
		return ns.L.NA
	end
	return tostring(mana)
end

local function FormatHPM(spell)
	local hpm = ns.HealPerMana(spell)
	if hpm == nil then
		return ns.L.NA
	end
	return string.format("%.2f", hpm)
end

local function SavePosition()
	local db = ns.db
	if not db or not frame then
		return
	end
	local point, _, relPoint, x, y = frame:GetPoint(1)
	if point then
		db.point, db.relPoint, db.x, db.y = point, relPoint, x, y
	end
end

local function CreateRow(parent)
	local row = CreateFrame("Button", nil, parent)
	row:SetHeight(ROW_H)
	row.bg = Solid(row, 0.10, 0.10, 0.12, 0.95)
	row.bg:SetAllPoints()
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(16, 16)
	row.icon:SetPoint("LEFT", 8, 0)
	row.name = Font(row, 11)
	row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
	row.name:SetWidth(140)
	row.name:SetJustifyH("LEFT")
	row.name:SetWordWrap(false)
	local x = 176
	row.rank = Font(row, 11)
	row.rank:SetPoint("LEFT", x, 0)
	row.rank:SetWidth(42)
	row.rank:SetJustifyH("CENTER")
	x = x + 42
	row.cast = Font(row, 11)
	row.cast:SetPoint("LEFT", x, 0)
	row.cast:SetWidth(48)
	row.cast:SetJustifyH("CENTER")
	x = x + 48
	row.mana = Font(row, 11)
	row.mana:SetPoint("LEFT", x, 0)
	row.mana:SetWidth(52)
	row.mana:SetJustifyH("RIGHT")
	x = x + 52
	row.heal = Font(row, 11)
	row.heal:SetPoint("LEFT", x, 0)
	row.heal:SetWidth(88)
	row.heal:SetJustifyH("RIGHT")
	x = x + 88
	row.hpm = Font(row, 12)
	row.hpm:SetPoint("LEFT", x, 0)
	row.hpm:SetWidth(64)
	row.hpm:SetJustifyH("RIGHT")
	Color(row.hpm, GOLD)
	row:SetScript("OnClick", function(self)
		if self.spell and widgets.macro then
			widgets.macro:SetText(ns.MacroText(self.spell))
			widgets.macro:HighlightText()
			widgets.macro:SetFocus()
		end
	end)
	return row
end

local function PaintRow(row, spell, alt)
	row.spell = spell
	row:Show()
	if alt then
		row.bg:SetColorTexture(0.12, 0.11, 0.13, 0.95)
	else
		row.bg:SetColorTexture(0.10, 0.10, 0.12, 0.95)
	end
	if spell.icon then
		row.icon:SetTexture(spell.icon)
		row.icon:Show()
	else
		row.icon:Hide()
	end
	row.name:SetText(spell.name or ns.L.NA)
	if spell.known then
		Color(row.name, TEXT)
	else
		Color(row.name, MUTED)
	end
	if type(spell.rank) == "number" then
		row.rank:SetText(tostring(spell.rank))
	else
		row.rank:SetText(ns.L.NA)
	end
	row.cast:SetText(FormatCast(spell.castSec))
	row.mana:SetText(FormatMana(spell.mana))
	row.heal:SetText(FormatHeal(spell))
	row.hpm:SetText(FormatHPM(spell))
end

local function UpdateTable(spells)
	local db = ns.db
	local list = {}
	for i = 1, #spells do
		local spell = spells[i]
		if spell.known or db.showUnlearned then
			list[#list + 1] = spell
		end
	end
	ns.SortSpellsBy(list, db.sortKey, db.sortAsc)
	local child = widgets.scrollChild
	local shown = #list
	for i = 1, shown do
		local row = rows[i]
		if not row then
			row = CreateRow(child)
			rows[i] = row
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
		row:SetPoint("RIGHT", child, "RIGHT", 0, 0)
		PaintRow(row, list[i], i % 2 == 0)
	end
	for i = shown + 1, #rows do
		rows[i]:Hide()
		rows[i].spell = nil
	end
	child:SetSize(widgets.scroll:GetWidth() or 490, math.max(shown * ROW_H, 1))
	if shown > 0 and widgets.macro then
		widgets.macro:SetText(ns.MacroText(list[1]))
	elseif widgets.macro then
		widgets.macro:SetText("")
	end
end

local function MakeHeaderButton(parent, col, label)
	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(col.w, 20)
	btn.label = Font(btn, 10)
	btn.label:SetAllPoints()
	btn.label:SetJustifyH("CENTER")
	btn.label:SetText(label)
	if col.key == "hpm" then
		Color(btn.label, GOLD)
	else
		Color(btn.label, MUTED)
	end
	btn:SetScript("OnClick", function()
		local db = ns.db
		if db.sortKey == col.key then
			db.sortAsc = not db.sortAsc
		else
			db.sortKey = col.key
			db.sortAsc = col.key == "name"
		end
		ClickSound()
		ns.RefreshUI()
	end)
	return btn
end

function ns.RefreshUI()
	if not frame or not ns.db then
		return
	end
	local priest = ns.IsPriest()
	if priest == false then
		widgets.gate:Show()
		widgets.body:Hide()
		widgets.gateText:SetText(ns.L.PRIEST_ONLY)
		return
	end
	widgets.gate:Hide()
	widgets.body:Show()
	local spells = ns.GetSpells()
	if #spells == 0 then
		widgets.empty:Show()
		widgets.empty:SetText(ns.L.NO_SPELLS)
	else
		widgets.empty:Hide()
	end
	UpdateTable(spells)
end

function ns.CreateMainFrame()
	if frame then
		return frame
	end
	local L = ns.L
	local db = ns.db
	frame = CreateFrame("Frame", "HealPerManaFrame", UIParent)
	frame:SetSize(FRAME_W, FRAME_H)
	frame:SetFrameStrata("HIGH")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:Hide()
	frame:SetPoint(db.point or "CENTER", UIParent, db.relPoint or "CENTER", db.x or 0, db.y or 0)
	Solid(frame, 0.07, 0.07, 0.09, 0.97):SetAllPoints()
	Edge(frame, GOLD[1], GOLD[2], GOLD[3], 0.55)

	local titleBar = CreateFrame("Frame", nil, frame)
	titleBar:SetPoint("TOPLEFT")
	titleBar:SetPoint("TOPRIGHT")
	titleBar:SetHeight(32)
	Solid(titleBar, 0.10, 0.09, 0.08, 1):SetAllPoints()
	titleBar:EnableMouse(true)
	titleBar:RegisterForDrag("LeftButton")
	titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
	titleBar:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		SavePosition()
	end)
	local title = Font(titleBar, 14)
	title:SetPoint("LEFT", 14, 0)
	title:SetText(ns.TITLE)
	Color(title, GOLD)

	local close = CreateFrame("Button", nil, titleBar)
	close:SetSize(22, 22)
	close:SetPoint("RIGHT", -8, 0)
	close.label = Font(close, 14)
	close.label:SetPoint("CENTER", 1, 1)
	close.label:SetText("×")
	Color(close.label, MUTED)
	close:SetScript("OnClick", function()
		frame:Hide()
		ClickSound()
	end)

	local gate = CreateFrame("Frame", nil, frame)
	gate:SetPoint("TOPLEFT", 0, -32)
	gate:SetPoint("BOTTOMRIGHT")
	gate:Hide()
	local gateText = Font(gate, 13)
	gateText:SetPoint("CENTER", 0, 20)
	gateText:SetWidth(360)
	gateText:SetJustifyH("CENTER")
	Color(gateText, MUTED)
	widgets.gate = gate
	widgets.gateText = gateText

	local body = CreateFrame("Frame", nil, frame)
	body:SetPoint("TOPLEFT", 12, -40)
	body:SetPoint("BOTTOMRIGHT", -12, 12)
	widgets.body = body

	local header = CreateFrame("Frame", nil, body)
	header:SetPoint("TOPLEFT", 0, 0)
	header:SetPoint("TOPRIGHT", 0, 0)
	header:SetHeight(20)
	Solid(header, 0.09, 0.09, 0.10, 1):SetAllPoints()
	local hx = 8
	local labels = {
		name = L.COL_SPELL,
		rank = L.COL_RANK,
		cast = L.COL_CAST,
		mana = L.COL_MANA,
		heal = L.COL_HEAL,
		hpm = L.COL_HPM,
	}
	for i = 1, #COLS do
		local col = COLS[i]
		local btn = MakeHeaderButton(header, col, labels[col.key])
		btn:SetPoint("LEFT", hx, 0)
		hx = hx + col.w
	end

	local scroll = CreateFrame("ScrollFrame", nil, body)
	scroll:SetPoint("TOPLEFT", 0, -22)
	scroll:SetPoint("BOTTOMRIGHT", 0, 44)
	scroll:EnableMouseWheel(true)
	local child = CreateFrame("Frame", nil, scroll)
	scroll:SetScrollChild(child)
	child:SetWidth(490)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local cur = self:GetVerticalScroll()
		local max = self:GetVerticalScrollRange() or 0
		local nextScroll = cur - delta * ROW_H * 3
		if nextScroll < 0 then
			nextScroll = 0
		elseif nextScroll > max then
			nextScroll = max
		end
		self:SetVerticalScroll(nextScroll)
	end)
	widgets.scroll = scroll
	widgets.scrollChild = child

	widgets.empty = Font(body, 12)
	widgets.empty:SetPoint("CENTER", scroll, "CENTER")
	widgets.empty:Hide()
	Color(widgets.empty, MUTED)

	widgets.macro = CreateFrame("EditBox", nil, body)
	widgets.macro:SetMultiLine(true)
	widgets.macro:SetHeight(40)
	widgets.macro:SetPoint("BOTTOMLEFT", 0, 0)
	widgets.macro:SetPoint("BOTTOMRIGHT", 0, 0)
	widgets.macro:SetAutoFocus(false)
	widgets.macro:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
	widgets.macro:SetTextInsets(6, 6, 4, 4)
	widgets.macro:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	widgets.macro:SetMaxLetters(255)
	local macroBg = Solid(widgets.macro, 0.06, 0.06, 0.07, 1)
	macroBg:SetAllPoints()
	widgets.macro:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	widgets.macro:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	widgets.macro:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

	ns.mainFrame = frame
	return frame
end

function ns.ToggleMainFrame()
	ns.CreateMainFrame()
	if frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
		ns.RefreshUI()
	end
end
