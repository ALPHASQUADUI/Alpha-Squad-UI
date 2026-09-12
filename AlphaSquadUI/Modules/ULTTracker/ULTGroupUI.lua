-- Ąlpha Şquad UI - ULT Tracker / Compact Group Percentage List

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}

local ULT = AlphaSquadUI.Modules.ULTTracker
if not ULT or not ULT.Group then return end

local Group = ULT.Group
local EM = EVENT_MANAGER

local COLORS = ULT.COLORS or {
    bg = {0.010, 0.016, 0.030, 0.96},
    white = {0.95, 0.97, 1.00, 1.00},
    muted = {0.53, 0.62, 0.72, 1.00},
    orange = {1.00, 0.58, 0.16, 1.00},
    cyan = {0.20, 0.82, 1.00, 1.00},
    gold = {0.97, 0.78, 0.30, 1.00},
}

local BASE_WINDOW_W = 312
local BASE_ROW_H = 36
local HEADER_H = 16
local GAP = 1

local READY_ORANGE = {1.00, 0.46, 0.05, 1.00}
local READY_GOLD = {1.00, 0.82, 0.18, 1.00}
local READY_WHITE = {1.00, 0.98, 0.88, 1.00}

local function SetColor(control, color, alpha)
    if not control or not color then return end
    control:SetColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function Solid(parent, name, color)
    local texture = WINDOW_MANAGER:CreateControl(name, parent, CT_TEXTURE)
    texture:SetAnchorFill(parent)
    SetColor(texture, color)
    return texture
end

local function Label(parent, name, font, text, color)
    local label = WINDOW_MANAGER:CreateControl(name, parent, CT_LABEL)
    label:SetFont(font)
    label:SetText(text or "")
    SetColor(label, color or COLORS.white)
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    return label
end

function Group:GetListWidth()
    return ULT.Clamp(self.sv and self.sv.hudWidth or BASE_WINDOW_W, 240, 520)
end

function Group:GetRowHeight()
    return ULT.Clamp(self.sv and self.sv.rowHeight or BASE_ROW_H, 28, 56)
end

function Group:GetIconSize()
    return ULT.Clamp(self:GetRowHeight() - 8, 20, 44)
end

function Group:GetRowWidth()
    return math.max(228, self:GetListWidth() - 12)
end

function Group:GetWindowBaseWidth()
    return self:GetListWidth()
end

local function CreateRow(parent, index)
    local row = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupListRow" .. index, parent, CT_CONTROL)
    row:SetDimensions(BASE_WINDOW_W - 12, BASE_ROW_H)

    row.bg = Solid(row, "AlphaSquadULTGroupListRow" .. index .. "BG", {0.016, 0.024, 0.042, 0.92})

    row.readyOverlay = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupListRow" .. index .. "ReadyOverlay", row, CT_TEXTURE)
    row.readyOverlay:SetAnchorFill(row)
    row.readyOverlay:SetBlendMode(TEX_BLEND_MODE_ADD)
    row.readyOverlay:SetColor(1.00, 0.46, 0.05, 0)

    row.accent = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupListRow" .. index .. "Accent", row, CT_TEXTURE)
    row.accent:SetDimensions(4, BASE_ROW_H)
    row.accent:SetAnchor(TOPLEFT, row, TOPLEFT, 0, 0)
    SetColor(row.accent, COLORS.cyan, 0.28)

    row.iconBorder = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupListRow" .. index .. "IconBorder", row, CT_TEXTURE)
    row.iconBorder:SetDimensions(32, 32)
    row.iconBorder:SetAnchor(LEFT, row, LEFT, 7, 0)
    SetColor(row.iconBorder, COLORS.cyan, 0.34)

    row.icon = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupListRow" .. index .. "Icon", row, CT_TEXTURE)
    row.icon:SetDimensions(28, 28)
    row.icon:SetAnchor(CENTER, row.iconBorder, CENTER, 0, 0)
    row.icon:SetTextureCoords(0.04, 0.96, 0.04, 0.96)

    row.user = Label(row, "AlphaSquadULTGroupListRow" .. index .. "User", "ZoFontGameBold", "", COLORS.white)
    row.user:SetDimensions(184, BASE_ROW_H)
    row.user:SetAnchor(LEFT, row, LEFT, 47, 0)
    row.user:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    row.user:SetMaxLineCount(1)
    if row.user.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then
        row.user:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    end

    row.percent = Label(row, "AlphaSquadULTGroupListRow" .. index .. "Percent", "ZoFontGameBold", "", COLORS.white)
    row.percent:SetDimensions(60, BASE_ROW_H)
    row.percent:SetAnchor(RIGHT, row, RIGHT, -8, 0)
    row.percent:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    row.progressBG = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupListRow" .. index .. "ProgressBG", row, CT_TEXTURE)
    row.progressBG:SetDimensions(BASE_WINDOW_W - 64, 2)
    row.progressBG:SetAnchor(BOTTOMRIGHT, row, BOTTOMRIGHT, -8, -3)
    row.progressBG:SetColor(0.04, 0.06, 0.09, 0.90)

    row.progress = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupListRow" .. index .. "Progress", row, CT_TEXTURE)
    row.progress:SetDimensions(0, 2)
    row.progress:SetAnchor(LEFT, row.progressBG, LEFT, 0, 0)
    SetColor(row.progress, COLORS.cyan, 0.80)

    row.ready = false
    row.recentlyUsed = false
    return row
