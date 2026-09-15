-- Ąlpha Şquad UI - Shared settings registry and shell bridge
AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Settings = AlphaSquadUI.Settings or {}

local Settings = AlphaSquadUI.Settings
local LogicalWidth = AlphaSquadUI.Utils.GetLogicalWidth
local LogicalHeight = AlphaSquadUI.Utils.GetLogicalHeight
Settings.pages = Settings.pages or {}
Settings.mainWindow = Settings.mainWindow or nil
Settings.showPageCallback = Settings.showPageCallback or nil
Settings.refreshCallback = Settings.refreshCallback or nil
Settings.exclusiveWindows = Settings.exclusiveWindows or {}
Settings.windowHistory = Settings.windowHistory or {}

local function MainPage()
    local shell = AlphaSquadUI.Shell
    return shell and shell.activeSettingsPage or Settings.currentPage or "dashboard"
end

local function VisibleWindow()
    for id, entry in pairs(Settings.exclusiveWindows) do
        if not entry.control:IsHidden() then return id, entry end
    end
end

local function CopyHistory(history)
    local copy = {}
    for _, item in ipairs(history or {}) do
        if #copy == 8 then break end
        if type(item) == "table" and Settings.exclusiveWindows[item.id] then
            copy[#copy + 1] = {id = item.id, page = item.page}
        end
    end
    return copy
end

local function NavigationBlocked()
    if IsUnitInCombat and IsUnitInCombat("player") then return true end
    if AlphaSquadUI.Input and AlphaSquadUI.Input.loading then return true end
    for _, module in pairs(AlphaSquadUI.Modules or {}) do
        if type(module) == "table" and module.loading then return true end
    end
    return false
end

local function RestoreCursor()
    -- Closing the placement toolbar can release ESO's last native top-level.
    -- Restore mouse access only in gameplay; native options keep their scene.
    local manager = SCENE_MANAGER
    local scene = manager and manager.GetCurrentScene and manager:GetCurrentScene()
    local name = scene and scene.GetName and scene:GetName()
    if (name == "hud" or name == "hudui") and manager.SetInUIMode then
        if manager.IsInUIMode and not manager:IsInUIMode() then Settings.ownsCursor = true end
        manager:SetInUIMode(true)
    end
end

local function ReleaseCursor()
    local owned = Settings.ownsCursor
    Settings.ownsCursor = nil
    if not owned or VisibleWindow() then return end
    local manager = SCENE_MANAGER
    local scene = manager and manager.GetCurrentScene and manager:GetCurrentScene()
    local name = scene and scene.GetName and scene:GetName()
    if (name == "hud" or name == "hudui") and manager.SetInUIMode then manager:SetInUIMode(false) end
end

function Settings.RefreshModuleVisibility()
    for _, module in pairs(AlphaSquadUI.Modules or {}) do
        if type(module) == "table" then
            if type(module.ApplyVisibility) == "function" then module:ApplyVisibility()
            elseif type(module.ApplyVisualSettings) == "function" then module:ApplyVisualSettings() end
        end
    end
end

function Settings.RegisterExclusiveWindow(id, control, closeCallback, options)
    if not id or not control then return end
    options = options or {}
    Settings.exclusiveWindows[id] = { control = control, close = closeCallback,
        restore = options.restore, fallbackPage = options.fallbackPage }
    if AlphaSquadUI.Input then
        AlphaSquadUI.Input.RegisterWindow(control, {
            close = function() Settings.CloseExclusiveWindow(id) end,
            dismiss = function()
                if closeCallback then closeCallback() else control:SetHidden(true) end
                -- Native scenes own their own mouse mode after a dismissal.
                if not VisibleWindow() then Settings.ownsCursor = nil end
            end,
        })
    end
end

function Settings.AnyExclusiveWindowVisible()
    for _, entry in pairs(Settings.exclusiveWindows) do
        if not entry.control:IsHidden() then return true end
    end
    return false
end

function Settings.ShowExclusiveWindow(id)
    local target = Settings.exclusiveWindows[id]
    if not target then return false end
    local visible = VisibleWindow()
    if id == "settings" then
        Settings.windowHistory = {}
    elseif visible ~= id then
        local history = Settings.windowHistory
        if not visible then
            history = {{id = "settings", page = target.fallbackPage or MainPage()}}
        else
            local previous
            for index, item in ipairs(history) do if item.id == id then previous = index; break end end
            if previous then
                for index = #history, previous, -1 do history[index] = nil end
            else
                history[#history + 1] = {id = visible, page = visible == "settings" and MainPage() or nil}
                -- Window history is transient and bounded even if extensions register more panels.
                if #history > 8 then table.remove(history, 2) end
            end
        end
        Settings.windowHistory = history
    end
    if AlphaSquadUI.Layout then AlphaSquadUI.Layout.Finish() end
    for otherId, entry in pairs(Settings.exclusiveWindows) do
        if otherId ~= id and not entry.control:IsHidden() then
            if type(entry.close) == "function" then entry.close()
            else entry.control:SetHidden(true) end
        end
    end
    target.control:SetHidden(false)
    Settings.RefreshModuleVisibility()
    return true
end

-- Registered close callbacks only tear down a window. Navigation belongs to
-- explicit user actions, never to combat, loading or native scene dismissal.
function Settings.DismissAllWindows()
    Settings.windowHistory = {}
    for _, entry in pairs(Settings.exclusiveWindows) do
        if not entry.control:IsHidden() then
            if type(entry.close) == "function" then entry.close()
            else entry.control:SetHidden(true) end
        end
    end
    Settings.ownsCursor = nil
    Settings.RefreshModuleVisibility()
end

function Settings.CaptureReturnTarget()
    local id = VisibleWindow()
    return {id = id or "settings", page = MainPage(), history = CopyHistory(Settings.windowHistory)}
end

function Settings.RestoreReturnTarget(target)
    if NavigationBlocked() then return false end
    target = type(target) == "table" and target or {}
    local id = Settings.exclusiveWindows[target.id] and target.id or "settings"
    if id == "settings" then
        local opened = Settings.OpenPage(target.page or "dashboard")
        if opened then RestoreCursor() end
        return opened
    end
    if not Settings.ShowExclusiveWindow(id) then return false end
    Settings.windowHistory = CopyHistory(target.history)
    if #Settings.windowHistory == 0 then
        local entry = Settings.exclusiveWindows[id]
        Settings.windowHistory[1] = {id = "settings", page = entry.fallbackPage or target.page or "dashboard"}
    end
    local restore = Settings.exclusiveWindows[id].restore
    if type(restore) == "function" then restore() end
    RestoreCursor()
    return true
end

function Settings.CloseExclusiveWindow(id)
    local entry = Settings.exclusiveWindows[id]
    if not entry or entry.control:IsHidden() then return false end
    if type(entry.close) == "function" then entry.close() else entry.control:SetHidden(true) end
    if id == "settings" or NavigationBlocked() then
        Settings.windowHistory = {}
        if id == "settings" then ReleaseCursor() else Settings.ownsCursor = nil end
        Settings.RefreshModuleVisibility()
        return true
    end
    local previous = table.remove(Settings.windowHistory) or {id = "settings", page = entry.fallbackPage or MainPage()}
    return Settings.RestoreReturnTarget({id = previous.id, page = previous.page,
        history = Settings.windowHistory})
end

function Settings.CloseMain()
    local entry = Settings.exclusiveWindows.settings
    if entry and type(entry.close) == "function" then entry.close()
    elseif Settings.mainWindow then Settings.mainWindow:SetHidden(true) end
    Settings.windowHistory = {}
    ReleaseCursor()
    Settings.RefreshModuleVisibility()
end

-- Clipped mouse-wheel/slider scrolling with no animation or OnUpdate loop.
function Settings.CreateScrollArea(parent, name, x, y, width, height, contentHeight)
    local scroll = WINDOW_MANAGER:CreateControl(name, parent, CT_SCROLL)
    scroll:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)
    scroll:SetDimensions(width - 16, height)
    scroll:SetMouseEnabled(true)
    local child = WINDOW_MANAGER:CreateControl(name .. "Child", scroll, CT_CONTROL)
    child:SetAnchor(TOPLEFT, scroll, TOPLEFT, 0, 0)
    child:SetDimensions(width - 16, contentHeight or height)
    local slider = WINDOW_MANAGER:CreateControl(name .. "Bar", parent, CT_SLIDER)
    slider:SetAnchor(TOPLEFT, parent, TOPLEFT, x + width - 12, y)
    slider:SetDimensions(10, height)
    slider:SetOrientation(ORIENTATION_VERTICAL)
    slider:SetMouseEnabled(true)
    slider:SetValueStep(1)
    local thumb = "/esoui/art/miscellaneous/scrollbox_elevator.dds"
    slider:SetThumbTexture(thumb, thumb, thumb, 10, 40, 0, 0, 1, 1)
    scroll.offset = 0
    local function SetOffset(value)
        scroll.offset = AlphaSquadUI.Utils.Clamp(value, 0, scroll.maximum or 0)
        scroll:SetVerticalScroll(scroll.offset)
    end
    local function UpdateBounds()
        scroll.maximum = math.max(0, LogicalHeight(child) - LogicalHeight(scroll))
        slider:SetMinMax(0, scroll.maximum)
        slider:SetHidden(scroll.maximum == 0)
        SetOffset(scroll.offset)
        slider:SetValue(scroll.offset)
    end
    local function OnWheel(_, delta)
        SetOffset(scroll.offset - delta * 40)
        slider:SetValue(scroll.offset)
    end
    slider:SetHandler("OnValueChanged", function(_, value) SetOffset(value) end)
    slider:SetHandler("OnMouseWheel", OnWheel)
    scroll:SetHandler("OnMouseWheel", OnWheel)
    scroll:SetHandler("OnRectHeightChanged", UpdateBounds)
    child:SetHandler("OnRectHeightChanged", UpdateBounds)
    scroll.UpdateBounds = UpdateBounds
    scroll.scrollbar = slider
    function scroll:EnsureControlVisible(control)
        if not control or not control.GetTop or not self.GetTop then return end
        local scale = self.GetScale and self:GetScale() or 1
        if type(scale) ~= "number" or scale <= 0 then return end
        local top = (control:GetTop() - self:GetTop()) / scale
        local bottom = top + LogicalHeight(control)
        local viewport = LogicalHeight(self)
        if top < 0 then SetOffset(self.offset + top)
        elseif bottom > viewport then SetOffset(self.offset + bottom - viewport) end
        slider:SetValue(self.offset)
    end
    if AlphaSquadUI.Input then AlphaSquadUI.Input.Register(slider, {kind = "slider", step = 40, label = "Scroll content"}) end
    UpdateBounds()
    return child, scroll, slider
end

function Settings.RegisterPage(id, builder)
    if not id or type(builder) ~= "function" then return end
    Settings.pages[id] = builder
end

function Settings.GetPageBuilder(id)
    return id and Settings.pages[id] or nil
end

-- Modules communicate with the independent Core shell through this bridge.
function Settings.AttachShell(mainWindow, showPageCallback, refreshCallback)
    Settings.mainWindow = mainWindow
    Settings.showPageCallback = showPageCallback
    Settings.refreshCallback = refreshCallback
end

function Settings.RefreshMain()
    if Settings.refreshCallback then
        Settings.refreshCallback()
    end
end

function Settings.OpenPage(id)
    if not Settings.mainWindow then return false end
    Settings.currentPage = id or "dashboard"
    if Settings.showPageCallback then
        Settings.showPageCallback(id)
    end
    if Settings.exclusiveWindows.settings then Settings.ShowExclusiveWindow("settings")
    else Settings.mainWindow:SetHidden(false) end
    Settings.RefreshMain()
    return true
end

local ASUI=AlphaSquadUI
-- Native confirmation dialogs use MEDIUM/20. Keep addon windows below them,
-- and leave tooltips on their native high tier. No modal hooks or polling.
function Settings.ApplyWindowLayer(control,isHUD)
    if not control then return end
    control:SetDrawTier(DT_MEDIUM or DT_HIGH)
    control:SetDrawLayer(DL_CONTROLS or DL_OVERLAY)
    local dialogLevel=tonumber(ZO_MEDIUM_TIER_KEYBOARD_STANDARD_DIALOG) or 20
    control:SetDrawLevel(math.max(0,dialogLevel-(isHUD and 15 or 5)))
end
local function OpenLink(url)
    if type(url)~="string" or #url>2048 or url:find("[%z\1-\32\127]") or not url:match("^https://") or not RequestOpenUnsafeURL then return false end
    if ASUI.Layout then ASUI.Layout.Finish() end
    if ASUI.Tooltips then ASUI.Tooltips.Hide() end
    RequestOpenUnsafeURL(url)
    return true
end
Settings.OpenLink=OpenLink
Settings.modulePages={ulttracker="ULTTracker",ultoverload="ULTTracker",supportcoverage="SupportCoverage"}
-- Native menu artwork, as used by ESO's own keyboard main menu.
Settings.icons={dashboard="EsoUI/Art/MainMenu/menuBar_map_up.dds",
    ulttracker="EsoUI/Art/MainMenu/menuBar_skills_up.dds",
    supportcoverage="EsoUI/Art/MainMenu/menuBar_social_up.dds",
    libraries="EsoUI/Art/MainMenu/menuBar_collections_up.dds",
    community="EsoUI/Art/MenuBar/menuBar_help_up.dds"}
function Settings.IsModuleEnabled(id)
    local module=ASUI.Modules[Settings.modulePages[id]]
    if not module or not module.sv then return false end
    return module.sv.enabled==true
end
function Settings.SetModuleEnabled(id,enabled)
    local module=ASUI.Modules[Settings.modulePages[id]]
    if not module or not module.sv then return end
    module:SetEnabled(enabled)
    Settings.RefreshMain()
end
local function Label(ui,parent,name,text,x,y,w,h,color,font)
    local control=ui.CreateLabel(parent,name,font or "ZoFontGameSmall",text,color or ui.colors.muted)
    control:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);control:SetDimensions(w,h)
    control:SetHorizontalAlignment(TEXT_ALIGN_LEFT);control:SetVerticalAlignment(TEXT_ALIGN_TOP)
    return control
