-- Ąlpha Şquad UI - ULT Tracker / Group HUD

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}

local ULT = AlphaSquadUI.Modules.ULTTracker
if not ULT or not ULT.Group then return end

local Group = ULT.Group

local COLORS = ULT.COLORS or {
    bg = {0.010, 0.016, 0.030, 0.96},
    panel = {0.020, 0.030, 0.052, 0.98},
    white = {0.95, 0.97, 1.00, 1.00},
    muted = {0.53, 0.62, 0.72, 1.00},
    orange = {1.00, 0.58, 0.16, 1.00},
    cyan = {0.20, 0.82, 1.00, 1.00},
    cyanDim = {0.10, 0.36, 0.49, 1.00},
    green = {0.34, 0.82, 0.52, 1.00},
    red = {1.00, 0.30, 0.35, 1.00},
    gold = {0.97, 0.78, 0.30, 1.00},
}

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
    local row = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupRow" .. index, parent, CT_CONTROL)
    row:SetDimensions(452, 42)

    row.bg = Solid(row, "AlphaSquadULTGroupRow" .. index .. "BG", {0.018, 0.027, 0.047, 0.94})

    row.accent = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupRow" .. index .. "Accent", row, CT_TEXTURE)
    row.accent:SetAnchor(TOPLEFT, row, TOPLEFT, 0, 0)
    row.accent:SetDimensions(3, 42)
    SetColor(row.accent, COLORS.cyanDim)

    row.iconBorder = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupRow" .. index .. "IconBorder", row, CT_TEXTURE)
    row.iconBorder:SetDimensions(34, 34)
    row.iconBorder:SetAnchor(LEFT, row, LEFT, 8, 0)
    SetColor(row.iconBorder, COLORS.cyanDim, 0.55)

    row.icon = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupRow" .. index .. "Icon", row, CT_TEXTURE)
    row.icon:SetDimensions(30, 30)
    row.icon:SetAnchor(CENTER, row.iconBorder, CENTER, 0, 0)
    row.icon:SetTextureCoords(0.05, 0.95, 0.05, 0.95)

    row.player = Label(row, "AlphaSquadULTGroupRow" .. index .. "Player", "ZoFontGameSmall", "", COLORS.white)
    row.player:SetDimensions(118, 18)
    row.player:SetAnchor(TOPLEFT, row, TOPLEFT, 50, 4)
    row.player:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    row.player:SetMaxLineCount(1)

    row.account = Label(row, "AlphaSquadULTGroupRow" .. index .. "Account", "ZoFontGameSmall", "", COLORS.muted)
    row.account:SetDimensions(118, 16)
    row.account:SetAnchor(TOPLEFT, row, TOPLEFT, 50, 21)
    row.account:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    row.account:SetMaxLineCount(1)

    row.ability = Label(row, "AlphaSquadULTGroupRow" .. index .. "Ability", "ZoFontGameSmall", "", COLORS.white)
    row.ability:SetDimensions(145, 20)
    row.ability:SetAnchor(TOPLEFT, row, TOPLEFT, 174, 4)
    row.ability:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    row.ability:SetMaxLineCount(1)

    row.slot = Label(row, "AlphaSquadULTGroupRow" .. index .. "Slot", "ZoFontGameSmall", "", COLORS.muted)
    row.slot:SetDimensions(145, 16)
    row.slot:SetAnchor(TOPLEFT, row, TOPLEFT, 174, 22)
    row.slot:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    row.value = Label(row, "AlphaSquadULTGroupRow" .. index .. "Value", "ZoFontGameBold", "", COLORS.white)
    row.value:SetDimensions(66, 20)
    row.value:SetAnchor(TOPRIGHT, row, TOPRIGHT, -66, 4)
    row.value:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    row.status = Label(row, "AlphaSquadULTGroupRow" .. index .. "Status", "ZoFontGameBold", "", COLORS.muted)
    row.status:SetDimensions(62, 20)
    row.status:SetAnchor(TOPRIGHT, row, TOPRIGHT, -5, 4)
    row.status:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    row.progressBG = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupRow" .. index .. "ProgressBG", row, CT_TEXTURE)
    row.progressBG:SetDimensions(128, 3)
    row.progressBG:SetAnchor(BOTTOMRIGHT, row, BOTTOMRIGHT, -7, -7)
    row.progressBG:SetColor(0.05, 0.08, 0.12, 1)

    row.progress = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupRow" .. index .. "Progress", row, CT_TEXTURE)
    row.progress:SetDimensions(0, 3)
    row.progress:SetAnchor(LEFT, row.progressBG, LEFT, 0, 0)
    SetColor(row.progress, COLORS.cyan)

    return row