end

function Group:ApplyRowGeometry(row)
    if not row then return end

    local width = self:GetRowWidth()
    local height = self:GetRowHeight()
    local iconSize = self:GetIconSize()
    local iconBorderSize = iconSize + 4
    local iconX = 7
    local userX = iconX + iconBorderSize + 8
    local percentWidth = 58
    local rightPadding = 8
    local userWidth = math.max(90, width - userX - percentWidth - rightPadding - 8)
    local progressWidth = math.max(80, width - userX - 8)

    row:SetDimensions(width, height)
    row.accent:SetDimensions(4, height)

    row.iconBorder:SetDimensions(iconBorderSize, iconBorderSize)
    row.iconBorder:ClearAnchors()
    row.iconBorder:SetAnchor(LEFT, row, LEFT, iconX, 0)

    row.icon:SetDimensions(iconSize, iconSize)

    row.user:SetDimensions(userWidth, height)
    row.user:ClearAnchors()
    row.user:SetAnchor(LEFT, row, LEFT, userX, 0)

    row.percent:SetDimensions(percentWidth, height)
    row.percent:ClearAnchors()
    row.percent:SetAnchor(RIGHT, row, RIGHT, -rightPadding, 0)

    row.progressBG:SetDimensions(progressWidth, 2)
    row.progress:SetHeight(2)
    row.geometryProgressWidth = progressWidth
end

function Group:ApplyListGeometry()
    if not self.window then return end

    local width = self:GetListWidth()
    self.window:SetWidth(width)

    if self.window.dragSurface then
        self.window.dragSurface:SetWidth(width)
    end

    if self.window.empty then
        self.window.empty:SetWidth(math.max(100, width - 20))
    end

    for _, row in ipairs(self.window.rows or {}) do
        self:ApplyRowGeometry(row)
    end
end

function Group:GetDefaultPosition()
    local rootW = GuiRoot and GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot and GuiRoot:GetHeight() or 1080
    return math.max(8, math.floor(rootW - self:GetListWidth() - 30)), math.floor(rootH * 0.16)
end

function Group:GetEffectiveScale()
    if not self.window or not self.sv or not GuiRoot then
        return (self.sv and self.sv.scale or 100) / 100
    end

    local requested = (self.sv.scale or 100) / 100
    local rootW = GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot:GetHeight() or 1080
    local baseW = self.window:GetWidth() or self:GetListWidth()
    local baseH = self.window:GetHeight() or 100

    local fitX = math.max(0.50, (rootW - 20) / math.max(1, baseW))
    local fitY = math.max(0.50, (rootH - 20) / math.max(1, baseH))
    return math.min(requested, fitX, fitY)
end