end
local function Icon(parent,name,texture,x,y,size)
    local icon=WINDOW_MANAGER:CreateControl(name,parent,CT_TEXTURE)
    icon:SetDimensions(size,size);icon:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);icon:SetTexture(texture)
    return icon
end
local function PresetDropdown(parent,ui,width)
    local theme=ASUI.Theme
    local container=WINDOW_MANAGER:CreateControlFromVirtual("AlphaSquadThemeChoice",parent,"ZO_ComboBox")
    container:SetAnchor(TOPLEFT,parent,TOPLEFT,14,47);container:SetDimensions(width-28,32)
    local combo=ZO_ComboBox_ObjectFromContainer(container)
    combo:SetSortsItems(false)
    if theme.ConfigureDropdown then theme.ConfigureDropdown(combo) end
    local description=Label(ui,parent,"AlphaSquadThemeDescription","",14,88,width-28,50)
    for _,preset in ipairs(theme.GetPresets()) do
        local id=preset.id
        local entry=combo:CreateItemEntry(preset.name,function() theme.SetPreset(id) end)
        entry.id=id;entry.description=preset.description
        combo:AddItem(entry)
    end
    if ASUI.Input then ASUI.Input.Register(container, {kind = "dropdown", combo = combo, label = "Interface style"}) end
    ui.RegisterRefresher(function()
        local id=theme.GetPresetId()
        combo:SetSelectedItemByEval(function(entry)return entry.id==id end,true)
        for _,preset in ipairs(theme.GetPresets()) do if preset.id==id then description:SetText(preset.description) end end
    end)
    return container
