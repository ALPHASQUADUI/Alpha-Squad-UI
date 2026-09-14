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
    function c:GetWidth() return self.width end
    function c:GetHeight() return self.height end
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
AlphaSquadUI={name="AlphaSquadUI",version="3.0.0",website="https://alphasquadeso.com/",Modules={}}
assert(loadfile("AlphaSquadUI/Core/Utils.lua"))()
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
check(Shell.settingsWindow.width==1350 and Shell.settingsWindow.height<=720,"Settings provide the wider desktop canvas and fit the viewport")
check(Shell.settingsScroll.maximum==0 and Shell.settingsPages.libraries.contentHeight==590,"Every library and sharing switch fits on one page")
GuiRoot:SetDimensions(854,480);Shell:ApplySettingsGeometry()
check(Shell.settingsWindow.width*Shell.settingsWindow.scale<=814 and Shell.settingsWindow.height*Shell.settingsWindow.scale<=440,
    "The complete settings canvas fits a smaller viewport without clipping")
check(Shell.settingsScroll.maximum==0,"Libraries still needs no scrollbar at a smaller viewport")
GuiRoot:SetDimensions(1280,720);Shell:ApplySettingsGeometry()
check(controls.AlphaSquadSettingsClose==nil,"Parent settings has no close cross")
check(Shell.settingsPages.dashboard~=nil,"Dashboard is available independently of modules")
check(not Shell.settingsNavButtons.overload and Shell.settingsNavButtons.discord and not controls.AlphaSquadDashboardModule3,
    "Dashboard has two modules; Discord is accessible and Overload has no separate module navigation")
local choice=controls.AlphaSquadThemeChoice.combo
check(#choice.entries==3 and choice.selected.id=="obsidian" and not choice.sorted,"The native global theme picker defaults to Obsidian and retains curated order")
choice.entries[1].callback()
check(AlphaSquadUI.Theme.GetPresetId()=="ember" and choice.selected.id=="ember","Selecting a native theme applies and refreshes the picker immediately")
check(Shell.settingsPages.dashboard.contentHeight==590 and Shell.settingsPages.discord.contentHeight==590,"Dashboard and Discord fit the shared single-page canvas")
check(controls.AlphaSquadLibraryStatus1.text=="MISSING","Missing transport is clearly identified")
check(controls.AlphaSquadLibraryShare1Button.label.text=="N/A","Missing sharing controls cannot be mistaken for a confirmed OFF setting")
check(controls.AlphaSquadLibraryNativeSettings==nil,"Sharing never offers a button that navigates to another addon panel")
LibGroupBroadcast={};Settings.RefreshMain()
check(controls.AlphaSquadLibraryStatus1.text=="INSTALLED","Installed library state refreshes when settings are shown")
local sharingOn=true
AlphaSquadUI.Sharing={IsEnabled=function() return sharingOn end,
    GetStatus=function() return sharingOn,nil,true end,
    SetEnabled=function(_,value) sharingOn=value;return true end}
Settings.RefreshMain()
check(controls.AlphaSquadLibraryShare2Button.label.text=="ON","Libraries reflects an enabled native sharing setting")
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
Settings.OpenPage("discord")
controls.AlphaSquadDiscordJoin.handlers.OnMouseUp(nil,MOUSE_BUTTON_INDEX_LEFT,true)
check(requested[2]=="https://discord.com/widget?id=1524092356696084690&theme=dark" and not Shell.settingsWindow:IsHidden(),
    "Discord opens the supplied community widget through the normal native confirmation")
check(confirmationCount==0,"The addon never confirms an external URL on the player's behalf")
Settings.layout={x=120,y=75}
Shell:CloseSettingsWindow();Shell:ToggleSettingsWindow()
check(Shell.settingsWindow.anchor[1]==TOPLEFT and Shell.settingsWindow.anchor[4]==120 and Shell.settingsWindow.anchor[5]==75,
    "Reopening settings retains the saved window placement")
local refreshCount=0
Shell.settingsRefreshers[#Shell.settingsRefreshers+1]=function() refreshCount=refreshCount+1 end
Shell:CloseSettingsWindow();Shell:RefreshSettingsWindow()
check(refreshCount==0,"Hidden settings skip their page refresh work")

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
