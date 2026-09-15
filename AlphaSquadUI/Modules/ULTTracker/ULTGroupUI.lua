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
local HEADER_H = 22
local GAP = 4
Group.layoutName="Group Ultimates"
Group.layoutBounds={minWidth=240,minHeight=70,maxWidth=1800,maxHeight=1200}

local READY_ORANGE = {1.00, 0.46, 0.05, 1.00}
local READY_GOLD = {1.00, 0.82, 0.18, 1.00}
local READY_WHITE = {1.00, 0.98, 0.88, 1.00}

local function Palette(role,fallback)
    local theme=AlphaSquadUI.Theme
    return theme and theme.colors and theme.colors[role] or COLORS[role] or fallback or COLORS.bg
end
local function SetColor(control, color, alpha)
    if not control or not color then return end
    control:SetColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

local function Solid(parent, name, color)
    local texture = WINDOW_MANAGER:CreateControl(name, parent, CT_TEXTURE)
    texture:SetAnchorFill(parent)
    SetColor(texture, color)
    if AlphaSquadUI.Theme and AlphaSquadUI.Theme.BindColor then AlphaSquadUI.Theme.BindColor(texture,color) end
    return texture
end

local function Label(parent, name, font, text, color)
    local label = WINDOW_MANAGER:CreateControl(name, parent, CT_LABEL)
    label:SetFont(font)
    label:SetText(text or "")
    SetColor(label, color or COLORS.white)
    if AlphaSquadUI.Theme and AlphaSquadUI.Theme.BindColor then AlphaSquadUI.Theme.BindColor(label,color or COLORS.white) end
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    return label
end

local EMPTY_ICON="EsoUI/Art/ActionBar/abilityFrame64_up.dds"
local previewEntries,previewMode
local function PreviewMode(module)
    if not (AlphaSquadUI.Layout and AlphaSquadUI.Layout.IsMoving(module)) then return "live" end
    local preview=AlphaSquadUI.Preview
    return preview and preview.GetMode and preview.GetMode() or module.layoutPreviewMode or "mixed"
end
function Group:SetLayoutPreview(mode)
    self.layoutPreviewMode=mode
    if self.RefreshHUD then self:RefreshHUD() end
end
function Group:GetHUDEntries()
    local mode=PreviewMode(self)
    if mode=="live" then return self:GetTrackedEntries() end
    if not previewEntries or previewMode~=mode then
        previewMode=mode;previewEntries={}
        for index=1,12 do
            local name=index<=2 and string.format("@Tank%02d",index) or index<=4 and string.format("@Healer%02d",index-2) or string.format("@Damage%02d",index-4)
            local id=index<=4 and 40223 or (index%2==0 and 122174 or 30366)
            local nativeName,nativeIcon=self:GetAbilityMeta(id)
            local state=mode=="ready" and "ready" or mode=="missing" and "missing" or ({"ready","ready","charging","ready","charging","charging","used","off","missing","offline","dead","charging"})[index]
            local percent=state=="ready" and 100 or state=="charging" and (97-index*5) or state=="used" and 8 or 0
            previewEntries[index]={key=name,displayName=name,preview=true,previewState=state,chargePercent=percent,
                connected=state~="offline",dead=state=="dead",shared=state~="off" and state~="missing",
                anyReady=state=="ready",unavailable=state=="offline" or state=="dead" or state=="off" or state=="missing",
                recentlyUsed=state=="used",bestUltimate={id=state=="missing" and 0 or id,name=state=="missing" and "No Ultimate slotted" or nativeName,icon=state=="missing" and EMPTY_ICON or (nativeIcon~="" and nativeIcon or EMPTY_ICON)}}
        end
    end
    return previewEntries
end
function Group:GetLayoutOrientation()
    return self.sv and self.sv.hudOrientation=="horizontal" and "horizontal" or "vertical"
end
function Group:GetLayoutOrientations()
    return {"vertical","horizontal"}
end
function Group:SetLayoutOrientation(orientation)
    if not self.sv or (orientation~="horizontal" and orientation~="vertical") then return false end
    local previous=self:GetLayoutOrientation()
    if previous==orientation then return false end
    if type(self.sv.hudLayouts)~="table" then self.sv.hudLayouts={} end
    self.sv.hudLayouts[previous]={width=self.layoutWidth or self.sv.hudWidth,height=self.layoutHeight or self.sv.hudHeight}
    self.sv.hudOrientation=orientation
    local saved=self.sv.hudLayouts[orientation]
    self.sv.hudWidth=type(saved)=="table" and saved.width or nil
    self.sv.hudHeight=type(saved)=="table" and saved.height or nil
    self:RefreshHUD()
    return true