end
Settings.RegisterPage("dashboard",function(page,ui)
    page.responsiveCards=true;page.contentHeight=590
    local width=LogicalWidth(page)-16;local half=(width-16)/2
    Label(ui,page,"AlphaSquadDashboardTitle","DASHBOARD",8,2,width,34,ui.colors.orange,"ZoFontWinH2")
    Label(ui,page,"AlphaSquadDashboardIntro","Your tools, your layout. Choose what you need and make it yours.",8,40,width,26)
    local entries={
        {"ulttracker","ULT TRACKER","Personal and group Ultimates, with specialized Sorcerer Overload support."},
        {"supportcoverage","SUPPORT COVERAGE","Prepare group support and inspect the equipped builds behind it."},
    }
    for index,data in ipairs(entries) do
        local id=data[1];local x=8+(index-1)*(half+16)
        local card=ui.CreateCard(page,"AlphaSquadDashboardModule"..index,x,82,half,180,data[2],ui.colors.orange)
        Icon(card,"AlphaSquadDashboardIcon"..index,Settings.icons[id],14,40,52)
        Label(ui,card,"AlphaSquadDashboardHelp"..index,data[3],80,43,half-98,65,ui.colors.muted,"ZoFontGame")
        ui.AddToggleRow(card,"AlphaSquadDashboardToggle"..index,"Enable module",132,function() return Settings.IsModuleEnabled(id) end,
            function(v) Settings.SetModuleEnabled(id,v) end,"Stops this module's HUD, tracking events and timers. Sharing choices in Libraries are kept.")
    end
    local appearance=ui.CreateCard(page,"AlphaSquadDashboardAppearance",8,280,half,172,"INTERFACE STYLE",ui.colors.orange)
    PresetDropdown(appearance,ui,half)
    Label(ui,appearance,"AlphaSquadThemeScope","Applies to every menu and HUD. Gameplay colors stay consistent.",14,136,half-28,24)
    local sync=ui.CreateCard(page,"AlphaSquadDashboardSync",8+half+16,280,half,172,"CROSS-SYNC",ui.colors.cyan)
    Label(ui,sync,"AlphaSquadDashboardSyncHelp","Keep your theme, HUD sizes, positions and preferences across characters on this server.",14,44,half-28,60,ui.colors.muted,"ZoFontGame")
    ui.AddToggleRow(sync,"AlphaSquadCrossSync","Across characters",124,function() return not ASUI.Preferences or not ASUI.Preferences.sv or ASUI.Preferences.sv.crossSync~=false end,
        function(value) if ASUI.Preferences then ASUI.Preferences.SetCrossSync(value) end end,
        "Your current appearance and layout are kept when switching. ON saves future changes across characters; OFF saves them for this character. Sharing remains account-wide. No reload is needed.")
    local help=ui.CreateCard(page,"AlphaSquadDashboardSharing",8,470,width,108,"GROUP DATA",ui.colors.green)
    Icon(help,"AlphaSquadDashboardGroupIcon",Settings.icons.libraries,14,38,48)
    Label(ui,help,"AlphaSquadDashboardSharingHelp","Manage dependencies and sharing in Libraries. Your sharing choices remain independent of tracking modules.",78,40,width-330,56,ui.colors.muted,"ZoFontGame")
    ui.CreateButton(help,"AlphaSquadDashboardLibraries","LIBRARIES",width-206,44,190,36,function() Settings.OpenPage("libraries") end)
end)
Settings.RegisterPage("libraries",function(page,ui)
    page.responsiveCards=true;page.contentHeight=590
    local c=ui.colors;local width=LogicalWidth(page)-16;local half=(width-16)/2
    Label(ui,page,"AlphaSquadLibrariesTitle","LIBRARIES & SHARING",8,2,width,34,c.orange,"ZoFontWinH2")
    Label(ui,page,"AlphaSquadLibrariesIntro","Required add-ons for group features • green: installed • red: missing. Local trackers work without these libraries.",8,38,width,28)
    local rows={
        {key="LibGroupBroadcast",name="LibGroupBroadcast",id=1337,kind="builds",toggle="Share equipped build",text="Needs LibAddonMenu-2.0 (38+) + LibDebugLogger."},
        {key="LibGroupCombatStats",name="LibGroupCombatStats",id=4024,kind="ultimate",toggle="Share group Ultimates",text="Needs LibCombat + LibGroupBroadcast."},
        {key="LibSetDetection",name="LibSetDetection",id=3338,kind="sets",toggle="Share equipped sets",text="Version 5+ with LibGroupBroadcast. Respects incognito."},
        {key="LibFoodDrinkBuff",name="LibFoodDrinkBuff",id=1902,text="Recognizes visible food/drink buffs. No setup needed."},
        {key="LibCombat",name="LibCombat",id=2528,text="Required by LibGroupCombatStats. Leave enabled."},
        {key="LibAddonMenu2",name="LibAddonMenu-2.0",id=7,text="Required by LibGroupBroadcast. Version 38 or newer."},
        {key="LibDebugLogger",name="LibDebugLogger",id=2275,text="Required by LibGroupBroadcast. No logging setup needed."},
    }
    for index,data in ipairs(rows) do
        local x=8+((index-1)%2)*(half+16);local y=78+math.floor((index-1)/2)*108
        local card=ui.CreateCard(page,"AlphaSquadLibraryCard"..index,x,y,half,98,data.name,c.orange)
        local status=Label(ui,card,"AlphaSquadLibraryStatus"..index,"",half-188,10,112,22,c.red)
        ui.CreateButton(card,"AlphaSquadLibraryLink"..index,"ESOUI",half-76,6,62,26,function() OpenLink("https://www.esoui.com/downloads/info"..data.id) end)
        if data.kind then
            local switch=ui.AddToggleRow(card,"AlphaSquadLibraryShare"..index,data.toggle,36,function() return ASUI.Sharing and ASUI.Sharing.IsEnabled(data.kind) or false end,
                function(value) if ASUI.Sharing then ASUI.Sharing.SetEnabled(data.kind,value) end end,
                data.kind=="builds" and "Share supported equipment, traits, glyphs, skill bars, CP and readiness in your current group. Both clients need compatible software. Build transport registration is pending; use in coordinated groups. Enabled at installation; your later OFF choice is saved. Module switches do not change sharing."
                or "Changes this library's matching group protocols and saved settings here, without opening another panel. Other addons using the same protocols follow this setting. Enabled at installation; your later OFF choice is saved. Module switches do not change sharing.")
            local baseHelp=switch.help
            ui.RegisterRefresher(function()
                local _,reason,available=false,"Install the listed libraries to enable sharing.",false
                if ASUI.Sharing then _,reason,available=ASUI.Sharing.GetStatus(data.kind) end
                switch.help=baseHelp..(reason and ("\n\n"..reason) or "")
                if not available then
                    switch.label:SetText("N/A")
                    if switch.thumb then switch.thumb:SetHidden(true) end
                    if switch.track then switch.track:SetHidden(true) end
                    switch.label:ClearAnchors();switch.label:SetAnchorFill(switch)
                    switch.label:SetColor(c.red[1],c.red[2],c.red[3],1)
                elseif switch.track then
                    switch.track:SetHidden(false)
                    switch.label:ClearAnchors();switch.label:SetAnchor(TOPLEFT,switch,TOPLEFT,3,0)
                    switch.label:SetDimensions(40,30)
                end
            end)
            Label(ui,card,"AlphaSquadLibraryHelp"..index,data.text,14,72,half-28,23)
        else Label(ui,card,"AlphaSquadLibraryHelp"..index,data.text,14,40,half-28,48) end
        ui.RegisterRefresher(function()
            local lib=rawget(_G,data.key);local installed=lib~=nil
            local old=data.key=="LibAddonMenu2" and type(lib)=="table" and tonumber(lib.version) and tonumber(lib.version)<38
            status:SetText(old and "UPDATE NEEDED" or installed and "INSTALLED" or "MISSING")
            local color=installed and not old and c.green or c.red;status:SetColor(color[1],color[2],color[3],1)
        end)
    end
    local help=ui.CreateCard(page,"AlphaSquadLibraryPrivacy",8+half+16,402,half,98,"DATA ACCESS",c.cyan)
    Label(ui,help,"AlphaSquadLibraryPrivacyText","Group membership alone cannot reveal full builds. Senders can use AlphaSquadBuildShare instead of the full UI. Unavailable data stays Unknown.",14,38,half-28,54)
    local footer=ui.CreateCard(page,"AlphaSquadMinion",8,518,width,70,"MINION • ADDON MANAGER",c.green)
    Label(ui,footer,"AlphaSquadMinionHelp","Install and update ESO addons and libraries, then /reloadui.",14,34,width-180,26)
    ui.CreateButton(footer,"AlphaSquadMinionLink","GET MINION",width-152,24,136,30,function() OpenLink("https://minion.mmoui.com/") end)
end)

