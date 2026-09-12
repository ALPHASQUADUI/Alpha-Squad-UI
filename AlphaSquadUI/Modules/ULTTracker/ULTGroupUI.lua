-- Ąlpha Şquad UI - ULT Tracker / Compact Group Ultimate List

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
    green = {0.34, 0.82, 0.52, 1.00},
    gold = {0.97, 0.78, 0.30, 1.00},
}

local ROW_W = 430
local ROW_H = 30
local HEADER_H = 22
local GAP = 2
local WINDOW_W = 442

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

local function CreateRow(parent, index)
    local row = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupListRow" .. index, parent, CT_CONTROL)
    row:SetDimensions(ROW_W, ROW_H)

    row.bg = Solid(row, "AlphaSquadULTGroupListRow" .. index .. "BG", {0.016, 0.024, 0.042, 0.92})

    row.accent = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupListRow" .. index .. "Accent", row, CT_TEXTURE)
    row.accent:SetDimensions(3, ROW_H)
    row.accent:SetAnchor(TOPLEFT, row, TOPLEFT, 0, 0)
    SetColor(row.accent, COLORS.cyan, 0.30)

    row.user = Label(row, "AlphaSquadULTGroupListRow" .. index .. "User", "ZoFontGameBold", "", COLORS.white)
    row.user:SetDimensions(135, ROW_H)
    row.user:SetAnchor(LEFT, row, LEFT, 8, 0)
    row.user:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    row.user:SetMaxLineCount(1)
    if row.user.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then
        row.user:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    end

    row.icon1 = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupListRow" .. index .. "Icon1", row, CT_TEXTURE)
    row.icon1:SetDimensions(22, 22)
    row.icon1:SetAnchor(LEFT, row, LEFT, 146, 0)
    row.icon1:SetTextureCoords(0.05, 0.95, 0.05, 0.95)

    row.icon2 = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupListRow" .. index .. "Icon2", row, CT_TEXTURE)
    row.icon2:SetDimensions(22, 22)
    row.icon2:SetAnchor(LEFT, row, LEFT, 171, 0)
    row.icon2:SetTextureCoords(0.05, 0.95, 0.05, 0.95)

    row.ability = Label(row, "AlphaSquadULTGroupListRow" .. index .. "Ability", "ZoFontGameSmall", "", COLORS.white)
    row.ability:SetDimensions(150, ROW_H)
    row.ability:SetAnchor(LEFT, row, LEFT, 198, 0)
    row.ability:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    row.ability:SetMaxLineCount(1)
    if row.ability.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then
        row.ability:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    end

    row.value = Label(row, "AlphaSquadULTGroupListRow" .. index .. "Value", "ZoFontGameSmall", "", COLORS.muted)
    row.value:SetDimensions(72, ROW_H)
    row.value:SetAnchor(RIGHT, row, RIGHT, -7, 0)
    row.value:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    row.ready = false
    row.recentlyUsed = false
    return row
end

function Group:GetWindowBaseWidth()
    return WINDOW_W
end

function Group:GetDefaultPosition()
    local rootW = GuiRoot and GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot and GuiRoot:GetHeight() or 1080
    return math.max(8, math.floor(rootW - WINDOW_W - 30)), math.floor(rootH * 0.16)
end

function Group:GetEffectiveScale()
    if not self.window or not self.sv or not GuiRoot then
        return (self.sv and self.sv.scale or 100) / 100
    end

    local requested = (self.sv.scale or 100) / 100
    local rootW = GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot:GetHeight() or 1080
    local baseW = self.window:GetWidth() or WINDOW_W
    local baseH = self.window:GetHeight() or 100

    local fitX = math.max(0.55, (rootW - 20) / math.max(1, baseW))
    local fitY = math.max(0.55, (rootH - 20) / math.max(1, baseH))
    return math.min(requested, fitX, fitY)
end

function Group:ClampToScreen(saveIfChanged)
    if not self.window or not self.sv or not GuiRoot then return end

    local rootW = GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot:GetHeight() or 1080
    local scale = self.window:GetScale() or ((self.sv.scale or 100) / 100)
    local width = (self.window:GetWidth() or WINDOW_W) * scale
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
    if self.window.bg then self.window.bg:SetAlpha((self.sv.opacity or 92) / 100) end
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
    row.user:SetText(entry.displayName ~= "" and entry.displayName or entry.key or "@Unknown")

    local matches = entry.matchingUltimates or self:GetMatchingUltimates(entry)
    local first = matches[1]
    local second = matches[2]

    row.icon1:SetHidden(not first or not first.icon or first.icon == "")
    if first and first.icon and first.icon ~= "" then row.icon1:SetTexture(first.icon) end

    row.icon2:SetHidden(not second or not second.icon or second.icon == "")
    if second and second.icon and second.icon ~= "" then row.icon2:SetTexture(second.icon) end

    if first and second then
        row.ability:SetText((first.name or "Ultimate") .. " + " .. (second.name or "Ultimate"))
    elseif first then
        row.ability:SetText(first.name or "Ultimate")
    else
        row.ability:SetText("Tracked Ultimate")
    end

    local ready = false
    local bestCost = 0
    for _, ultimate in ipairs(matches) do
        if ultimate.ready then ready = true end
        local cost = tonumber(ultimate.cost) or 0
        if cost > 0 and (bestCost == 0 or cost < bestCost) then bestCost = cost end
    end

    local value = tonumber(entry.ultValue) or 0
    row.value:SetText(bestCost > 0 and string.format("%d/%d", value, bestCost) or tostring(value))

    row.ready = ready
    row.recentlyUsed = entry.recentlyUsed == true

    if row.recentlyUsed then
        row:SetAlpha(0.28)
        SetColor(row.accent, COLORS.muted, 0.20)
        SetColor(row.value, COLORS.muted, 0.55)
        row.bg:SetColor(0.012, 0.018, 0.030, 0.38)
    elseif row.ready then
        row:SetAlpha(1)
        SetColor(row.accent, COLORS.green, 0.95)
        SetColor(row.value, COLORS.green, 1)
        row.bg:SetColor(0.045, 0.105, 0.070, 0.84)
    else
        row:SetAlpha(0.62)
        SetColor(row.accent, COLORS.cyan, 0.26)
        SetColor(row.value, COLORS.muted, 0.75)
        row.bg:SetColor(0.016, 0.024, 0.042, 0.68)
    end

    return ready
