-- Shared settings shell: available independently of gameplay modules.
local ASUI=AlphaSquadUI
local Shell={settingsRefreshers={},settingsPages={},settingsNavButtons={},activeSettingsPage="dashboard"}
ASUI.Shell=Shell
local COLORS=ASUI.Theme.colors
local SETTINGS_MENU_NAME=ASUI.Theme.Brand()
local VERSION=ASUI.version
local WINDOW_WIDTH,WINDOW_HEIGHT=1350,720
local SIDEBAR_WIDTH=236
local NAV_WIDTH=SIDEBAR_WIDTH-24
local CONTENT_X=SIDEBAR_WIDTH+10
local CONTENT_WIDTH=WINDOW_WIDTH-CONTENT_X-10
local Clamp=ASUI.Utils.Clamp
local LogicalWidth=ASUI.Utils.GetLogicalWidth
local LogicalHeight=ASUI.Utils.GetLogicalHeight
local function SetColor(control,color) control:SetColor(color[1],color[2],color[3],color[4] or 1) end
function Shell:ApplyVisualSettings() ASUI.Settings.RefreshModuleVisibility() end
function Shell:OpenWebsite() return ASUI.Settings.OpenLink(ASUI.website) end
local function CreateSolid(parent, name, color, left, top, right, bottom)
    local texture = WINDOW_MANAGER:CreateControl(name, parent, CT_TEXTURE)
    texture:SetColor(color[1], color[2], color[3], color[4])
    if ASUI.Theme.BindColor then ASUI.Theme.BindColor(texture,color) end
    if left and top and right and bottom then
        texture:SetAnchor(TOPLEFT, parent, TOPLEFT, left, top)
        texture:SetAnchor(BOTTOMRIGHT, parent, BOTTOMRIGHT, right, bottom)
    else
        texture:SetAnchorFill(parent)
    end
    return texture
end

local function CreateLabel(parent, name, font, text, color)
    local label = WINDOW_MANAGER:CreateControl(name, parent, CT_LABEL)
    label:SetFont(font)
    label:SetText(text or "")
    label:SetColor(color[1], color[2], color[3], color[4])
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    if ASUI.Theme.BindColor then ASUI.Theme.BindColor(label,color) end
    return label
end

local function CreateButton(parent, name, text, x, y, width, height, onClick)
    local button = WINDOW_MANAGER:CreateControl(name, parent, CT_CONTROL)
    button:SetDimensions(width, height)
    button:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)
    button:SetMouseEnabled(true)

    local bg = CreateSolid(button, name .. "BG", COLORS.panel)
    button.bg = bg
    if ASUI.Theme.RegisterSurface then ASUI.Theme.RegisterSurface(button,bg,"button") end

    local label = CreateLabel(button, name .. "Label", "ZoFontGame", text, COLORS.white)
    label:SetAnchorFill(button)
    label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    label:SetMaxLineCount(1)
    if label.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end
    button.label = label
    button.enabled = true

    button:SetHandler("OnMouseEnter", function()
        if button.enabled then SetColor(bg,COLORS.hover or COLORS.panelActive) end
        local tooltips = AlphaSquadUI.Tooltips
        if button.help and tooltips then tooltips.ShowText(button, button.help) end
    end)
    button:SetHandler("OnMouseExit", function()
        local color = button.restingColor or COLORS.panel
        bg:SetColor(color[1], color[2], color[3], color[4] or 1)
        if AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.Hide() end
    end)
    button:SetHandler("OnMouseUp", function(_, mouseButton, upInside)
        if button.enabled and mouseButton == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false and onClick then
            onClick()
        end
    end)

    if ASUI.Input then ASUI.Input.Register(button, {activate = onClick, label = text}) end

    return button
end

function Shell:RefreshSettingsWindow()
    if not self.settingsWindow or self.settingsWindow:IsHidden() then return end
    self:ApplySettingsGeometry()
    self:RefreshNavigation()
    for _, refresher in ipairs(self.settingsRefreshers) do
        refresher()
    end
end

