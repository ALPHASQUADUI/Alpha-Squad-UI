-- Ąlpha Şquad UI - ULT Tracker / Compact Group Grid

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}

local ULT = AlphaSquadUI.Modules.ULTTracker
if not ULT or not ULT.Group then return end

local Group = ULT.Group
local EM = EVENT_MANAGER

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

local CARD_W = 188
local CARD_H = 64
local GAP = 6
local COLS = 3
local HEADER_H = 24
local WINDOW_W = 588

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

local function CreateUltimateLine(card, cardIndex, lineIndex, y)
    local prefix = "AlphaSquadULTGroupCard" .. cardIndex .. "Line" .. lineIndex
    local line = WINDOW_MANAGER:CreateControl(prefix, card, CT_CONTROL)
    line:SetDimensions(CARD_W - 10, 19)
    line:SetAnchor(TOPLEFT, card, TOPLEFT, 5, y)

    line.bg = Solid(line, prefix .. "BG", {0.025, 0.036, 0.058, 0.72})

    line.slot = Label(line, prefix .. "Slot", "ZoFontGameSmall", "", COLORS.muted)
    line.slot:SetDimensions(22, 18)
    line.slot:SetAnchor(LEFT, line, LEFT, 3, 0)
    line.slot:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    line.icon = WINDOW_MANAGER:CreateControl(prefix .. "Icon", line, CT_TEXTURE)
    line.icon:SetDimensions(16, 16)
    line.icon:SetAnchor(LEFT, line, LEFT, 27, 0)
    line.icon:SetTextureCoords(0.05, 0.95, 0.05, 0.95)

    line.name = Label(line, prefix .. "Name", "ZoFontGameSmall", "", COLORS.white)
    line.name:SetDimensions(86, 18)
    line.name:SetAnchor(LEFT, line, LEFT, 47, 0)
    line.name:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    line.name:SetMaxLineCount(1)
    if line.name.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then
        line.name:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    end

    line.value = Label(line, prefix .. "Value", "ZoFontGameSmall", "", COLORS.muted)
    line.value:SetDimensions(48, 18)
    line.value:SetAnchor(RIGHT, line, RIGHT, -3, 0)
    line.value:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    line.ready = false
    return line
end

local function CreateCard(parent, index)
    local card = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupCard" .. index, parent, CT_CONTROL)
    card:SetDimensions(CARD_W, CARD_H)

    card.bg = Solid(card, "AlphaSquadULTGroupCard" .. index .. "BG", {0.016, 0.024, 0.042, 0.96})

    card.accent = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupCard" .. index .. "Accent", card, CT_TEXTURE)
    card.accent:SetAnchor(TOPLEFT, card, TOPLEFT, 0, 0)
    card.accent:SetDimensions(3, CARD_H)
    SetColor(card.accent, COLORS.cyanDim, 0.55)

    card.player = Label(card, "AlphaSquadULTGroupCard" .. index .. "Player", "ZoFontGameBold", "", COLORS.white)
    card.player:SetDimensions(CARD_W - 14, 18)
    card.player:SetAnchor(TOPLEFT, card, TOPLEFT, 7, 1)
    card.player:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    card.player:SetMaxLineCount(1)
    if card.player.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then
        card.player:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    end

    card.line1 = CreateUltimateLine(card, index, 1, 21)
    card.line2 = CreateUltimateLine(card, index, 2, 42)
    return card
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
    local left = self.window:GetLeft()
    local top = self.window:GetTop()

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

    if self.window.dragSurface then
        self.window.dragSurface:SetMouseEnabled(movable)
    end
    if self.window.dragHint then
        self.window.dragHint:SetHidden(not movable)
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
        not ULT.sv.enabled
        or not self.sv.enabled
        or not self.sv.visible
        or sharedSettingsVisible
        or configVisible
        or (self.sv.hideInMenus and ULT.uiObscured)

    self.window:SetHidden(hidden)

    if hidden then
        self:SetReadyPulseActive(false)
    end
end

function Group:RefreshUltimateLine(line, ultimate, shared)
    if not line then return false end

    if not shared then
        line:SetHidden(false)
        line.slot:SetText("--")
        line.icon:SetHidden(true)
        line.name:SetText("NO DATA")
        line.value:SetText("")
        line.ready = false
        line.bg:SetColor(0.025, 0.036, 0.058, 0.35)
        return false
    end

    if not ultimate or ultimate.id <= 0 then
        line:SetHidden(false)
        line.slot:SetText(ultimate and ultimate.slot == "back" and "B" or "F")
        line.icon:SetHidden(true)
        line.name:SetText("EMPTY")
        line.value:SetText("")
        line.ready = false
        line.bg:SetColor(0.025, 0.036, 0.058, 0.45)
        return false
    end

    line:SetHidden(false)
    line.slot:SetText(ultimate.slot == "back" and "B" or "F")
    line.icon:SetHidden(false)
    if ultimate.icon and ultimate.icon ~= "" then line.icon:SetTexture(ultimate.icon) end
    line.name:SetText(ultimate.name or "Ultimate")

    local value = tonumber(ultimate.value) or 0
    local cost = tonumber(ultimate.cost) or 0
    line.value:SetText(cost > 0 and string.format("%d/%d", value, cost) or tostring(value))

    line.ready = ultimate.ready == true
    if line.ready then
        SetColor(line.slot, COLORS.green)
        SetColor(line.value, COLORS.green)
        line.bg:SetColor(0.055, 0.120, 0.080, 0.80)
    else
        SetColor(line.slot, COLORS.muted)
        SetColor(line.value, COLORS.muted)
        line.bg:SetColor(0.025, 0.036, 0.058, 0.72)
    end

    return line.ready