Settings.RegisterPage("community",function(page,ui)
    page.responsiveCards=true;page.contentHeight=590
    local width=LogicalWidth(page)-16;local half=(width-16)/2
    Label(ui,page,"AlphaSquadCommunityTitle","ABOUT",8,2,width,36,ui.colors.orange,"ZoFontWinH2")
    Label(ui,page,"AlphaSquadCommunityIntro","Endgame ESO PvE • Hard Modes • Trifectas • Guides • Community",8,44,width,26)
    local site=ui.CreateCard(page,"AlphaSquadCommunitySite",8,88,width,180,"EXPLORE ALPHA SQUAD",ui.colors.orange)
    Icon(site,"AlphaSquadCommunitySiteIcon",Settings.icons.community,18,48,64)
    Label(ui,site,"AlphaSquadCommunitySiteText","Build guides, roster information and resources for your next challenge.",100,48,width-124,56,ui.colors.white,"ZoFontGame")
    ui.CreateButton(site,"AlphaSquadSiteButton","VISIT WEBSITE",100,116,190,36,function()OpenLink(ASUI.website)end)
    ui.CreateButton(site,"AlphaSquadESOUI","FIND ON ESOUI",310,116,190,36,function()OpenLink("https://www.esoui.com/downloads/search.php?search=Alpha%20Squad%20UI")end)
    ui.CreateButton(site,"AlphaSquadReleases","RELEASE NOTES",520,116,190,36,function()OpenLink("https://github.com/ALPHASQUADUI/Alpha-Squad-UI/releases")end)
    local about=ui.CreateCard(page,"AlphaSquadCommunityAbout",8,286,half,210,"ABOUT THE ADDON",ui.colors.cyan)
    Label(ui,about,"AlphaSquadAboutText","Clear group preparation and one unified Ultimate tracker. Built around native ESO information and controls.\n\nCreated by "..ASUI.Theme.authorText,16,46,half-32,130,ui.colors.muted,"ZoFontGame")
    local discord=ui.CreateCard(page,"AlphaSquadCommunityDiscord",8+half+16,286,half,210,"JOIN THE COMMUNITY",ui.colors.orange)
    Label(ui,discord,"AlphaSquadCommunityDiscordText","Find the Alpha Squad Discord, meet the roster and connect with other players.",16,46,half-32,80,ui.colors.muted,"ZoFontGame")
    local join=ui.CreateButton(discord,"AlphaSquadCommunityDiscordButton","JOIN DISCORD",16,148,190,36,function()OpenLink(ASUI.discord)end)
    join.help="Open the Alpha Squad server invitation after ESO's normal link confirmation. No build, character or group data is sent through this link."
    Label(ui,page,"AlphaSquadCommunityCommands","/asui  Settings     /asmove  Arrange HUD     /assupport builds  Inspect builds",8,522,width,30,ui.colors.muted,"ZoFontGame")
end)
