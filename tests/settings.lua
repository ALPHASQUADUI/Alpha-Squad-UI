-- Deterministic window, scrolling and settings lifecycle regressions.
-- Controls are doubles, not certification of ESO's layout renderer.
local total = 0
local function check(value, message) total = total + 1; assert(value, message) end
local controls = {}
local function Control(name, parent)
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
    function c:SetAnchorFill(target) self.width,self.height=target.width,target.height end
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
    controls[name]=c
    return c
end
local constantNames={"CT_CONTROL","CT_TEXTURE","CT_LABEL","CT_SCROLL","CT_SLIDER","TOPLEFT","TOPRIGHT","BOTTOMLEFT",
    "BOTTOMRIGHT","LEFT","RIGHT","CENTER","TEXT_ALIGN_CENTER","TEXT_ALIGN_LEFT","TEXT_ALIGN_RIGHT","TEXT_ALIGN_TOP",
    "ORIENTATION_VERTICAL","DT_HIGH","DL_OVERLAY","MOUSE_BUTTON_INDEX_LEFT","MOUSE_BUTTON_INDEX_RIGHT",
    "EVENT_ADD_ON_LOADED","EVENT_SCREEN_RESIZED"}
for index,name in ipairs(constantNames) do _G[name]=index end
GuiRoot=Control("GuiRoot");GuiRoot:SetDimensions(1280,720)
WINDOW_MANAGER={CreateControl=function(_,name,parent) return Control(name,parent) end,
    CreateTopLevelWindow=function(_,name) return Control(name,GuiRoot) end}
EVENT_MANAGER={RegisterForEvent=function() end,UnregisterForEvent=function() end,UnregisterForUpdate=function() end}
AlphaSquadUI={version="test",Modules={}}
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

assert(loadfile("AlphaSquadUI/Modules/Overload/Overload.lua"))()
local AOT=AlphaSquadUI.Modules.Overload
AOT.sv={scale=100,opacity=95,reserveWarningThreshold=160,reserveThreshold=130,readyReminderThreshold=400}
AOT:CreateSettingsWindow()
check(Settings.GetPageBuilder("libraries") and AOT.settingsPages.libraries,"Libraries page is registered in the real shell")
Settings.OpenPage("libraries")
check(controls.AlphaSquadSettingsTitle.text:gsub("|c%x%x%x%x%x%x",""):gsub("|r",""):find("Ąlpha Şquad UI",1,true)~=nil,"Settings brand retains the original letters and UI suffix")
check(AOT.settingsWindow.width==1350 and AOT.settingsWindow.height<=720,"Settings provide the wider desktop canvas and fit the viewport")
check(AOT.settingsScroll.maximum==0 and AOT.settingsPages.libraries.contentHeight==590,"Every library and sharing switch fits on one page")
GuiRoot:SetDimensions(854,480);AOT:ApplySettingsGeometry()
check(AOT.settingsWindow.width*AOT.settingsWindow.scale<=814 and AOT.settingsWindow.height*AOT.settingsWindow.scale<=440,
    "The complete settings canvas fits a smaller viewport without clipping")
check(AOT.settingsScroll.maximum==0,"Libraries still needs no scrollbar at a smaller viewport")
GuiRoot:SetDimensions(1280,720);AOT:ApplySettingsGeometry()
check(controls.AlphaSquadSettingsClose==nil,"Parent settings has no close cross")
check(AOT.settingsPages.dashboard~=nil,"Dashboard is available independently of modules")
check(controls.AlphaSquadLibraryStatus1.text=="MISSING","Missing transport is clearly identified")
LibGroupBroadcast={};Settings.RefreshMain()
check(controls.AlphaSquadLibraryStatus1.text=="INSTALLED","Installed library state refreshes when settings are shown")
local refreshCount=0
AOT.settingsRefreshers[#AOT.settingsRefreshers+1]=function() refreshCount=refreshCount+1 end
AOT:CloseSettingsWindow();AOT:RefreshSettingsWindow()
check(refreshCount==0,"Hidden settings skip their page refresh work")

local native={name="Graphics",categoryName="Settings"}
local otherAddon={name="Another addon",categoryName="Settings",id=105}
local entries={native,otherAddon}
SETTING_PANEL_MAX_VALUE=50
KEYBOARD_OPTIONS={currentPanelId=110,panelNames={}}
ZO_FadeSceneFragment={New=function(_,control) return {control=control} end}
ZO_GameMenu_AddSettingPanel=function(data) data.categoryName="Settings";entries[#entries+1]=data end
ZO_GameMenuManager_GetSubcategoriesEntries=function() return entries end
AOT:RegisterDirectSettingsPanel()
check(entries[1]==native and entries[2]==AOT.directSettingsPanelData and entries[3]==otherAddon,
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
