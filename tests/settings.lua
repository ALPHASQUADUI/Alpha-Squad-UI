-- Deterministic window, scrolling and settings lifecycle regressions.
-- Controls are doubles, not certification of ESO's layout renderer.
local total = 0
local function check(value, message) total = total + 1; assert(value, message) end
local controls = {}
local serial=0
local function Control(name, parent)
    if not name then serial=serial+1;name="anonymous"..serial end
    local c = {name=name, parent=parent, hidden=false, width=100, height=100, handlers={}}
    function c:SetHidden(value) self.hidden=value==true end
    function c:IsHidden() return self.hidden end
    function c:SetDimensions(w,h) self.width,self.height=w,h end
    function c:SetWidth(w) self.width=w end
    function c:SetHeight(h)
        self.height=h
        if self.handlers.OnRectHeightChanged then self.handlers.OnRectHeightChanged(self) end
    end
    function c:GetScale() return (self.scale or 1) * (self.parent and self.parent:GetScale() or 1) end
    function c:GetWidth() return self.width * self:GetScale() end
    function c:GetHeight() return self.height * self:GetScale() end
    function c:SetText(text) self.text=text end
    function c:SetAnchor(...) self.anchor={...} end
    function c:SetAnchorFill(target) target=target or self.parent;self.width,self.height=target.width,target.height end
    function c:SetHandler(event,callback) self.handlers[event]=callback end
    function c:SetVerticalScroll(offset) self.verticalScroll=offset end
    function c:SetMinMax(low,high) self.low,self.high=low,high end
    function c:SetValue(value)
        if value~=self.value then
            self.value=value
            if self.handlers.OnValueChanged then self.handlers.OnValueChanged(self,value) end
        end
    end
    function c:SetScale(scale) self.scale=scale end
    for _, method in ipairs({"SetMouseEnabled","SetOrientation","SetValueStep","SetThumbTexture","SetFont",
        "SetColor","SetVerticalAlignment","SetHorizontalAlignment","SetClampedToScreen","SetMovable","SetDrawTier",
        "SetDrawLayer","SetDrawLevel","SetHeightConstraint","SetAlpha","ClearAnchors","StartMoving","StopMovingOrResizing",
        "SetTextureCoords","SetMaxLineCount","SetWrapMode","SetTexture"}) do
        c[method]=function() end
    end
    function c:SetDrawTier(value) self.drawTier=value end
    function c:SetDrawLayer(value) self.drawLayer=value end
    function c:SetDrawLevel(value) self.drawLevel=value end
    controls[name]=c
    return c
end
local constantNames={"CT_CONTROL","CT_TEXTURE","CT_LABEL","CT_SCROLL","CT_SLIDER","TOPLEFT","TOPRIGHT","BOTTOMLEFT",
    "BOTTOMRIGHT","LEFT","RIGHT","CENTER","TEXT_ALIGN_CENTER","TEXT_ALIGN_LEFT","TEXT_ALIGN_RIGHT","TEXT_ALIGN_TOP",
    "ORIENTATION_VERTICAL","DT_HIGH","DL_OVERLAY","DT_MEDIUM","DL_CONTROLS","MOUSE_BUTTON_INDEX_LEFT","MOUSE_BUTTON_INDEX_RIGHT",
    "EVENT_ADD_ON_LOADED","EVENT_SCREEN_RESIZED"}
for index,name in ipairs(constantNames) do _G[name]=index end
GuiRoot=Control("GuiRoot");GuiRoot:SetDimensions(1280,720)
WINDOW_MANAGER={CreateControl=function(_,name,parent) return Control(name,parent) end,
    CreateTopLevelWindow=function(_,name) return Control(name,GuiRoot) end}
local eventCallbacks,pending={},{}
EVENT_MANAGER={RegisterForEvent=function(_,name,_,callback) eventCallbacks[name]=callback end,
    UnregisterForEvent=function(_,name) eventCallbacks[name]=nil end,UnregisterForUpdate=function() end}