end

function Group:RefreshCard(card, entry)
    if not card then return false end

    if not entry then
        card:SetHidden(true)
        card.line1.ready = false
        card.line2.ready = false
        return false
    end

    card:SetHidden(false)
    card.player:SetText(entry.characterName or entry.displayName or entry.key or "Unknown")

    local ultimates = entry.selectedUltimates or self:GetSelectedUltimates(entry)
    local ready = false

    if #ultimates <= 1 then
        card.line1:ClearAnchors()
        card.line1:SetAnchor(TOPLEFT, card, TOPLEFT, 5, 31)
        card.line2:SetHidden(true)
        card.line2.ready = false
        ready = self:RefreshUltimateLine(card.line1, ultimates[1], entry.shared)
    else
        card.line1:ClearAnchors()
        card.line1:SetAnchor(TOPLEFT, card, TOPLEFT, 5, 21)
        card.line2:ClearAnchors()
        card.line2:SetAnchor(TOPLEFT, card, TOPLEFT, 5, 42)
        local ready1 = self:RefreshUltimateLine(card.line1, ultimates[1], entry.shared)
        local ready2 = self:RefreshUltimateLine(card.line2, ultimates[2], entry.shared)
        ready = ready1 or ready2
    end

    SetColor(card.accent, ready and COLORS.green or COLORS.cyanDim, ready and 0.90 or 0.45)
    return ready
end

function Group:SetReadyPulseActive(enabled)
    enabled = enabled == true
    if self.readyPulseActive == enabled then return end
    self.readyPulseActive = enabled

    local updateName = "AlphaSquadUI_ULTGroup_ReadyPulse"
    if enabled then
        EM:RegisterForUpdate(updateName, 180, function()
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
    local pulse = (math.sin(t * 3.2) + 1) * 0.5
    local alpha = 0.50 + (pulse * 0.28)

    for _, card in ipairs(self.window.cards or {}) do
        if not card:IsHidden() then
            for _, line in ipairs({card.line1, card.line2}) do
                if line and not line:IsHidden() and line.ready then
                    line.bg:SetColor(0.055, 0.145, 0.090, alpha)
                end
            end
        end
    end
end

function Group:ResetReadyPulse()
    if not self.window then return end
    for _, card in ipairs(self.window.cards or {}) do
        if not card:IsHidden() then
            for _, line in ipairs({card.line1, card.line2}) do
                if line and not line:IsHidden() and line.ready then
                    line.bg:SetColor(0.055, 0.120, 0.080, 0.80)
                end
            end
        end
    end
end

function Group:RefreshHUD()
    if not self.window or not self.sv then return end

    local entries = self:GetTrackedEntries()
    local count = #entries
    local rows = math.max(1, math.ceil(count / COLS))
    local height = HEADER_H + 6 + (rows * CARD_H) + ((rows - 1) * GAP) + 6

    self.window:SetDimensions(WINDOW_W, height)

    local shared, total = self:GetSharingCount()
    self.window.status:SetText(string.format("GROUP ULT  •  %d tracked", count))
    self.window.share:SetText(self.libraryAvailable and string.format("%d/%d share", shared, total) or "NO SHARE LIB")

    local anyReady = false

    for index, card in ipairs(self.window.cards) do
        local entry = entries[index]
        if entry then
            local col = (index - 1) % COLS
            local row = math.floor((index - 1) / COLS)
            card:ClearAnchors()
            card:SetAnchor(TOPLEFT, self.window, TOPLEFT,
                6 + (col * (CARD_W + GAP)),
                HEADER_H + 6 + (row * (CARD_H + GAP)))
        end

        if self:RefreshCard(card, entry) then anyReady = true end
    end

    self.window.empty:SetHidden(count > 0)
    if count == 0 then
        self.window.empty:SetText(total > 0 and "No players selected" or "Join a group")
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
    local fitY = math.max(0.65, (rootH - 30) / 720)
    self.configWindow:SetScale(math.min(1, fitX, fitY))
end

function Group:CreateHUD()
    local win = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadULTGroupWindow")
    self.window = win

    win:SetDimensions(WINDOW_W, 100)
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
    SetColor(top, COLORS.orange, 0.75)

    win.status = Label(win, "AlphaSquadULTGroupStatus", "ZoFontGameSmall", "GROUP ULT", COLORS.muted)
    win.status:SetDimensions(250, 20)
    win.status:SetAnchor(TOPLEFT, win, TOPLEFT, 7, 2)
    win.status:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.share = Label(win, "AlphaSquadULTGroupShare", "ZoFontGameSmall", "", COLORS.muted)
    win.share:SetDimensions(120, 20)
    win.share:SetAnchor(TOPRIGHT, win, TOPRIGHT, -48, 2)
    win.share:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    win.dragHint = Label(win, "AlphaSquadULTGroupDragHint", "ZoFontGameSmall", "DRAG", COLORS.gold)
    win.dragHint:SetDimensions(42, 20)
    win.dragHint:SetAnchor(TOPRIGHT, win, TOPRIGHT, -5, 2)
    win.dragHint:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    win.empty = Label(win, "AlphaSquadULTGroupEmpty", "ZoFontGameSmall", "", COLORS.muted)
    win.empty:SetDimensions(WINDOW_W - 20, 42)
    win.empty:SetAnchor(TOPLEFT, win, TOPLEFT, 10, HEADER_H + 18)
    win.empty:SetHorizontalAlignment(TEXT_ALIGN_CENTER)

    win.cards = {}
    for index = 1, 12 do
        win.cards[index] = CreateCard(win, index)
        win.cards[index]:SetHidden(true)
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