function Shell:ApplySettingsGeometry()
    if not self.settingsWindow or not GuiRoot then return end
    local scale=math.max(0.001,math.min(1,(GuiRoot:GetWidth()-40)/WINDOW_WIDTH,(GuiRoot:GetHeight()-40)/WINDOW_HEIGHT))
    local height=WINDOW_HEIGHT
    if self.settingsAppliedScale==scale then return end
    self.settingsAppliedScale=scale
    self.settingsWindow:SetDimensions(WINDOW_WIDTH, height)
    self.settingsWindow:SetScale(scale)
    if self.settingsSidebar then self.settingsSidebar:SetHeight(height - 64) end
    if self.settingsSaveNote then self.settingsSaveNote:SetHidden(height < 490) end
    if self.settingsScroll then
        self.settingsScroll:SetHeight(height - 80)
        self.settingsScroll.scrollbar:SetHeight(height - 80)
        self.settingsScroll.UpdateBounds()
    end
end

function Shell:CloseSettingsWindow()
    if not self.settingsWindow then return end
    if self.settingsOpenedFromGameMenu and self.settingsFragment then
        SCENE_MANAGER:RemoveFragment(self.settingsFragment)
        self.settingsOpenedFromGameMenu = false
    end
    self.settingsWindow:SetHidden(true)
    if AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.Hide() end
    local settings = AlphaSquadUI.Settings
    if settings and settings.RefreshModuleVisibility then settings.RefreshModuleVisibility()
    else self:ApplyVisualSettings() end
end

function Shell:ShowSettingsPage(pageId)
    if not self.settingsPages then return end
    if not self.settingsPages[pageId] or (AlphaSquadUI.Settings.modulePages[pageId] and not AlphaSquadUI.Settings.IsModuleEnabled(pageId)) then pageId = "dashboard" end
    if self.activeSettingsPage ~= pageId and self.settingsScroll then
        self.settingsScroll.offset = 0
        self.settingsScroll:SetVerticalScroll(0)
        self.settingsScroll.scrollbar:SetValue(0)
    end
    self.activeSettingsPage = pageId

    for id, page in pairs(self.settingsPages) do
        page:SetHidden(id ~= pageId)
    end
    if self.settingsContent then
        local page = self.settingsPages[pageId]
        local height = math.max(self.settingsScroll and LogicalHeight(self.settingsScroll) or 590, tonumber(page.contentHeight) or 640)
        self.settingsContent:SetHeight(height)
        page:SetHeight(height)
    end

    for id, button in pairs(self.settingsNavButtons or {}) do
        local selected = id == pageId or (id=="ulttracker" and pageId=="ultoverload")
        if button.bg then
            if selected then
                SetColor(button.bg,COLORS.selected or COLORS.panelActive)
            else
                SetColor(button.bg,COLORS.panel)
            end
        end
        if button.accent then button.accent:SetHidden(not selected) end
        if button.label then
            local color = selected and COLORS.orange or COLORS.white
            button.label:SetColor(color[1], color[2], color[3], 1)
        end
    end
end

function Shell:RefreshNavigation()
    if not self.settingsNavButtons then return end
    local y=50
    for _,id in ipairs({"dashboard","ulttracker","supportcoverage","libraries","community"}) do
        local button=self.settingsNavButtons[id]
        local visible=not AlphaSquadUI.Settings.modulePages[id] or AlphaSquadUI.Settings.IsModuleEnabled(id)
        if button then
            button:SetHidden(not visible)
            if visible then button:ClearAnchors();button:SetAnchor(TOPLEFT,self.settingsSidebar,TOPLEFT,12,y);y=y+44 end
        end
    end
    if self.activeSettingsPage and AlphaSquadUI.Settings.modulePages[self.activeSettingsPage] and not AlphaSquadUI.Settings.IsModuleEnabled(self.activeSettingsPage) then self:ShowSettingsPage("dashboard") end
    if self.settingsSaveNote then self.settingsSaveNote:ClearAnchors();self.settingsSaveNote:SetAnchor(TOPLEFT,self.settingsSidebar,TOPLEFT,18,y+12) end
end