function Group:ClampToScreen(saveIfChanged)
    if not self.window or not self.sv or not GuiRoot then return end

    local rootW = GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot:GetHeight() or 1080
    local scale = self.window:GetScale() or ((self.sv.scale or 100) / 100)
    local width = (self.window:GetWidth() or self:GetListWidth()) * scale
    local height = (self.window:GetHeight() or 100) * scale
    local left, top = self.window:GetLeft(), self.window:GetTop()
    if left == nil or top == nil then return end

    local x = ULT.Clamp(left, 0, math.max(0, rootW - width))
    local y = ULT.Clamp(top, 0, math.max(0, rootH - height))

    if math.abs(x - left) > 0.5 or math.abs(y - top) > 0.5 then
        self.window:ClearAnchors()
        self.window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, x, y)
        if saveIfChanged then
            self.sv.x = math.floor(x + 0.5)
            self.sv.y = math.floor(y + 0.5)
            self.sv.positionSaved = true
        end
    end
end

function Group:ApplyPosition()
    if not self.window or not self.sv then return end

    local x = tonumber(self.sv.x)
    local y = tonumber(self.sv.y)

    if x == nil or y == nil then
        x, y = self:GetDefaultPosition()
        self.sv.x, self.sv.y = x, y
    end

    self.window:ClearAnchors()
    self.window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, x, y)
    self:ClampToScreen(true)
end

function Group:SavePosition()
    if not self.window or not self.sv then return end

    local left, top = self.window:GetLeft(), self.window:GetTop()
    if left ~= nil and top ~= nil then
        self.sv.x = math.floor(left + 0.5)
        self.sv.y = math.floor(top + 0.5)
        self.sv.positionSaved = true
        self:ClampToScreen(true)
    end
end

function Group:ResetPosition()
    if not self.sv then return end

    local x, y = self:GetDefaultPosition()
    self.sv.x, self.sv.y = x, y
    self.sv.positionSaved = true
    self:ApplyPosition()
    self:RefreshIntegratedSettings()
end

function Group:ResetSize()
    if not self.sv then return end

    self.sv.scale = 100
    self.sv.hudWidth = BASE_WINDOW_W
    self.sv.rowHeight = BASE_ROW_H
    self.sv.opacity = 92

    self:ApplyListGeometry()
    self:ApplyAppearance()
    self:RefreshHUD()
    self:RefreshConfig()
end

function Group:UpdateLockState()
    if not self.window or not self.sv then return end

    local movable = not self.sv.locked
    self.window:SetMovable(movable)

    if self.window.dragSurface then self.window.dragSurface:SetMouseEnabled(movable) end
    if self.window.dragHint then self.window.dragHint:SetHidden(not movable) end
end

function Group:ApplyAppearance()
    if not self.window or not self.sv then return end

    self.window:SetScale(self:GetEffectiveScale())
    self.window:SetAlpha(1)

    if self.window.bg then
        self.window.bg:SetAlpha((self.sv.opacity or 92) / 100)
    end

    self:ClampToScreen(true)
end

function Group:ApplyVisibility()
    if not self.window or not self.sv then return end

    local sharedSettings = AlphaSquadUI and AlphaSquadUI.Settings and AlphaSquadUI.Settings.mainWindow
    local sharedSettingsVisible = sharedSettings and not sharedSettings:IsHidden() or false
    local configVisible = self.configWindow and not self.configWindow:IsHidden() or false

    local hidden =
        not ULT.sv.enabled
        or not self.sv.enabled
        or not self.sv.visible
        or sharedSettingsVisible
        or configVisible
        or (self.sv.hideInMenus and ULT.uiObscured)

    self.window:SetHidden(hidden)

    if hidden then self:SetReadyPulseActive(false) end
end