function zo_callLater(callback) pending[#pending+1]=callback end
WINDOW_MANAGER.CreateControlFromVirtual=function(_,name,parent)
    local control=Control(name,parent)
    control.combo={entries={}}
    function control.combo:SetSortsItems(value) self.sorted=value end
    function control.combo:CreateItemEntry(text,callback) return {name=text,callback=callback} end
    function control.combo:AddItem(entry) self.entries[#self.entries+1]=entry end
    function control.combo:SetSelectedItemByEval(evaluate,ignoreCallback)
        for _,entry in ipairs(self.entries) do
            if evaluate(entry) then self.selected=entry;if not ignoreCallback then entry.callback() end;return end
        end
    end
    return control
end
ZO_ComboBox_ObjectFromContainer=function(control) return control.combo end
SLASH_COMMANDS={}
AlphaSquadUI={name="AlphaSquadUI",version="3.0.0",website="https://alphasquadeso.com/",discord="https://discord.gg/snDyd23h6N",Modules={}}
assert(loadfile("AlphaSquadUI/Core/Utils.lua"))()
assert(loadfile("AlphaSquadUI/Core/Localization.lua"))()
assert(loadfile("AlphaSquadUI/Localization/fr.lua"))()
assert(loadfile("AlphaSquadUI/Core/Theme.lua"))()
assert(loadfile("AlphaSquadUI/Core/Settings.lua"))()
local Settings=AlphaSquadUI.Settings
local main,detail=Control("main"),Control("detail")
main:SetHidden(true);detail:SetHidden(true)
local closeCount,visibilityCount=0,0
AlphaSquadUI.Modules.Test={ApplyVisibility=function() visibilityCount=visibilityCount+1 end}
Settings.RegisterExclusiveWindow("settings",main,function() main:SetHidden(true);closeCount=closeCount+1 end)
Settings.RegisterExclusiveWindow("detail",detail,function() detail:SetHidden(true) end)
Settings.AttachShell(main,function(id) main.page=id end,function() main.refresh=true end)
check(Settings.OpenPage("libraries") and not main:IsHidden() and main.page=="libraries","Settings opens the requested page")
check(Settings.AnyExclusiveWindowVisible(),"Open settings count as an exclusive window")
check(Settings.ShowExclusiveWindow("detail") and main:IsHidden() and not detail:IsHidden(),"Opening a detail closes main settings")
check(closeCount==1,"Switching windows invokes the main close callback exactly once")
Settings.OpenPage("libraries")
check(detail:IsHidden() and not main:IsHidden(),"Returning to settings closes the detail")
Settings.CloseMain()
check(not Settings.AnyExclusiveWindowVisible() and closeCount==2,"Closing settings restores no exclusive window")
check(not Settings.ShowExclusiveWindow("missing") and visibilityCount>0,"Unknown windows do not open while visibility hooks run for real switches")

local child,scroll,slider=Settings.CreateScrollArea(GuiRoot,"testScroll",0,0,300,200,600)
check(scroll.maximum==400 and not slider:IsHidden(),"Overflow enables a bounded scrollbar")
scroll.handlers.OnMouseWheel(scroll,-3)
check(scroll.verticalScroll==120 and slider.value==120,"Mouse wheel updates content and thumb together")
slider:SetValue(5000)
check(scroll.verticalScroll==400,"Scrolling cannot exceed available content")
child:SetHeight(100)
check(scroll.verticalScroll==0 and slider:IsHidden(),"Shrinking content clamps an old scroll offset and hides the scrollbar")
child:SetHeight(600);scroll:SetHeight(700)
check(scroll.maximum==0 and scroll.handlers.OnUpdate==nil,"Viewport resize uses events without an update loop")

assert(loadfile("AlphaSquadUI/Core/Shell.lua"))()
local Shell=AlphaSquadUI.Shell
local profileReady=false
Settings.RegisterPage("ulttracker",function(page) page.profileReady=profileReady end)
eventCallbacks.AlphaSquadUI_Shell(nil,AlphaSquadUI.name)
check(not Shell.initialized and #pending==1,"Shell construction waits until all addon-loaded profile callbacks can finish")
profileReady=true;pending[1]();pending={}
check(Shell.initialized and Shell.settingsPages.ulttracker.profileReady,"Deferred shell builds module pages with initialized profiles")
check(Settings.GetPageBuilder("libraries") and Shell.settingsPages.libraries,"Libraries page is registered in the real shell")
Settings.OpenPage("libraries")
check(controls.AlphaSquadSettingsTitle.text:gsub("|c%x%x%x%x%x%x",""):gsub("|r",""):find("Ąlpha Şquad UI",1,true)~=nil,"Settings brand retains the original letters and UI suffix")
check(Shell.settingsWindow.width==1256 and Shell.settingsWindow.height==696 and Shell.settingsWindow.scale==1,
    "Settings fit the actual desktop viewport without shrinking native text or controls")
check(Shell.settingsScroll.maximum==0 and Shell.settingsPages.libraries.contentHeight==590,"Every library and sharing switch fits on one page")
GuiRoot:SetDimensions(854,480);Shell:ApplySettingsGeometry()
check(Shell.settingsWindow.width==830 and Shell.settingsWindow.height==456 and Shell.settingsWindow.scale==1,
    "A smaller viewport keeps readable native text and adapts the actual window dimensions")
check(Shell.settingsCompact and Shell.settingsSidebar.height==92 and controls.AlphaSquadNav_dashboard.label.width>=200,
    "Narrow screens use two navigation rows with full module names")
check(controls.AlphaSquadLibraryCard2.anchor[4]==8 and controls.AlphaSquadLibraryCard2.anchor[5]>controls.AlphaSquadLibraryCard1.anchor[5],
    "Library cards stack vertically when two readable columns cannot fit")
check(Shell.settingsScroll.maximum>0 and controls.AlphaSquadLibraryShare2Button.height==30,
    "Unavoidable overflow scrolls instead of shrinking library switches and descriptions")
local narrowCardWidth=controls.AlphaSquadLibraryCard1.width
for _, dimensions in ipairs({{1920,1080},{3440,1440},{800,600},{640,480},{3840,2160},{1280,720}}) do
    GuiRoot:SetDimensions(dimensions[1],dimensions[2]);Shell:ApplySettingsGeometry();Shell:ShowSettingsPage("libraries")
    check(Shell.settingsWindow.scale==1 and Shell.settingsWindow.width<=dimensions[1]-24 and Shell.settingsWindow.height<=dimensions[2]-24,
        "Viewport and display-mode changes preserve the native control scale within screen bounds")
    check(controls.AlphaSquadLibraryCard1.width>400 and controls.AlphaSquadLibraryLink1.width==62,
        "Reflow preserves room for exact library names, status text and a usable link button")
    check(Shell.settingsScroll.maximum==(dimensions[1]<1000 and Shell.settingsPages.libraries.contentHeight-Shell.settingsScroll.height or 0),
        "Libraries remains one page wherever the viewport has room for readable columns")
end
GuiRoot:SetDimensions(1024,768);Shell:ApplySettingsGeometry()
check(Shell.settingsScroll.maximum==0 and not controls.AlphaSquadLibraryCard7:IsHidden() and controls.AlphaSquadLibraryShare1Button.height==30,
    "A 1024-wide screen fits every library and sharing switch by condensing helpers without shrinking controls")
check(controls.AlphaSquadLibraryHelp1:IsHidden() and controls.AlphaSquadLibraryShare1Button.help:find("LibDebugLogger",1,true),
    "Condensed library cards retain dependency instructions on the sharing tooltip")
GuiRoot:SetDimensions(1920,1080);Shell:ApplySettingsGeometry()
check(Shell.settingsWindow.width==1350 and controls.AlphaSquadLibraryCard1.width<narrowCardWidth and not controls.AlphaSquadLibraryHelp1:IsHidden(),
    "Returning to desktop restores two columns and visible helper text without recreating controls")
check(Shell.settingsPages.dashboard.contentHeight<=618 and Shell.settingsPages.community.contentHeight<=618,
    "Dashboard and About fit the desktop single-page canvas")
GuiRoot:SetDimensions(1280,720);Shell:ApplySettingsGeometry()
check(controls.AlphaSquadSettingsClose and controls.AlphaSquadSettingsClose.anchor[1]==TOPRIGHT,"Root settings exposes a clear top-right Close control")
check(Shell.settingsPages.dashboard~=nil,"Dashboard is available independently of modules")
check(not Shell.settingsNavButtons.overload and not Shell.settingsNavButtons.discord and not controls.AlphaSquadDashboardModule3,
    "Dashboard has two modules; community links share one About page without redundant navigation")
check(Shell.settingsNavButtons.community.label.text=="About" and Shell.settingsNavButtons.supportcoverage.label.width>=160,
    "About has a short label and the sidebar reserves space for the complete Support Coverage name")
local choice=controls.AlphaSquadThemeChoice.combo
Settings.OpenPage("dashboard")
check(#choice.entries==3 and choice.selected.id=="obsidian" and not choice.sorted,"The native global theme picker defaults to Obsidian and retains curated order")
choice.entries[1].callback()
check(AlphaSquadUI.Theme.GetPresetId()=="ember" and choice.selected.id=="ember","Selecting a native theme applies and refreshes the picker immediately")
check(Shell.settingsPages.dashboard.contentHeight<=594 and Shell.settingsPages.community.contentHeight<=594,"Dashboard and About fit the available desktop canvas")
Settings.OpenPage("libraries")
check(controls.AlphaSquadLibraryStatus1.text=="MISSING","Missing transport is clearly identified")
check(controls.AlphaSquadLibraryShare1Button.label.text=="N/A","Missing sharing controls cannot be mistaken for a confirmed OFF setting")
check(controls.AlphaSquadLibraryShare1Button.track:IsHidden() and controls.AlphaSquadLibraryShare1Button.thumb:IsHidden(),
    "Unavailable library controls hide the switch rail and thumb together")
check(controls.AlphaSquadLibraryNativeSettings==nil,"Sharing never offers a button that navigates to another addon panel")
check(controls.AlphaSquadLibraryShare1Button.help:find("Starts OFF",1,true) and controls.AlphaSquadLibraryShare2Button.help:find("Starts OFF",1,true),
    "Each sharing option explains that new installations require an explicit ON choice")
LibGroupBroadcast={};Settings.RefreshMain()
check(controls.AlphaSquadLibraryStatus1.text=="INSTALLED","Installed library state refreshes when settings are shown")
local sharingOn=true
AlphaSquadUI.Sharing={IsEnabled=function() return sharingOn end,
    GetStatus=function() return sharingOn,nil,true end,
    SetEnabled=function(_,value) sharingOn=value;return true end}
Settings.RefreshMain()
check(controls.AlphaSquadLibraryShare2Button.label.text=="ON","Libraries reflects an enabled native sharing setting")
check(not controls.AlphaSquadLibraryShare2Button.track:IsHidden() and controls.AlphaSquadLibraryShare2Button.label.width==40,
    "A library becoming available restores a separate text label and switch without overlap")
controls.AlphaSquadLibraryShare2Button.handlers.OnMouseUp(nil,MOUSE_BUTTON_INDEX_LEFT,true)
check(not sharingOn and controls.AlphaSquadLibraryShare2Button.label.text=="OFF" and not Shell.settingsWindow:IsHidden(),
    "Sharing toggles and refreshes in place without leaving the Alpha Squad window")
check(Shell.settingsWindow.drawTier==DT_MEDIUM and Shell.settingsWindow.drawLevel<20,
    "Addon settings remain below the native medium-tier URL confirmation")
local requested={};local confirmationCount=0
RequestOpenUnsafeURL=function(url) requested[#requested+1]=url end
ConfirmOpenURL=function() confirmationCount=confirmationCount+1 end
check(Settings.OpenLink("https://minion.mmoui.com/") and #requested==1 and not Shell.settingsWindow:IsHidden(),
    "A link requests the native confirmation without closing the addon or redirecting settings")
check(not Settings.OpenLink("javascript:alert(1)") and not Settings.OpenLink("https://example.org/\npath") and #requested==1,
    "Unsupported schemes and control characters never reach the external URL request")
Settings.OpenPage("community")
controls.AlphaSquadCommunityDiscordButton.handlers.OnMouseUp(nil,MOUSE_BUTTON_INDEX_LEFT,true)
check(requested[2]==AlphaSquadUI.discord and not Shell.settingsWindow:IsHidden(),
    "About opens the configured Discord invitation directly through the normal native confirmation")
check(not Settings.GetPageBuilder("discord") and controls.AlphaSquadCommunityTitle.text=="ABOUT",
    "Community information uses one About page without an intermediate Discord widget page")
check(confirmationCount==0,"The addon never confirms an external URL on the player's behalf")
Settings.layout={x=120,y=75}
Shell:CloseSettingsWindow();Shell:ToggleSettingsWindow()
check(Shell.settingsWindow.anchor[1]==TOPLEFT and Shell.settingsWindow.anchor[4]==120 and Shell.settingsWindow.anchor[5]==75,
    "Reopening settings retains the saved window placement")
local refreshCount=0
Shell.settingsRefreshers[#Shell.settingsRefreshers+1]=function() refreshCount=refreshCount+1 end
Shell:CloseSettingsWindow();Shell:RefreshSettingsWindow()
check(refreshCount==0,"Hidden settings skip their page refresh work")
local pageRefreshes={dashboard=0,libraries=0}
for _,id in ipairs({"dashboard","libraries"}) do
    local pageId=id
    Shell.buildingSettingsPage=pageId
    Shell:RegisterSettingsRefresher(function()pageRefreshes[pageId]=pageRefreshes[pageId]+1 end)
end
Shell.buildingSettingsPage=nil
Settings.OpenPage("dashboard")
local dashboardRefreshes=pageRefreshes.dashboard
Shell:RefreshSettingsWindow()
check(pageRefreshes.dashboard>dashboardRefreshes and pageRefreshes.libraries==0,
    "A live settings update runs only the visible page's refreshers")
Settings.OpenPage("libraries")
check(pageRefreshes.libraries>0,"Opening a previously hidden page immediately refreshes its current values")
dashboardRefreshes=pageRefreshes.dashboard
Shell:RefreshSettingsWindow()
check(pageRefreshes.dashboard==dashboardRefreshes,"Library updates do not repaint hidden Dashboard controls")
local libraryRefreshers=Shell.settingsPageRefreshers.libraries
libraryRefreshers[#libraryRefreshers+1]=function()error("Synthetic settings refresh failure")end
check(not pcall(Shell.RefreshSettingsWindow,Shell) and not Shell.refreshingSettings,
    "A failing page callback preserves its error without permanently blocking later settings refreshes")
table.remove(libraryRefreshers);Shell:RefreshSettingsWindow()
local combat=false
IsUnitInCombat=function()return combat end
Shell:CloseSettingsWindow();combat=true
SLASH_COMMANDS["/asui"]()
check(Shell.settingsWindow:IsHidden(),"The settings slash command uses the same combat opening guard as keybindings")
combat=false;Shell:ToggleSettingsWindow();combat=true;Shell:ToggleSettingsWindow()
check(Shell.settingsWindow:IsHidden(),"An already visible root can always be closed after combat starts")
combat=false

local native={name="Graphics",categoryName="Settings"}
local otherAddon={name="Another addon",categoryName="Settings",id=105}
local entries={native,otherAddon}
SETTING_PANEL_MAX_VALUE=50
KEYBOARD_OPTIONS={currentPanelId=110,panelNames={}}
ZO_FadeSceneFragment={New=function(_,control) return {control=control} end}
ZO_GameMenu_AddSettingPanel=function(data) data.categoryName="Settings";entries[#entries+1]=data end
ZO_GameMenuManager_GetSubcategoriesEntries=function() return entries end
Shell:RegisterDirectSettingsPanel()
check(entries[1]==native and entries[2]==Shell.directSettingsPanelData and entries[3]==otherAddon,
    "Only the own panel moves ahead of an identified addon; native settings keep their position")
check(KEYBOARD_OPTIONS.panelNames[110]=="Ąlpha Şquad UI","Native settings metadata uses the full addon name")
SCENE_MANAGER={RemoveFragment=function()end}
Settings.OpenPage("community")
Shell.directSettingsPanelData.unselectedCallback()
check(Shell.settingsWindow:IsHidden() and not Settings.AnyExclusiveWindowVisible(),
    "Selecting another native Settings category dismisses a restored raw addon window")
SCENE_MANAGER=nil

-- The language picker changes existing and hidden controls, retaining geometry
-- and selected stable IDs without generating duplicate dropdown entries.
AlphaSquadUI.Preferences={sv={language="auto"},Initialize=function()end}
Settings.OpenPage("dashboard")
local language=controls.AlphaSquadLanguageChoice.combo
Shell:RefreshSettingsWindow()
check(#language.entries==3 and language.selected.id=="auto","The language picker defaults to the game's language")
local closeControl=controls.AlphaSquadSettingsClose
local contentWidth=Shell.settingsPages.dashboard.width
language.entries[3].callback()
check(AlphaSquadUI.Localization.GetLanguage()=="fr" and AlphaSquadUI.Preferences.sv.language=="fr",
    "Selecting French changes and persists addon language without reload")
check(closeControl==controls.AlphaSquadSettingsClose and closeControl.label.text=="FERMER",
    "Changing language refreshes the existing shell controls")
check(Shell.settingsNavButtons.community.label.text==AlphaSquadUI.L("About")
    and controls.AlphaSquadLibrariesTitle.text==AlphaSquadUI.L("LIBRARIES & SHARING"),
    "Navigation and hidden settings pages refresh together")
check(language.selected.id=="fr" and #language.entries==3 and #choice.entries==3,
    "Localized dropdowns retain stable selection and never duplicate items")
check(Shell.settingsPages.dashboard.width==contentWidth and controls.AlphaSquadLanguageChoice.width<=contentWidth-28,
    "Changing language keeps the dropdown inside its responsive card")
language.entries[2].callback()
check(closeControl.label.text=="CLOSE" and controls.AlphaSquadLibrariesTitle.text=="LIBRARIES & SHARING",
    "Switching back to English does not preserve stale French text")
local languageClient="fr"
GetCVar=function()return languageClient end
language.entries[1].callback()
check(AlphaSquadUI.Localization.GetLanguage()=="fr" and language.selected.id=="auto",
    "Automatic follows French game language while retaining the Automatic preference")
languageClient="en";AlphaSquadUI.Localization.SetLanguage("auto")
check(AlphaSquadUI.Localization.GetLanguage()=="en","Automatic also follows an English game client")
GetCVar=nil

-- Done returns to the actual native category, even when Move HUD was opened
-- from a secondary window. Selection is by our exact data identity.
local nativeShows,nativeSelects=0,0
local nativeScene={GetName=function()return "hud" end,GetState=function()return SCENE_SHOWN end}
SCENE_SHOWN=999
SCENE_MANAGER={GetCurrentScene=function()return nativeScene end,
    Show=function(_,name)check(name=="gameMenuInGame","Placement returns to native keyboard settings");nativeShows=nativeShows+1 end,
    AddFragment=function()end,RemoveFragment=function()end}
KEYBOARD_OPTIONS.ChangePanels=function(_,id)check(id==Shell.directSettingsPanelId,"Native options select only Alpha Squad")end
local nativeNode={data=Shell.directSettingsPanelData}
ZO_GameMenu_InGame={gameMenu={navigationTree={
    ExecuteOnSubTree=function(_,_,visit)visit({data=otherAddon});visit(nativeNode)end,
    SelectNode=function(_,node)check(node==nativeNode,"Native tree selection uses our exact panel");nativeSelects=nativeSelects+1 end}}}
ZO_Dialogs_IsShowingDialog=function()return true end
check(not Settings.ReturnFromLayout({id="settings",page="dashboard"}) and nativeShows==0,"A native dialog suppresses placement return navigation")
ZO_Dialogs_IsShowingDialog=nil
check(Settings.ReturnFromLayout({id="builds",page="libraries"}) and nativeShows==1 and Shell.pendingNativePage=="libraries",
    "A placement return queues the native Alpha settings page instead of a secondary window")
check(Shell:SelectNativeSettings() and nativeSelects==1 and Shell.activeSettingsPage=="libraries" and Shell.settingsOpenedFromGameMenu,
    "Native completion selects Alpha and restores the prior internal settings page")
Shell.pendingNativePage="dashboard";combat=true
check(not Shell:SelectNativeSettings() and Shell.pendingNativePage==nil and nativeSelects==1,
    "Combat between Done and native completion consumes the request without reopening")
combat=false
SCENE_HIDING=1000
Shell.pendingNativePage="dashboard"
Shell:HandleNativeSettingsScene({GetName=function()return "gameMenuInGame" end},SCENE_HIDING)
check(Shell.pendingNativePage==nil and not Shell:SelectNativeSettings(),
    "Canceling native settings entry cannot reopen Alpha during a later unrelated menu visit")
local resumed=0
SCENE_MANAGER={GetCurrentScene=function()return {GetName=function()return "gameMenuInGame" end}end,
    RemoveFragment=function()end,ShowBaseScene=function()resumed=resumed+1 end,SetInUIMode=function(_,value)check(value==false,"Close releases the gameplay cursor")end}
closeControl.handlers.OnMouseUp(nil,MOUSE_BUTTON_INDEX_LEFT,true)
check(resumed==1 and not Settings.AnyExclusiveWindowVisible(),"Top-right Close leaves settings and resumes gameplay")
SCENE_MANAGER=nil;ZO_GameMenu_InGame=nil

-- Configuration must retain access to currently shared skills plus saved filters.
local ULT={COLORS=nil,Group={sv={trackedAbilities={}},ApplyConfigWindowScale=function() end}}
AlphaSquadUI.Modules.ULTTracker=ULT
local Group=ULT.Group
function Group:GetTrackedAbilityCount()
    local count=0;for _ in pairs(self.sv.trackedAbilities) do count=count+1 end;return count
end
function Group:GetAvailableAbilities()
    local result={};for i=1,48 do result[i]={id=i,name="Ultimate "..i} end;return result
end
function Group:Refresh() self.refreshes=(self.refreshes or 0)+1 end
assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTGroupSettings.lua"))()
Group:CreateConfigWindow()
check(#Group.configWindow.abilityRows==48 and Group.configWindow.abilityScroll~=nil,"The group configuration scrolls all possible current and saved Ultimates")
controls.AlphaSquadULTGroupSelectAll.handlers.OnMouseUp(nil,MOUSE_BUTTON_INDEX_LEFT,true)
check(Group:GetTrackedAbilityCount()==24 and Group.refreshes==1,"Select All honors the persistent 24-filter cap with one refresh")
print(string.format("PASS: %d assertions; Lua %s. No ESO-runtime certification.",total,_VERSION))