function Shell:CreateSettingsWindow()
    -- One lightweight Ąlpha Şquad shell with internal module pages. Future modules
    -- only need a new sidebar entry + page; no extra ESO Settings panel is required.
    self.settingsRefreshers = {}
    self.settingsPages = {}
    self.settingsNavButtons = {}

    local win = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadSettingsWindow")
    self.settingsWindow = win
    ASUI.Settings.AttachShell(win,
        function(pageId) Shell:ShowSettingsPage(pageId) end,
        function() Shell:RefreshSettingsWindow() end)
    win:SetDimensions(WINDOW_WIDTH, WINDOW_HEIGHT)
    win:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    if AlphaSquadUI.Preferences then
        local layout=AlphaSquadUI.Preferences.Open("Shell","AlphaSquadUISettingsSavedVariables",(GetWorldName and GetWorldName() or "Default")..":Layout",{})
        AlphaSquadUI.Settings.layout=layout
        if type(layout.x)=="number" and layout.x==layout.x and math.abs(layout.x)<100000 and type(layout.y)=="number" and layout.y==layout.y and math.abs(layout.y)<100000 then
            win:ClearAnchors();win:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,layout.x,layout.y)
        end
    end
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:SetMouseEnabled(true)
    win:SetDrawTier(DT_HIGH)
    win:SetDrawLayer(DL_OVERLAY)
    win:SetDrawLevel(100)
    if AlphaSquadUI.Settings and AlphaSquadUI.Settings.ApplyWindowLayer then AlphaSquadUI.Settings.ApplyWindowLayer(win, false) end
    win:SetHidden(true)
    if AlphaSquadUI.Settings.RegisterExclusiveWindow then
        AlphaSquadUI.Settings.RegisterExclusiveWindow("settings", win, function() Shell:CloseSettingsWindow() end)
    end
    if EVENT_SCREEN_RESIZED then
        EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_SettingsResize", EVENT_SCREEN_RESIZED, function()
            Shell:ApplySettingsGeometry()
        end)
    end
    if EVENT_ALL_GUI_SCREENS_RESIZED then
        EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_SettingsUIScale", EVENT_ALL_GUI_SCREENS_RESIZED, function()
            Shell.settingsAppliedScale=nil
            Shell:ApplySettingsGeometry()
        end)
    end

    win.bg=CreateSolid(win,"AlphaSquadSettingsBG",COLORS.bg)
    if ASUI.Theme.RegisterSurface then ASUI.Theme.RegisterSurface(win,win.bg,"window") end

    local header = WINDOW_MANAGER:CreateControl("AlphaSquadSettingsHeader", win, CT_CONTROL)
    header:SetDimensions(WINDOW_WIDTH, 64)
    header:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    header:SetMouseEnabled(true)
    header:SetHandler("OnMouseDown", function(_, button)
        if button == MOUSE_BUTTON_INDEX_LEFT or button == MOUSE_BUTTON_INDEX_RIGHT then win:StartMoving() end
    end)
    header:SetHandler("OnMouseUp", function(_, button)
        if button == MOUSE_BUTTON_INDEX_LEFT or button == MOUSE_BUTTON_INDEX_RIGHT then
            win:StopMovingOrResizing()
            local layout=AlphaSquadUI.Settings.layout
            if layout then layout.x=win:GetLeft();layout.y=win:GetTop() end
        end
    end)

    local title = CreateLabel(win, "AlphaSquadSettingsTitle", "ZoFontWinH2", SETTINGS_MENU_NAME, COLORS.white)
    title:SetDimensions(420, 30)
    title:SetAnchor(TOPLEFT, win, TOPLEFT, 20, 10)
    title:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local subtitle = CreateLabel(win, "AlphaSquadSettingsSubtitle", "ZoFontGameSmall", "Group preparation & Ultimate tracking  •  " .. (AlphaSquadUI.Theme and AlphaSquadUI.Theme.authorText or "@SeRuM1"), COLORS.muted)
    subtitle:SetDimensions(520, 20)
    subtitle:SetAnchor(TOPLEFT, win, TOPLEFT, 21, 38)
    subtitle:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    win.inputHint = CreateLabel(win, "AlphaSquadSettingsInputHint", "ZoFontGameSmall", "", COLORS.muted)
    win.inputHint:SetDimensions(754, 22)
    win.inputHint:SetAnchor(TOPRIGHT, win, TOPRIGHT, -20, 37)
    win.inputHint:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    win.inputHint:SetMaxLineCount(1)
    if win.inputHint.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then win.inputHint:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end

    local separator = WINDOW_MANAGER:CreateControl("AlphaSquadSettingsSeparator", win, CT_TEXTURE)
    separator:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 63)
    separator:SetAnchor(TOPRIGHT, win, TOPRIGHT, 0, 63)
    separator:SetHeight(1)
    separator:SetColor(COLORS.orange[1], COLORS.orange[2], COLORS.orange[3], 0.45)

    -- Sidebar: intentionally simple and static. It has no OnUpdate handler.
    local sidebar = WINDOW_MANAGER:CreateControl("AlphaSquadSettingsSidebar", win, CT_CONTROL)
    self.settingsSidebar = sidebar
    sidebar:SetDimensions(SIDEBAR_WIDTH, WINDOW_HEIGHT-64)
    sidebar:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 64)
    CreateSolid(sidebar,"AlphaSquadSettingsSidebarBG",COLORS.sidebar or COLORS.bg)
    local sideLine = WINDOW_MANAGER:CreateControl("AlphaSquadSettingsSidebarLine", sidebar, CT_TEXTURE)
    sideLine:SetAnchor(TOPRIGHT, sidebar, TOPRIGHT, 0, 0)
    sideLine:SetWidth(1)
    sideLine:SetAnchor(BOTTOMRIGHT, sidebar, BOTTOMRIGHT, 0, 0)
    sideLine:SetColor(COLORS.orange[1], COLORS.orange[2], COLORS.orange[3], 0.18)

    local modulesHeader = CreateLabel(sidebar, "AlphaSquadModulesHeader", "ZoFontGameBold", "WORKSPACE", COLORS.orange)
    modulesHeader:SetDimensions(SIDEBAR_WIDTH-36, 24)
    modulesHeader:SetAnchor(TOPLEFT, sidebar, TOPLEFT, 18, 18)
    modulesHeader:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local function AddNavButton(id, text, y)
        local button = WINDOW_MANAGER:CreateControl("AlphaSquadNav_" .. id, sidebar, CT_CONTROL)
        button:SetDimensions(NAV_WIDTH, 40)
        button:SetAnchor(TOPLEFT, sidebar, TOPLEFT, 12, y)
        button:SetMouseEnabled(true)
        button.bg = CreateSolid(button, "AlphaSquadNav_" .. id .. "BG", COLORS.panel)
        button.accent = WINDOW_MANAGER:CreateControl("AlphaSquadNav_" .. id .. "Accent", button, CT_TEXTURE)
        button.accent:SetAnchor(TOPLEFT, button, TOPLEFT, 0, 0)
        button.accent:SetDimensions(3, 40)
        SetColor(button.accent, COLORS.orange)
        button.label = CreateLabel(button, "AlphaSquadNav_" .. id .. "Label", "ZoFontGameBold", text, COLORS.white)
        local nativeIcon=ASUI.Settings.icons and ASUI.Settings.icons[id]
        if nativeIcon then
            button.icon=WINDOW_MANAGER:CreateControl("AlphaSquadNav_"..id.."Icon",button,CT_TEXTURE)
            button.icon:SetDimensions(23,23);button.icon:SetAnchor(LEFT,button,LEFT,8,0);button.icon:SetTexture(nativeIcon)
        end
        button.label:SetAnchor(TOPLEFT, button, TOPLEFT, nativeIcon and 37 or 14, 0)
        button.label:SetDimensions(NAV_WIDTH-(nativeIcon and 47 or 24), 40)
        button.label:SetMaxLineCount(1)
        button.label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        button:SetHandler("OnMouseEnter", function()
            if Shell.activeSettingsPage ~= id and not (id=="ulttracker" and Shell.activeSettingsPage=="ultoverload") then SetColor(button.bg,COLORS.hover or COLORS.panelActive) end
        end)
        button:SetHandler("OnMouseExit", function()
            if Shell.activeSettingsPage ~= id and not (id=="ulttracker" and Shell.activeSettingsPage=="ultoverload") then SetColor(button.bg,COLORS.panel) end
        end)
        button:SetHandler("OnMouseUp", function(_, mouseButton, upInside)
            if mouseButton == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false then Shell:ShowSettingsPage(id) end
        end)
        self.settingsNavButtons[id] = button
        if ASUI.Input then ASUI.Input.Register(button, {activate = function() Shell:ShowSettingsPage(id) end, label = text}) end
        return button
    end

    AddNavButton("dashboard", "Dashboard", 50)
    AddNavButton("ulttracker", "ULT Tracker", 94)
    AddNavButton("supportcoverage", "Support Coverage", 138)
    AddNavButton("libraries", "Libraries", 182)

    AddNavButton("community", "About", 226)

    local future = CreateLabel(sidebar, "AlphaSquadFutureModules", "ZoFontGameSmall",
        "Changes are saved\nautomatically.", COLORS.muted)
    future:SetDimensions(SIDEBAR_WIDTH-36, 48)
    future:SetAnchor(TOPLEFT, sidebar, TOPLEFT, 18, 328)
    future:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    future:SetVerticalAlignment(TEXT_ALIGN_TOP)
    self.settingsSaveNote = future

    self.settingsMoveButton = CreateButton(sidebar, "AlphaSquadMoveHUD", "MOVE HUD", 12, 0, NAV_WIDTH, 38, function()
        if AlphaSquadUI.Layout then AlphaSquadUI.Layout.Start() end
    end)
    self.settingsMoveButton:ClearAnchors()
    self.settingsMoveButton:SetAnchor(BOTTOMLEFT, sidebar, BOTTOMLEFT, 12, -56)
    self.settingsMoveButton.help = "Outside combat, place enabled HUDs against the game interface. Enable at least one module in Dashboard first. Drag a panel to move it, its corners to scale it, or its sides to reshape it. Choose Done or press Escape to save and lock your layout."

    local versionLabel = CreateLabel(sidebar, "AlphaSquadSidebarVersion", "ZoFontGameSmall", "v" .. VERSION, COLORS.muted)
    versionLabel:SetDimensions(150, 20)
    versionLabel:SetAnchor(BOTTOMLEFT, sidebar, BOTTOMLEFT, 18, -15)
    versionLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local content
    if AlphaSquadUI.Settings.CreateScrollArea then
        content, self.settingsScroll = AlphaSquadUI.Settings.CreateScrollArea(win, "AlphaSquadSettingsContent", CONTENT_X, 70, CONTENT_WIDTH, 640, 640)
    else
        content = WINDOW_MANAGER:CreateControl("AlphaSquadSettingsContent", win, CT_CONTROL)
        content:SetDimensions(CONTENT_WIDTH, 640)
        content:SetAnchor(TOPLEFT, win, TOPLEFT, CONTENT_X, 70)
    end
    self.settingsContent = content

    local function CreatePage(id)
        local page = WINDOW_MANAGER:CreateControl("AlphaSquadPage_" .. id, content, CT_CONTROL)
        page:SetAnchor(TOPLEFT, content, TOPLEFT, 0, 0)
        page:SetDimensions(CONTENT_WIDTH-16, 640)
        page:SetHidden(true)
        self.settingsPages[id] = page
        return page
    end

    local function CreateCard(parent, name, x, y, w, h, titleText, titleColor)
        if not parent.responsiveCards then
            local factor=(LogicalWidth(parent)-16)/658
            x=8+(x-8)*factor;w=w*factor
        end
        local card = WINDOW_MANAGER:CreateControl(name, parent, CT_CONTROL)
        card:SetDimensions(w, h)
        card:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)
        card.bg = CreateSolid(card, name .. "BG", COLORS.panel)
        if ASUI.Theme.RegisterSurface then ASUI.Theme.RegisterSurface(card,card.bg,"card") end
        local label = CreateLabel(card, name .. "Title", "ZoFontGameBold", titleText, titleColor or COLORS.orange)
        label:SetDimensions(w - 28, 24)
        label:SetAnchor(TOPLEFT, card, TOPLEFT, 14, 8)
        label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        card.title=label
        return card
    end

    local function AddToggleRow(parent, name, labelText, y, getter, setter, help)
        local label = CreateLabel(parent, name .. "Label", "ZoFontGame", labelText, COLORS.white)
        label:SetDimensions(LogicalWidth(parent) - 116, 30)
        label:SetAnchor(TOPLEFT, parent, TOPLEFT, 14, y)
        label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        label:SetMaxLineCount(1)
        if label.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end
        local function Toggle()
            setter(not getter())
            Shell:ApplyVisualSettings()
            Shell:RefreshSettingsWindow()
        end
        local button = CreateButton(parent, name .. "Button", "", LogicalWidth(parent) - 96, y, 80, 30, Toggle)
        button.track=CreateSolid(button,name.."Track",COLORS.bg)
        button.track:SetDimensions(28,14);button.track:ClearAnchors()
        button.track:SetAnchor(RIGHT,button,RIGHT,-7,0)
        button.thumb=CreateSolid(button,name.."Thumb",COLORS.muted)
        button.thumb:SetDimensions(10,10);button.thumb:ClearAnchors()
        button.label:ClearAnchors();button.label:SetAnchor(TOPLEFT,button,TOPLEFT,3,0)
        button.label:SetDimensions(40,30)
        button.help = help or (labelText .. "\n\nClick the label or switch to change this setting. Changes are saved automatically.")
        if ASUI.Input then ASUI.Input.Register(button, {activate = Toggle, label = labelText}) end
        label:SetMouseEnabled(true)
        label:SetHandler("OnMouseEnter", function()
            if AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.ShowText(label, button.help) end
        end)
        label:SetHandler("OnMouseExit", function()
            if AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.Hide() end
        end)
        label:SetHandler("OnMouseUp", function(_, mouseButton, upInside)
            if mouseButton == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false then Toggle() end
        end)
        table.insert(self.settingsRefreshers, function()
            local enabled = getter()
            button.label:SetText(enabled and "ON" or "OFF")
            local c = enabled and COLORS.green or COLORS.muted
            button.label:SetColor(c[1], c[2], c[3], 1)
            button.thumb:SetHidden(false);button.thumb:ClearAnchors()
            button.thumb:SetAnchor(LEFT,button.track,LEFT,enabled and 16 or 2,0);SetColor(button.thumb,c)
            button.restingColor = enabled and (COLORS.selected or COLORS.panelActive) or COLORS.panel
            local bg = button.restingColor
            button.bg:SetColor(bg[1], bg[2], bg[3], bg[4])
        end)
        return button, label
    end

    local function AddStepperRow(parent, name, labelText, y, getter, setter, step, minimum, maximum, suffix, color, description)
        local label = CreateLabel(parent, name .. "Label", "ZoFontGame", labelText, COLORS.white)
        label:SetDimensions(LogicalWidth(parent) - 170, 30)
        label:SetAnchor(TOPLEFT, parent, TOPLEFT, 14, y)
        label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        label:SetMaxLineCount(1)
        if label.SetWrapMode and TEXT_WRAP_MODE_ELLIPSIS then label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS) end
        local minus = CreateButton(parent, name .. "Minus", "−", LogicalWidth(parent) - 154, y, 38, 30, function()
            setter(Clamp(getter() - step, minimum, maximum))
            Shell:RefreshSettingsWindow()
        end)
        local value = CreateLabel(parent, name .. "Value", "ZoFontGameBold", "", color or COLORS.cyan)
        value:SetDimensions(56, 30)
        value:SetAnchor(TOPLEFT, parent, TOPLEFT, LogicalWidth(parent) - 112, y)
        value:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
        local plus = CreateButton(parent, name .. "Plus", "+", LogicalWidth(parent) - 52, y, 38, 30, function()
            setter(Clamp(getter() + step, minimum, maximum))
            Shell:RefreshSettingsWindow()
        end)
        local help = string.format("%s%s\n\nAdjust from %s%s to %s%s. Changes are saved automatically.",
            labelText, description and ("\n\n" .. description) or "", minimum, suffix or "", maximum, suffix or "")
        minus.help, plus.help = help, help
        if ASUI.Input then
            ASUI.Input.Register(minus, {label = "Decrease " .. labelText})
            ASUI.Input.Register(plus, {label = "Increase " .. labelText})
        end
        label:SetMouseEnabled(true)
        label:SetHandler("OnMouseEnter", function()
            if AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.ShowText(label, help) end
        end)
        label:SetHandler("OnMouseExit", function()
            if AlphaSquadUI.Tooltips then AlphaSquadUI.Tooltips.Hide() end
        end)
        table.insert(self.settingsRefreshers, function()
            local current = getter()
            value:SetText(tostring(current) .. (suffix or ""))
            minus.enabled, plus.enabled = current > minimum, current < maximum
            minus:SetAlpha(minus.enabled and 1 or 0.4)
            plus:SetAlpha(plus.enabled and 1 or 0.4)
        end)
        return minus, plus, value
    end

    local pageUI = {
        CreateLabel=CreateLabel, CreateCard=CreateCard, AddToggleRow=AddToggleRow,
        AddStepperRow=AddStepperRow, CreateButton=CreateButton, colors=COLORS,
        RegisterRefresher=function(fn) table.insert(self.settingsRefreshers,fn) end,
    }
    self.pageUI=pageUI
    for _,id in ipairs({"dashboard","ulttracker","ultoverload","supportcoverage","libraries","community"}) do
        local page=CreatePage(id)
        local builder=AlphaSquadUI.Settings.GetPageBuilder(id)
        if builder then builder(page,pageUI) end
    end

    self:ShowSettingsPage(self.activeSettingsPage or "dashboard")
    self:RefreshSettingsWindow()