function Group:RefreshRow(row, entry)
    if not row then return false end

    if not entry then
        row:SetHidden(true)
        row.ready = false
        row.recentlyUsed = false
        return false
    end

    row:SetHidden(false)

    local userId = entry.displayName ~= "" and entry.displayName or entry.key or "@Unknown"
    row.user:SetText(userId)

    local ultimate = entry.bestUltimate
    if not ultimate then
        ultimate = self:GetBestMatchingUltimate(entry)
    end

    row.icon:SetHidden(not ultimate or not ultimate.icon or ultimate.icon == "")
    if ultimate and ultimate.icon and ultimate.icon ~= "" then
        row.icon:SetTexture(ultimate.icon)
    end

    local percent = tonumber(entry.chargePercent) or 0
    percent = math.min(100, math.max(0, math.floor(percent + 0.5)))
    row.percent:SetText(tostring(percent) .. "%")

    local progressWidth = row.geometryProgressWidth or math.max(80, self:GetRowWidth() - 52)
    row.progress:SetWidth(math.floor(progressWidth * (percent / 100)))

    row.ready = entry.anyReady == true
    row.recentlyUsed = entry.recentlyUsed == true

    row.readyOverlay:SetColor(1.00, 0.46, 0.05, 0)

    if row.recentlyUsed then
        row:SetAlpha(0.20)
        SetColor(row.accent, COLORS.muted, 0.16)
        SetColor(row.iconBorder, COLORS.muted, 0.18)
        SetColor(row.percent, COLORS.muted, 0.45)
        SetColor(row.progress, COLORS.muted, 0.25)
        row.bg:SetColor(0.010, 0.014, 0.022, 0.30)
    elseif row.ready then
        row:SetAlpha(1)
        SetColor(row.accent, READY_ORANGE, 1)
        SetColor(row.iconBorder, READY_GOLD, 1)
        SetColor(row.percent, READY_WHITE, 1)
        SetColor(row.progress, READY_GOLD, 1)
        row.bg:SetColor(0.18, 0.065, 0.010, 0.96)
    else
        row:SetAlpha(0.64)
        SetColor(row.accent, COLORS.cyan, 0.34)
        SetColor(row.iconBorder, COLORS.cyan, 0.40)
        SetColor(row.percent, COLORS.white, 0.82)
        SetColor(row.progress, COLORS.cyan, 0.72)
        row.bg:SetColor(0.016, 0.024, 0.042, 0.72)
    end

    return row.ready
end

function Group:SetReadyPulseActive(enabled)
    enabled = enabled == true
    if self.readyPulseActive == enabled then return end
    self.readyPulseActive = enabled

    local updateName = "AlphaSquadUI_ULTGroup_ReadyPulse"
    if enabled then
        EM:RegisterForUpdate(updateName, 140, function()
            if Group and Group.UpdateReadyPulse then Group:UpdateReadyPulse() end
        end)
    else
        EM:UnregisterForUpdate(updateName)
        self:ResetReadyPulse()
    end
end

function Group:UpdateReadyPulse()
    if not self.window or self.window:IsHidden() then return end

    local t = (GetGameTimeMilliseconds and GetGameTimeMilliseconds() or 0) / 1000
    local pulse = (math.sin(t * 3.1) + 1) * 0.5

    for _, row in ipairs(self.window.rows or {}) do
        if not row:IsHidden() and row.ready and not row.recentlyUsed then
            local overlayAlpha = 0.10 + (pulse * 0.42)
            local orange = 0.18 + (pulse * 0.24)

            row:SetAlpha(0.92 + (pulse * 0.08))
            row.readyOverlay:SetColor(1.00, 0.46, 0.05, overlayAlpha)
            row.bg:SetColor(orange, 0.065 + (pulse * 0.055), 0.008, 0.96)
            SetColor(row.accent, pulse > 0.50 and READY_WHITE or READY_ORANGE, 1)
            SetColor(row.iconBorder, pulse > 0.50 and READY_WHITE or READY_GOLD, 1)
            SetColor(row.percent, READY_WHITE, 1)
        end
    end
end

function Group:ResetReadyPulse()
    if not self.window then return end

    for _, row in ipairs(self.window.rows or {}) do
        if not row:IsHidden() and row.ready and not row.recentlyUsed then
            row:SetAlpha(1)
            row.readyOverlay:SetColor(1.00, 0.46, 0.05, 0)
            row.bg:SetColor(0.18, 0.065, 0.010, 0.96)
            SetColor(row.accent, READY_ORANGE, 1)
            SetColor(row.iconBorder, READY_GOLD, 1)
            SetColor(row.percent, READY_WHITE, 1)
        end
    end