end

function Group:GetWindowBaseWidth()
    return 476
end

function Group:GetDefaultPosition()
    local rootW = GuiRoot and GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot and GuiRoot:GetHeight() or 1080
    local width = self:GetWindowBaseWidth()
    return math.max(10, math.floor(rootW - width - 40)), math.floor(rootH * 0.17)
end

function Group:GetEffectiveScale()
    if not self.window or not self.sv or not GuiRoot then
        return (self.sv and self.sv.scale or 100) / 100
    end

    local requested = (self.sv.scale or 100) / 100
    local rootW = GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot:GetHeight() or 1080
    local baseW = self.window:GetWidth() or self:GetWindowBaseWidth()
    local baseH = self.window:GetHeight() or 120

    local fitX = math.max(0.55, (rootW - 24) / math.max(1, baseW))
    local fitY = math.max(0.55, (rootH - 24) / math.max(1, baseH))
    return math.min(requested, fitX, fitY)
end

function Group:ClampToScreen(saveIfChanged)
    if not self.window or not self.sv or not GuiRoot then return end

    local rootW = GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot:GetHeight() or 1080
    local scale = self.window:GetScale() or ((self.sv.scale or 100) / 100)
    local width = (self.window:GetWidth() or self:GetWindowBaseWidth()) * scale
    local height = (self.window:GetHeight() or 120) * scale
    local left = self.window:GetLeft()
    local top = self.window:GetTop()

    if left == nil or top == nil then return end

    local maxX = math.max(0, rootW - width)
    local maxY = math.max(0, rootH - height)
    local x = ULT.Clamp(left, 0, maxX)
    local y = ULT.Clamp(top, 0, maxY)

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
        self.sv.x = x
        self.sv.y = y
    end

    self.window:ClearAnchors()
    self.window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, x, y)
    self:ClampToScreen(true)
end

function Group:SavePosition()
    if not self.window or not self.sv then return end

    local left = self.window:GetLeft()
    local top = self.window:GetTop()

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
    self.sv.x = x
    self.sv.y = y
    self.sv.positionSaved = true

    self:ApplyPosition()
    self:RefreshIntegratedSettings()
end

function Group:UpdateLockState()
    if not self.window or not self.sv then return end

    local movable = not self.sv.locked
    self.window:SetMovable(movable)

    if self.window.dragSurface then
        self.window.dragSurface:SetMouseEnabled(movable)
    end

    if self.window.moveHint then
        self.window.moveHint:SetHidden(not movable)
    end
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
        not self.sv.enabled
        or not self.sv.visible
        or sharedSettingsVisible
        or configVisible
        or (self.sv.hideInMenus and ULT.uiObscured)

    self.window:SetHidden(hidden)
end

function Group:RefreshRow(row, entry)
    if not row then return end

    if not entry then
        row:SetHidden(true)
        return
    end

    row:SetHidden(false)

    local selected = entry.selected or self:GetSelectedUltimate(entry)
    local color = COLORS.cyan
    local status = "CHARGE"
    local abilityName = selected and selected.name or "No Ultimate"
    local abilityIcon = selected and selected.icon or ""
    local slotText = selected and string.upper(selected.slot or "auto") or "AUTO"

    row.player:SetText(entry.characterName or entry.key or "Unknown")
    row.account:SetText(entry.displayName ~= "" and entry.displayName or entry.unitTag or "")

    if not entry.shared then
        row.icon:SetHidden(true)
        row.ability:SetText("NO SHARED DATA")
        row.slot:SetText("Install/share ULT data")
        row.value:SetText("-- / --")
        row.status:SetText("NO DATA")
        SetColor(row.status, COLORS.muted)
        SetColor(row.accent, COLORS.muted, 0.40)
        SetColor(row.iconBorder, COLORS.muted, 0.28)
        row.progress:SetWidth(0)
        return
    end

    if not selected or selected.id <= 0 then
        row.icon:SetHidden(true)
        row.ability:SetText("ULTIMATE NOT SLOTTED")
        row.slot:SetText(slotText)
        row.value:SetText(tostring(entry.ultValue or 0))
        row.status:SetText("EMPTY")
        SetColor(row.status, COLORS.muted)
        SetColor(row.accent, COLORS.muted, 0.45)
        row.progress:SetWidth(0)
        return
    end

    row.icon:SetHidden(false)
    if abilityIcon ~= "" then row.icon:SetTexture(abilityIcon) end
    row.ability:SetText(abilityName)
    row.slot:SetText(slotText .. " ULTIMATE")

    local value = tonumber(entry.ultValue) or 0
    local cost = tonumber(selected.cost) or 0
    local ratio = cost > 0 and math.min(1, math.max(0, value / cost)) or 0

    row.value:SetText(cost > 0 and string.format("%d/%d", value, cost) or tostring(value))

    if selected.ready then
        status = "READY"
        color = COLORS.green
    end

    row.status:SetText(status)
    SetColor(row.status, color)
    SetColor(row.accent, color, selected.ready and 0.95 or 0.65)
    SetColor(row.iconBorder, color, selected.ready and 0.90 or 0.55)
    row.progress:SetWidth(math.floor(128 * ratio))
    SetColor(row.progress, color)