end

function Shell:RegisterDirectSettingsPanel()
    if not ZO_GameMenu_AddSettingPanel or not KEYBOARD_OPTIONS or not self.settingsWindow then return end

    local panelId = KEYBOARD_OPTIONS.currentPanelId
    KEYBOARD_OPTIONS.currentPanelId = panelId + 1
    KEYBOARD_OPTIONS.panelNames[panelId] = "Ąlpha Şquad UI"
    self.directSettingsPanelId = panelId
    self.settingsFragment = ZO_FadeSceneFragment:New(self.settingsWindow)

    local panelData = {
        id = panelId,
        name = SETTINGS_MENU_NAME,
        visible = true,
    }

    panelData.callback = function(_, anchorFunction)
        local settings = AlphaSquadUI.Settings
        if settings and settings.ShowExclusiveWindow then settings.ShowExclusiveWindow("settings") end
        Shell.settingsOpenedFromGameMenu = true
        Shell.settingsWindow:SetMovable(false)
        Shell:ApplySettingsGeometry()
        Shell.settingsWindow:ClearAnchors()
        if anchorFunction then
            anchorFunction(Shell.settingsWindow)
        elseif ZO_ReanchorControlForLeftSidePanel then
            ZO_ReanchorControlForLeftSidePanel(Shell.settingsWindow)
        else
            Shell.settingsWindow:SetAnchor(CENTER, GuiRoot, CENTER, 170, 0)
        end
        SCENE_MANAGER:AddFragment(Shell.settingsFragment)
        KEYBOARD_OPTIONS:ChangePanels(panelId)
        Shell:RefreshSettingsWindow()
        zo_callLater(function()
            Shell:ApplyVisualSettings()
        end, 0)
    end

    panelData.unselectedCallback = function()
        if Shell.settingsFragment then
            SCENE_MANAGER:RemoveFragment(Shell.settingsFragment)
        end
        Shell.settingsOpenedFromGameMenu = false
        Shell.settingsWindow:SetMovable(true)
        -- A Back action may have restored a raw window after its native fragment
        -- was removed. Leaving this native Settings category must dismiss that
        -- window too, instead of leaving it over the newly selected category.
        if ASUI.Settings.DismissAllWindows then ASUI.Settings.DismissAllWindows() end
        zo_callLater(function()
            Shell:ApplyVisualSettings()
        end, 0)
        if SetCameraOptionsPreviewModeEnabled then
            SetCameraOptionsPreviewModeEnabled(false, CAMERA_OPTIONS_PREVIEW_NONE)
        end
    end

    self.directSettingsPanelData = panelData
    ZO_GameMenu_AddSettingPanel(panelData)
    -- Only move our panel before entries explicitly identified as addon panels.
    -- Native entries have no addon panel ID; their order and data stay untouched.
    local entries = ZO_GameMenuManager_GetSubcategoriesEntries and ZO_GameMenuManager_GetSubcategoriesEntries()
    if type(entries) == "table" and type(SETTING_PANEL_MAX_VALUE) == "number" then
        local ownIndex, firstAddonIndex
        for index, entry in ipairs(entries) do
            if entry == panelData then ownIndex = index
            elseif type(entry) == "table" and entry.categoryName == panelData.categoryName
                and type(entry.id) == "number" and entry.id > SETTING_PANEL_MAX_VALUE then
                firstAddonIndex = firstAddonIndex or index
            end
        end
        if ownIndex and firstAddonIndex and firstAddonIndex < ownIndex then
            table.remove(entries, ownIndex)
            table.insert(entries, firstAddonIndex, panelData)
        end
    end