end
function Group:GetHUDDimensions(count)
    local visible=math.max(1,math.min(12,count or self.layoutEntryCount or 0))
    local horizontal=self:GetLayoutOrientation()=="horizontal"
    local columns=horizontal and 4 or 1
    local rows=math.ceil(visible/columns)
    self.layoutColumns=columns
    local naturalRow=ULT.Clamp(self.sv and self.sv.rowHeight or BASE_ROW_H,28,56)
    local naturalHeight=math.max(70,HEADER_H+8+rows*naturalRow+(rows-1)*GAP)
    self.layoutBounds.minWidth=horizontal and 856 or 240
    self.layoutBounds.minHeight=math.max(70,HEADER_H+8+rows*28+(rows-1)*GAP)
    local defaultWidth=horizontal and 1020 or BASE_WINDOW_W
    local layout=AlphaSquadUI.Layout
    if layout and layout.GetDimensions then return layout.GetDimensions(self,defaultWidth,naturalHeight) end
    return ULT.Clamp(self.sv and self.sv.hudWidth or defaultWidth,self.layoutBounds.minWidth,1800),
        ULT.Clamp(self.sv and self.sv.hudHeight or naturalHeight,self.layoutBounds.minHeight,1200)
end
function Group:GetListWidth() return self.layoutWidth or (self:GetHUDDimensions()) end
function Group:GetRowHeight()
    return self.layoutRowHeight or ULT.Clamp(self.sv and self.sv.rowHeight or BASE_ROW_H,28,56)
end
function Group:GetIconSize() return ULT.Clamp(self:GetRowHeight()-8,20,44) end
function Group:GetRowWidth()
    local columns=self.layoutColumns or 1
    return math.max(1,(self:GetListWidth()-12-(columns-1)*GAP)/columns)
end
function Group:GetWindowBaseWidth() return self:GetListWidth() end

local function CreateRow(parent, index)
    local row = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupListRow" .. index, parent, CT_CONTROL)
    row:SetDimensions(BASE_WINDOW_W - 12, BASE_ROW_H)

    row.bg = Solid(row, "AlphaSquadULTGroupListRow" .. index .. "BG", Palette("surface"))
    if AlphaSquadUI.Theme and AlphaSquadUI.Theme.RegisterSurface then AlphaSquadUI.Theme.RegisterSurface(row,row.bg,"tile") end

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
    row:SetMouseEnabled(true)
    row:SetHandler("OnMouseEnter",function()
        local entry=row.entry
        local tips=AlphaSquadUI.Tooltips
        if not entry or not tips or not tips.ShowText then return end
        local ultimate=entry.bestUltimate
        local state=entry.previewState or (entry.connected==false and "offline" or entry.dead and "dead" or entry.stale and "stale" or entry.recentlyUsed and "used" or entry.anyReady and "ready" or "charging")
        local states={ready="Ready",charging="Charging",used="Recently spent",offline="Offline",dead="Dead",stale="Update needed",missing="No Ultimate available",off="Sharing off"}
        tips.ShowText(row,(entry.preview and "Placement example\n" or "")..(entry.displayName or "").."\n"..(ultimate and ultimate.name or "Ultimate unavailable").."\n"..(states[state] or "Unknown"))
    end)
    row:SetHandler("OnMouseExit",function() if AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.Hide() end end)
    if AlphaSquadUI.Input and AlphaSquadUI.Input.Register then AlphaSquadUI.Input.Register(row,{label="Group Ultimate"}) end
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
    local percentWidth = 66
    local rightPadding = 8
    local userWidth = math.max(1, width - userX - percentWidth - rightPadding - 8)
    local progressWidth = math.max(1, width - userX - 8)

    row:SetDimensions(width, height)
    row.accent:SetDimensions(4, height)

    row.iconBorder:SetDimensions(iconBorderSize, iconBorderSize)
    row.iconBorder:ClearAnchors()
    row.iconBorder:SetAnchor(LEFT, row, LEFT, iconX, 0)

    row.icon:SetDimensions(iconSize, iconSize)

    row.user:SetFont(width<260 and "ZoFontGameSmall" or "ZoFontGameBold")
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

    if self.window.title then self.window.title:SetWidth(math.max(100,width-16)) end
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
    if AlphaSquadUI.Layout and AlphaSquadUI.Layout.GetScale then return AlphaSquadUI.Layout.GetScale(self,self.layoutWidth,self.layoutHeight) end
    if not self.window or not self.sv or not GuiRoot then
        return (self.sv and self.sv.scale or 100) / 100
    end

    local requested = (self.sv.scale or 100) / 100
    local rootW = GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot:GetHeight() or 1080
    local scale=self.window:GetScale() or 1
    local baseW = self.layoutWidth or self.window:GetWidth()/math.max(0.001,scale)
    local baseH = self.layoutHeight or self.window:GetHeight()/math.max(0.001,scale)

    local fitX = math.max(0.001, (rootW - 20) / math.max(1, baseW))
    local fitY = math.max(0.001, (rootH - 20) / math.max(1, baseH))
    return math.min(requested, fitX, fitY)