end

function Group:RefreshHUD()
    if not self.window or not self.sv then return end

    local entries = self:GetTrackedEntries()
    local count = #entries
    local visibleRows = math.max(1, count)
    local height = 50 + (visibleRows * 44) + 24

    self.window:SetDimensions(self:GetWindowBaseWidth(), height)
    self.window.title:SetText(string.format("ĄLPHA ŞQUAD  •  GROUP ULTIMATES  •  %d", count))

    local shared, total = self:GetSharingCount()
    if not self.libraryAvailable then
        self.window.source:SetText("SHARING UNAVAILABLE  •  LibGroupCombatStats not detected")
        SetColor(self.window.source, COLORS.red)
    else
        self.window.source:SetText(string.format("ULT SHARING  •  %d/%d members reporting", shared, total))
        SetColor(self.window.source, shared > 0 and COLORS.green or COLORS.muted)
    end

    if count == 0 then
        self.window.empty:SetHidden(false)
        self.window.empty:SetText(total > 0 and "NO PLAYERS SELECTED  •  Configure Group Tracking" or "JOIN A GROUP TO TRACK ULTIMATES")
    else
        self.window.empty:SetHidden(true)
    end

    for index, row in ipairs(self.window.rows) do
        local entry = entries[index]
        self:RefreshRow(row, entry)

        if entry then
            row:ClearAnchors()
            row:SetAnchor(TOPLEFT, self.window, TOPLEFT, 12, 46 + ((index - 1) * 44))
        end
    end

    self:ApplyAppearance()
    self:UpdateLockState()
    self:ApplyVisibility()
end

function Group:CreateHUD()
    local win = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadULTGroupWindow")
    self.window = win

    win:SetDimensions(self:GetWindowBaseWidth(), 118)
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
    SetColor(top, COLORS.orange)

    win.title = Label(win, "AlphaSquadULTGroupTitle", "ZoFontGameBold",
        "ĄLPHA ŞQUAD  •  GROUP ULTIMATES", COLORS.orange)
    win.title:SetDimensions(360, 22)
    win.title:SetAnchor(TOPLEFT, win, TOPLEFT, 14, 6)
    win.title:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.moveHint = Label(win, "AlphaSquadULTGroupMoveHint", "ZoFontGameSmall", "DRAG", COLORS.gold)
    win.moveHint:SetDimensions(55, 20)
    win.moveHint:SetAnchor(TOPRIGHT, win, TOPRIGHT, -12, 7)
    win.moveHint:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    win.source = Label(win, "AlphaSquadULTGroupSource", "ZoFontGameSmall", "", COLORS.muted)
    win.source:SetDimensions(440, 17)
    win.source:SetAnchor(TOPLEFT, win, TOPLEFT, 14, 27)
    win.source:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.empty = Label(win, "AlphaSquadULTGroupEmpty", "ZoFontGame", "", COLORS.muted)
    win.empty:SetDimensions(440, 40)
    win.empty:SetAnchor(TOPLEFT, win, TOPLEFT, 18, 54)
    win.empty:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    win.rows = {}
    for i = 1, 12 do
        win.rows[i] = CreateRow(win, i)
        win.rows[i]:SetHidden(true)
    end

    win.dragSurface = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupDragSurface", win, CT_CONTROL)
    win.dragSurface:SetDimensions(self:GetWindowBaseWidth(), 44)
    win.dragSurface:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    win.dragSurface:SetMouseEnabled(true)

    win.dragSurface:SetHandler("OnMouseDown", function()
        if Group.sv and not Group.sv.locked then
            win:StartMoving()
        end
    end)

    win.dragSurface:SetHandler("OnMouseUp", function()
        if Group.sv and not Group.sv.locked then
            win:StopMovingOrResizing()
            Group:SavePosition()
        end
    end)

    win:SetHandler("OnMoveStop", function()
        if Group.sv and not Group.sv.locked then
            Group:SavePosition()
        end
    end)

    self:ApplyPosition()
    self:ApplyAppearance()
    self:UpdateLockState()
    self:ApplyVisibility()
end