end

function Group:SetReadyPulseActive(enabled)
    enabled = enabled == true
    if self.readyPulseActive == enabled then return end
    self.readyPulseActive = enabled

    local name = "AlphaSquadUI_ULTGroup_ReadyPulse"
    if enabled then
        EM:RegisterForUpdate(name, 160, function()
            if Group and Group.UpdateReadyPulse then Group:UpdateReadyPulse() end
        end)
    else
        EM:UnregisterForUpdate(name)
        self:ResetReadyPulse()
    end
end

function Group:UpdateReadyPulse()
    if not self.window or self.window:IsHidden() then return end

    local t = (GetGameTimeMilliseconds and GetGameTimeMilliseconds() or 0) / 1000
    local pulse = (math.sin(t * 3.6) + 1) * 0.5

    for _, row in ipairs(self.window.rows or {}) do
        if not row:IsHidden() and row.ready and not row.recentlyUsed then
            row:SetAlpha(0.86 + pulse * 0.14)
            row.bg:SetColor(0.045, 0.120 + pulse * 0.055, 0.078, 0.76 + pulse * 0.16)
            SetColor(row.accent, COLORS.green, 0.72 + pulse * 0.28)
        end
    end
end

function Group:ResetReadyPulse()
    if not self.window then return end
    for _, row in ipairs(self.window.rows or {}) do
        if not row:IsHidden() and row.ready and not row.recentlyUsed then
            row:SetAlpha(1)
            row.bg:SetColor(0.045, 0.105, 0.070, 0.84)
            SetColor(row.accent, COLORS.green, 0.95)
        end
    end
end

function Group:RefreshHUD()
    if not self.window or not self.sv then return end

    local entries = self:GetTrackedEntries()
    local count = #entries
    local rows = math.max(1, count)
    local height = HEADER_H + 5 + (rows * ROW_H) + ((rows - 1) * GAP) + 5
    self.window:SetDimensions(WINDOW_W, height)

    self.window.status:SetText(string.format("%d tracked", count))
    self.window.filter:SetText(string.format("%d Ultimates", self:GetTrackedAbilityCount()))

    local anyReady = false
    for index, row in ipairs(self.window.rows) do
        local entry = entries[index]
        if entry then
            row:ClearAnchors()
            row:SetAnchor(TOPLEFT, self.window, TOPLEFT, 6, HEADER_H + 5 + ((index - 1) * (ROW_H + GAP)))
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
    local fitY = math.max(0.65, (rootH - 30) / 700)
    self.configWindow:SetScale(math.min(1, fitX, fitY))
end

function Group:CreateHUD()
    local win = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadULTGroupWindow")
    self.window = win

    win:SetDimensions(WINDOW_W, 90)
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
    SetColor(top, COLORS.orange, 0.65)

    win.status = Label(win, "AlphaSquadULTGroupStatus", "ZoFontGameSmall", "", COLORS.muted)
    win.status:SetDimensions(100, 20)
    win.status:SetAnchor(TOPLEFT, win, TOPLEFT, 7, 2)
    win.status:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.filter = Label(win, "AlphaSquadULTGroupFilter", "ZoFontGameSmall", "", COLORS.muted)
    win.filter:SetDimensions(110, 20)
    win.filter:SetAnchor(TOPRIGHT, win, TOPRIGHT, -48, 2)
    win.filter:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    win.dragHint = Label(win, "AlphaSquadULTGroupDragHint", "ZoFontGameSmall", "DRAG", COLORS.gold)
    win.dragHint:SetDimensions(42, 20)
    win.dragHint:SetAnchor(TOPRIGHT, win, TOPRIGHT, -5, 2)
    win.dragHint:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    win.empty = Label(win, "AlphaSquadULTGroupEmpty", "ZoFontGameSmall", "", COLORS.muted)
    win.empty:SetDimensions(WINDOW_W - 20, 36)
    win.empty:SetAnchor(TOPLEFT, win, TOPLEFT, 10, HEADER_H + 16)
    win.empty:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    win.rows = {}
    for index = 1, 12 do
        win.rows[index] = CreateRow(win, index)
        win.rows[index]:SetHidden(true)
    end

    win.dragSurface = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupDragSurface", win, CT_CONTROL)
    win.dragSurface:SetDimensions(WINDOW_W, HEADER_H)
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

    self:ApplyPosition()
    self:ApplyAppearance()
    self:UpdateLockState()
    self:ApplyVisibility()
end