end

function Shell:ToggleSettingsWindow()
    if not self.settingsWindow then return end
    if not self.settingsWindow:IsHidden() then
        if ASUI.Settings.CloseExclusiveWindow then ASUI.Settings.CloseExclusiveWindow("settings")
        else self:CloseSettingsWindow() end
        return
    end
    if self.settingsOpenedFromGameMenu and self.settingsFragment then
        SCENE_MANAGER:RemoveFragment(self.settingsFragment)
        self.settingsOpenedFromGameMenu = false
    end
    local hidden = self.settingsWindow:IsHidden()
    if hidden then
        self.settingsWindow:SetMovable(true)
        self.settingsWindow:ClearAnchors()
        local layout=ASUI.Settings.layout
        if layout and type(layout.x)=="number" and layout.x==layout.x and math.abs(layout.x)<100000
            and type(layout.y)=="number" and layout.y==layout.y and math.abs(layout.y)<100000 then
            self.settingsWindow:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,layout.x,layout.y)
        else self.settingsWindow:SetAnchor(CENTER,GuiRoot,CENTER,0,0) end
    end
    if hidden and AlphaSquadUI.Settings.ShowExclusiveWindow then AlphaSquadUI.Settings.ShowExclusiveWindow("settings")
    else self.settingsWindow:SetHidden(not hidden) end
    if hidden then self:RefreshSettingsWindow() end
    self:ApplyVisualSettings()
end


function Shell:Initialize()
    if self.initialized then return end
    self.initialized=true
    if ASUI.Theme.Initialize then ASUI.Theme.Initialize() end
    if ASUI.Input then ASUI.Input.Initialize() end
    self:CreateSettingsWindow()
    self:RegisterDirectSettingsPanel()
    if ASUI.Theme.OnChanged then
        ASUI.Theme.OnChanged(function()
            Shell:ShowSettingsPage(Shell.activeSettingsPage or "dashboard")
            Shell:RefreshSettingsWindow()
        end)
    end
    SLASH_COMMANDS["/asui"]=function() Shell:ToggleSettingsWindow() end
    SLASH_COMMANDS["/alphasquad"]=SLASH_COMMANDS["/asui"]
end
EVENT_MANAGER:RegisterForEvent("AlphaSquadUI_Shell",EVENT_ADD_ON_LOADED,function(_,name)
    if name~=ASUI.name then return end
    EVENT_MANAGER:UnregisterForEvent("AlphaSquadUI_Shell",EVENT_ADD_ON_LOADED)
    -- Let every module finish loading its profile before constructing its page.
    zo_callLater(function() Shell:Initialize() end,0)
end)