end

function Group:ClampToScreen(saveIfChanged)
    if not self.window or not self.sv or not GuiRoot then return end

    local rootW = GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot:GetHeight() or 1080
    local width = self.window:GetWidth() or self:GetListWidth()
    local height = self.window:GetHeight() or 100
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
    self:ClampToScreen(false)
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
    self.sv.hudHeight = nil
    self.sv.rowHeight = BASE_ROW_H

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
    if self.window.dragHint then self.window.dragHint:SetHidden(true) end
end

function Group:ApplyAppearance()
    if not self.window or not self.sv then return end

    self.window:SetScale(self:GetEffectiveScale())
    self.window:SetAlpha(1)

    if self.window.bg then
        self.window.bg:SetAlpha((self.sv.opacity or 92) / 100)
    end

    self:ClampToScreen(false)
end

function Group:ApplyVisibility()
    if not self.window or not self.sv then return end

    local sharedSettings = AlphaSquadUI and AlphaSquadUI.Settings and AlphaSquadUI.Settings.mainWindow
    local sharedSettingsVisible = sharedSettings and not sharedSettings:IsHidden() or false
    local settings = AlphaSquadUI.Settings
    if settings and settings.AnyExclusiveWindowVisible then
        sharedSettingsVisible = sharedSettingsVisible or settings.AnyExclusiveWindowVisible()
    end
    local configVisible = self.configWindow and not self.configWindow:IsHidden() or false

    local moving = AlphaSquadUI.Layout and AlphaSquadUI.Layout.IsMoving(self)
    local hidden =
        ULT.loading == true
        or not ULT.sv.enabled
        or not self.sv.enabled
        or sharedSettingsVisible
        or configVisible
        or (self.sv.hideInMenus and ULT.uiObscured and not moving)

    self.window:SetHidden(hidden)
    if self.SetSafetyUpdateActive then self:SetSafetyUpdateActive(not hidden and not moving) end

    if hidden then
        self:SetReadyPulseActive(false)
    else
        local anyReady = false
        for _, row in ipairs(self.window.rows or {}) do
            if not row:IsHidden() and row.ready and not row.recentlyUsed then
                anyReady = true
                break
            end
        end
        self:SetReadyPulseActive(anyReady and not moving)
    end
end

function Group:RefreshRow(row, entry)
    if not row then return false end

    row.entry=entry
    if not entry then
        row:SetHidden(true)
        row.ready = false
        row.recentlyUsed = false
        return false
    end

    row:SetHidden(false)

    local userId = entry.displayName ~= "" and entry.displayName or entry.key or "@Unknown"
    row.user:SetText(AlphaSquadUI.Theme and AlphaSquadUI.Theme.PlayerName and AlphaSquadUI.Theme.PlayerName(userId) or userId)

    local ultimate = entry.bestUltimate
    if not ultimate then
        ultimate = self:GetBestMatchingUltimate(entry)
    end

    row.icon:SetHidden(false)
    row.icon:SetTexture(ultimate and ultimate.icon and ultimate.icon~="" and ultimate.icon or EMPTY_ICON)

    local percent = tonumber(entry.chargePercent) or 0
    percent = math.min(100, math.max(0, math.floor(percent + 0.5)))
    if entry.previewState=="missing" then row.percent:SetText("NONE")
    elseif entry.previewState=="off" then row.percent:SetText("OFF")
    elseif entry.stale then row.percent:SetText("STALE")
    elseif entry.recentlyUsed then row.percent:SetText("USED")
    elseif entry.connected == false then row.percent:SetText("OFFLINE")
    elseif entry.dead == true then row.percent:SetText("DEAD")
    else row.percent:SetText(tostring(percent) .. "%") end

    local progressWidth = row.geometryProgressWidth or math.max(80, self:GetRowWidth() - 52)
    row.progress:SetWidth(math.floor(progressWidth * (percent / 100)))

    row.ready = entry.anyReady == true
    row.unavailable = entry.unavailable == true
    row.recentlyUsed = entry.recentlyUsed == true

    row.readyOverlay:SetColor(1.00, 0.46, 0.05, 0)

    if row.unavailable then
        row:SetAlpha(0.62)
        SetColor(row.accent, COLORS.muted, 0.16)
        SetColor(row.iconBorder, COLORS.muted, 0.18)
        SetColor(row.percent, COLORS.muted, 0.60)
        SetColor(row.progress, COLORS.muted, 0.25)
        SetColor(row.bg,Palette("surface"),0.30)
    elseif row.recentlyUsed then
        row:SetAlpha(0.55)
        SetColor(row.accent, COLORS.muted, 0.16)
        SetColor(row.iconBorder, COLORS.muted, 0.18)
        SetColor(row.percent, COLORS.muted, 0.45)
        SetColor(row.progress, COLORS.muted, 0.25)
        SetColor(row.bg,Palette("surface"),0.30)
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
        SetColor(row.bg,Palette("surface"),0.72)
    end

    return row.ready