end

function Group:RefreshHUD()
    if not self.window or not self.sv then return end

    self:ApplyListGeometry()

    local entries = self:GetTrackedEntries()
    local count = #entries
    local rowHeight = self:GetRowHeight()
    local visibleRows = math.max(1, count)
    local height = HEADER_H + 4 + (visibleRows * rowHeight) + ((visibleRows - 1) * GAP) + 4

    self.window:SetDimensions(self:GetListWidth(), height)

    local anyReady = false

    for index, row in ipairs(self.window.rows) do
        local entry = entries[index]

        if entry then
            row:ClearAnchors()
            row:SetAnchor(TOPLEFT, self.window, TOPLEFT, 6, HEADER_H + 4 + ((index - 1) * (rowHeight + GAP)))
        end

        if self:RefreshRow(row, entry) then anyReady = true end
    end

    self.window.empty:SetHidden(count > 0)
    if count == 0 then
        self.window.empty:SetText(self:GetTrackedAbilityCount() == 0 and "Select Ultimates to track" or "No matching players")
    end

    self:SetReadyPulseActive(anyReady and not self.window:IsHidden())
    self:ApplyAppearance()
    self:UpdateLockState()
    self:ApplyVisibility()
end

function Group:ApplyConfigWindowScale()
    if not self.configWindow or not GuiRoot then return end

    local rootW = GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot:GetHeight() or 1080
    local fitX = math.max(0.65, (rootW - 30) / 780)
    local fitY = math.max(0.65, (rootH - 30) / 690)

    self.configWindow:SetScale(math.min(1, fitX, fitY))
end

function Group:CreateHUD()
    local win = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadULTGroupWindow")
    self.window = win

    win:SetDimensions(self:GetListWidth(), 90)
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:SetMouseEnabled(true)
    win:SetDrawTier(DT_HIGH)
    win:SetDrawLayer(DL_OVERLAY)
    win:SetDrawLevel(88)

    win.bg = Solid(win, "AlphaSquadULTGroupBG", COLORS.bg)

    local top = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupTopLine", win, CT_TEXTURE)
    top:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    top:SetAnchor(TOPRIGHT, win, TOPRIGHT, 0, 0)
    top:SetHeight(2)
    SetColor(top, COLORS.orange, 0.55)

    win.dragHint = Label(win, "AlphaSquadULTGroupDragHint", "ZoFontGameSmall", "DRAG", COLORS.gold)
    win.dragHint:SetDimensions(42, HEADER_H)
    win.dragHint:SetAnchor(TOPRIGHT, win, TOPRIGHT, -5, 0)
    win.dragHint:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    win.empty = Label(win, "AlphaSquadULTGroupEmpty", "ZoFontGameSmall", "", COLORS.muted)
    win.empty:SetDimensions(math.max(100, self:GetListWidth() - 20), 32)
    win.empty:SetAnchor(TOPLEFT, win, TOPLEFT, 10, HEADER_H + 14)
    win.empty:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    win.rows = {}
    for index = 1, 12 do
        win.rows[index] = CreateRow(win, index)
        win.rows[index]:SetHidden(true)
    end

    win.dragSurface = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupDragSurface", win, CT_CONTROL)
    win.dragSurface:SetDimensions(self:GetListWidth(), HEADER_H)
    win.dragSurface:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    win.dragSurface:SetMouseEnabled(true)

    win.dragSurface:SetHandler("OnMouseDown", function()
        if Group.sv and not Group.sv.locked then win:StartMoving() end
    end)

    win.dragSurface:SetHandler("OnMouseUp", function()
        if Group.sv and not Group.sv.locked then
            win:StopMovingOrResizing()
            Group:SavePosition()
        end
    end)

    win:SetHandler("OnMoveStop", function()
        if Group.sv and not Group.sv.locked then Group:SavePosition() end
    end)

    self:ApplyListGeometry()
    self:ApplyPosition()
    self:ApplyAppearance()
    self:UpdateLockState()
    self:ApplyVisibility()
end