end

function Group:SetReadyPulseActive(enabled)
    enabled = enabled == true and not (AlphaSquadUI.Layout and AlphaSquadUI.Layout.IsMoving(self))
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

    local entries=self:GetHUDEntries()
    local count=math.min(12,#entries)
    self.layoutEntryCount=count
    local width,height=self:GetHUDDimensions(count)
    self.layoutWidth,self.layoutHeight=width,height
    local columns=self.layoutColumns or 1
    local visibleRows=math.max(1,math.ceil(count/columns))
    self.layoutRowHeight=math.max(28,(height-HEADER_H-8-(visibleRows-1)*GAP)/visibleRows)
    local rowHeight=self:GetRowHeight()
    local rowWidth=self:GetRowWidth()
    self.window:SetDimensions(width,height)
    self:ApplyListGeometry()
    if self.window.title then self.window.title:SetText(PreviewMode(self)~="live" and "GROUP ULT • 12 EXAMPLES" or "GROUP ULTIMATES") end
    for index, row in ipairs(self.window.rows) do
        local entry = entries[index]
        if entry then
            local column=(index-1)%columns
            local line=math.floor((index-1)/columns)
            row:ClearAnchors()
            row:SetAnchor(TOPLEFT,self.window,TOPLEFT,6+column*(rowWidth+GAP),HEADER_H+4+line*(rowHeight+GAP))
        end
        self:RefreshRow(row,entry)
    end

    self.window.empty:SetHidden(count > 0)
    if count == 0 then
        self.window.empty:SetText(self:GetEmptyMessage())
    end

    self:ApplyAppearance()
    self:UpdateLockState()
    self:ApplyVisibility()
end

function Group:ApplyLayout() self:RefreshHUD() end

function Group:ApplyConfigWindowScale()
    if not self.configWindow or not GuiRoot then return end

    local rootW = GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot:GetHeight() or 1080
    local fitX = math.max(0.001, (rootW - 30) / 780)
    local fitY = math.max(0.001, (rootH - 30) / 630)

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
    if AlphaSquadUI.Settings and AlphaSquadUI.Settings.ApplyWindowLayer then AlphaSquadUI.Settings.ApplyWindowLayer(win, true) end

    win.bg = Solid(win, "AlphaSquadULTGroupBG", COLORS.bg)

    local top = WINDOW_MANAGER:CreateControl("AlphaSquadULTGroupTopLine", win, CT_TEXTURE)
    top:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    top:SetAnchor(TOPRIGHT, win, TOPRIGHT, 0, 0)
    top:SetHeight(2)
    SetColor(top, COLORS.orange, 0.55)

    win.title=Label(win,"AlphaSquadULTGroupTitle","ZoFontGameSmall","GROUP ULTIMATES",COLORS.orange)
    win.title:SetDimensions(200,HEADER_H)
    win.title:SetMaxLineCount(1)
    win.title:SetAnchor(TOPLEFT,win,TOPLEFT,8,0)
    if AlphaSquadUI.Theme then
        AlphaSquadUI.Theme.BindColor(top,"accent",0.55)
        AlphaSquadUI.Theme.BindColor(win.title,"accent")
        AlphaSquadUI.Theme.RegisterSurface(win,win.bg,"window")
    end

    win.dragHint = Label(win, "AlphaSquadULTGroupDragHint", "ZoFontGameSmall", "DRAG", COLORS.gold)
    win.dragHint:SetDimensions(42, HEADER_H)
    win.dragHint:SetAnchor(TOPRIGHT, win, TOPRIGHT, -5, 0)
    win.dragHint:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    win.empty = Label(win, "AlphaSquadULTGroupEmpty", "ZoFontGameSmall", "", COLORS.muted)
    win.empty:SetDimensions(math.max(100, self:GetListWidth() - 20), 32)
    win.empty:SetAnchor(TOPLEFT, win, TOPLEFT, 10, HEADER_H + 6)
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
    if AlphaSquadUI.Layout and AlphaSquadUI.Layout.Attach then AlphaSquadUI.Layout.Attach(self) end
end

-- A theme change repaints cached rows only; no roster rebuild or network request.
if AlphaSquadUI.Theme and AlphaSquadUI.Theme.OnChanged then
    AlphaSquadUI.Theme.OnChanged(function()
        Group:RefreshHUD()
        if Group.RefreshConfig then Group:RefreshConfig() end
    end)
end
