-- Real unified HUD controls with a deterministic native-control double.
local total=0
local function check(value,message) total=total+1;assert(value,message) end
local controls={}
local function Control(name,parent)
 local c={name=name,parent=parent,width=0,height=0,x=0,y=0,scale=1,hidden=false,handlers={}}
 function c:SetDimensions(w,h) self.geometryWrites=(self.geometryWrites or 0)+1;self.width=w;self.height=h end
 function c:GetWidth() return self.width*self.scale end
 function c:GetHeight() return self.height*self.scale end
 function c:SetWidth(w) self.widthWrites=(self.widthWrites or 0)+1;self.width=w end
 function c:SetHeight(h) self.height=h end
 function c:SetScale(value) self.scale=value end
 function c:GetScale() return self.scale end
 function c:GetLeft() return self.x end
 function c:GetTop() return self.y end
 function c:SetAnchor(point,relative,relativePoint,x,y) self.anchor={point,relative,relativePoint};self.x=x or 0;self.y=y or 0 end
 function c:SetHidden(value) self.hidden=value==true end
 function c:IsHidden() return self.hidden end
 function c:SetText(value) self.textWrites=(self.textWrites or 0)+1;self.text=value end
 function c:SetTexture(value) self.textureWrites=(self.textureWrites or 0)+1;self.texture=value end
 function c:SetMaxLineCount(value) self.maxLines=value end
 function c:SetWrapMode(value) self.wrapMode=value end
 function c:SetAlpha(value) self.alpha=value end
 function c:SetColor(r,g,b,a) self.color={r,g,b,a} end
 function c:SetHandler(name,fn) self.handlers[name]=fn end
 setmetatable(c,{__index=function(_,key) if key:match('^Set') or key:match('^Clear') or key:match('^Start') or key:match('^Stop') then return function() end end end})
 if name then controls[name]=c end
 return c
end
GuiRoot=Control("GuiRoot");GuiRoot:SetDimensions(1920,1080)
TEXT_WRAP_MODE_ELLIPSIS=1
local windows=0
WINDOW_MANAGER={CreateControl=function(_,name,parent) return Control(name,parent) end,
 CreateTopLevelWindow=function(_,name) windows=windows+1;return Control(name,GuiRoot) end}
HOTBAR_CATEGORY_PRIMARY=1;HOTBAR_CATEGORY_BACKUP=2;ACTION_BAR_ULTIMATE_SLOT_INDEX=7;COMBAT_MECHANIC_FLAGS_ULTIMATE=10
EVENT_ADD_ON_LOADED=1;EVENT_PLAYER_ACTIVATED=2
SCENE_SHOWN=1;HUD_SCENE={GetState=function() return SCENE_SHOWN end,RegisterCallback=function() end}
EVENT_MANAGER={RegisterForEvent=function() end,UnregisterForEvent=function() end,RegisterForUpdate=function() end,UnregisterForUpdate=function() end,AddFilterForEvent=function() end}
SLASH_COMMANDS={};function zo_callLater() end
function zo_strformat(_,value) return value end
function GetWorldName() return "TestWorld" end
local activeCategory=HOTBAR_CATEGORY_PRIMARY
function GetActiveHotbarCategory() return activeCategory end
local now=10000
function GetGameTimeMilliseconds() return now end
function GetSlotBoundId(_,category) return category==1 and 101 or 30366 end
function GetSlotName(_,category) return category==1 and "Meteor" or "Power Overload" end
function GetSlotTexture(_,category) return category==1 and "native/meteor.dds" or "native/power.dds" end
function GetSlotAbilityCost() return 100 end
function GetAbilityName(id) return "Native Ultimate "..id end
function GetAbilityIcon(id) return "native/"..id..".dds" end
function GetUnitPower() return 110 end
function GetNumBuffs() return 0 end
function IsSlotToggled() return false end
ZO_SavedVars={NewAccountWide=function(_,name,_,_,defaults) local copy={};for key,value in pairs(defaults) do copy[key]=value end;return copy end}
local attached=0
AlphaSquadUI={Modules={},Settings={},Layout={IsMoving=function() return false end,
 GetDimensions=function(module,w,h) return module.sv.hudWidth or w,module.sv.hudHeight or h end,
 GetScale=function(module) return module.sv.scale/100 end,Attach=function() attached=attached+1 end}}
AlphaSquadUI.Preferences={sv={language="en"},Initialize=function() end,
 Open=function(_,name,namespace,defaults) return ZO_SavedVars:NewAccountWide(name,1,namespace,defaults) end}
assert(loadfile("AlphaSquadUI/Core/Localization.lua"))()
assert(loadfile("AlphaSquadUI/Localization/fr.lua"))()
assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTTracker.lua"))()
assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTOverload.lua"))()
assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTTrackerUI.lua"))()
local ULT=AlphaSquadUI.Modules.ULTTracker
local nativeAccesses=0
local function NativeAccess()
 nativeAccesses=nativeAccesses+1;error("Personal HUD initialization must not access native action-bar controls")
end
ZO_ActionBar1={}
ActionButton8=setmetatable({},{__index=NativeAccess})
ActionBarTimer8=setmetatable({},{__index=NativeAccess})
SecurePostHook=NativeAccess
ULT:Initialize();ULT.uiObscured=false;ULT:Refresh("initial")
check(nativeAccesses==0,"Initialization and first render leave native action-bar presentation fully independent")
check(windows==1 and attached==1,"ULT and specialized Overload create and attach exactly one personal HUD")
check(not ULT.window.cards.primary:IsHidden() and not ULT.window.cards.backup:IsHidden(),"Both native weapon ultimates remain visible even with Overload on the other bar")
check(ULT.window.width==316 and ULT.window.height==48,"Design 2 starts with two compact horizontal minirows")
local first=ULT.window.cards.primary
check(first.icon.width==40 and first.valueLabel.x>first.iconBorder.x+first.iconBorder.width,
    "The approved minirow puts its numeric value to the right of a native 40px icon")
check(first.valueLabel.text=="110 / 100" and ULT.window.cards.backup.valueLabel.text=="110",
    "Ordinary Ultimates show the actual pool and native cost; Overload shows only the raw pool")
check(first.valueLabel.x+first.valueLabel.width<=first.width and first.statusLabel.y+first.statusLabel.height<=first.height,
    "Default numeric and status columns remain inside the row")
check(first.valueLabel.maxLines==1 and first.valueLabel.wrapMode==TEXT_WRAP_MODE_ELLIPSIS
    and first.statusLabel.maxLines==1 and first.statusLabel.wrapMode==TEXT_WRAP_MODE_ELLIPSIS,
    "Both text lines are bounded even with long translations or unusual native values")
local overloadCard=ULT.window.cards.backup
check(not overloadCard.reserveMarker.hidden and math.abs(overloadCard.reserveMarker.x-overloadCard.progressBG.width*0.4)<0.001,
    "The Overload reserve tick marks 160 of the configured 400-point reminder")
ULT.sv.hudWidth=152;ULT.sv.hudHeight=80;ULT:RefreshHUD()
check(ULT.window.width==316 and first.valueLabel.width>=86 and first.statusLabel.width>=86,
    "A saved narrow legacy layout expands to readable numeric and localized status columns")
ULT.sv.hudWidth=nil;ULT.sv.hudHeight=nil;ULT:RefreshHUD()
check(not ULT.window.bg and not ULT.window.brand and not ULT.window.cards.primary.nameLabel,"The gameplay HUD has no panel background, branding or skill names")
check(not ULT.window.cards.primary.activeArrow.hidden and ULT.window.cards.backup.activeArrow.hidden,"The green arrow identifies the active native weapon bar")
check(first.activeArrow.texture=="EsoUI/Art/Buttons/rightArrow_up.dds"
    and first.activeArrow.width==16 and first.activeArrow.height==24,
    "The active bar uses one larger native arrow texture instead of pixel scanlines")
check(not controls.AlphaSquadULTTracker_primary_Arrow0 and not controls.AlphaSquadULTTracker_backup_Arrow0,
    "The smoother marker avoids eighteen extra line controls")
check(first.iconBorder.x-first.activeArrow.width-4>=0
    and first.valueLabel.x>=first.iconBorder.x+first.iconBorder.width,
    "The larger marker fits inside the row without overlapping the icon or value")
check(ULT.window.cards.primary.alpha==1 and ULT.window.cards.backup.alpha==0.52,"The inactive weapon icon is visibly dimmed")
activeCategory=HOTBAR_CATEGORY_BACKUP;ULT:Refresh("bar swap")
check(ULT.window.cards.primary.activeArrow.hidden and not ULT.window.cards.backup.activeArrow.hidden and ULT.window.cards.backup.alpha==1,"Swapping bars moves the arrow and full opacity together")
activeCategory=HOTBAR_CATEGORY_PRIMARY;ULT:Refresh("bar swap")
check(ULT.window.cards.backup.icon.texture=="native/power.dds","The displayed icon is the exact native slot texture")
local originalX,originalY=ULT.sv.x,ULT.sv.y
ULT:RefreshHUD()
check(not ULT.window.cards.primary:IsHidden() and not ULT.window.cards.backup:IsHidden(),"Both mode displays ordinary and Overload Ultimates together")
ULT.sv.hudWidth=900;ULT.sv.hudHeight=200;ULT:RefreshHUD()
check(ULT.window.width==900 and ULT.window.height==200,"The personal renderer consumes saved edge dimensions")
check(ULT.window.cards.primary.x<ULT.window.cards.backup.x and ULT.window.cards.primary.y==ULT.window.cards.backup.y,"Wide Both mode lays the two cards side by side")
ULT.sv.hudWidth=400;ULT.sv.hudHeight=300;ULT:RefreshHUD()
check(ULT.window.cards.primary.x<ULT.window.cards.backup.x and ULT.window.height==300,"Narrowing the horizontal template never switches orientation or doubles its height")
ULT:SetLayoutOrientation("vertical")
check(ULT.window.cards.primary.y<ULT.window.cards.backup.y and ULT.window.cards.primary.x==ULT.window.cards.backup.x,"The explicit vertical template stacks both cards")
check(ULT.window.width==152 and ULT.window.height==108,"The vertical default retains two compact minirows")
ULT.sv.hudWidth=224;ULT.sv.hudHeight=410;ULT:RefreshHUD()
ULT:SetLayoutOrientation("horizontal")
ULT:SetLayoutOrientation("vertical")
check(ULT.window.width==224 and ULT.window.height==410,"Each orientation restores its own saved dimensions")
for _,card in pairs(ULT.window.cards) do
 check(card.icon.width==card.icon.height and card.iconBorder.width==card.iconBorder.height,"Resize preserves square native icons and frames")
 check(card.progress.width<=card.progressBG.width,"Progress remains inside its resized background")
 check(card.icon.width<=52 and card.valueLabel.x+card.valueLabel.width<=card.width,
     "Growing a row preserves compact icons and bounded right-side text")
end
check(ULT.sv.x==originalX and ULT.sv.y==originalY,"Bar-mode and dimension changes preserve the shared anchor")
ULT.sv.scale=125;ULT:ApplyAppearance()
check(ULT.window.scale==1.25,"Corner scaling uses the shared placement scale")
ULT.Overload:SetOption("enabled",false)
check(not ULT.window.cards.primary:IsHidden() and not ULT.window.cards.backup:IsHidden(),"Disabling specialization preserves both native weapons in the same HUD")
check(windows==1,"Switching modes never creates another window")
-- Exercise the actual placement controller, not only renderer helper calls.
assert(loadfile("AlphaSquadUI/Core/Layout.lua"))()
local Layout=AlphaSquadUI.Layout
function GetUIMousePosition() return 100,200 end
ULT:SetLayoutOrientation("horizontal");ULT.sv.hudWidth=400;ULT.sv.hudHeight=300;ULT.sv.scale=100;ULT:RefreshHUD()
check(Layout.Start() and Layout.IsMoving(ULT),"The real placement controller selects the unified personal HUD")
Layout.AdjustSelected("scale",25)
check(ULT.window:GetScale()==1.25,"Central scale controls repaint the personal HUD immediately")
Layout.AdjustSelected("opacity",-5)
check(ULT.sv.opacity==92,"Transparent personal HUD has no irrelevant background opacity adjustment")
local handle=Layout.attachments[ULT][5]
check(Layout.BeginResize(ULT,1,1,handle),"The real corner handle begins a proportional resize")
Layout.UpdateResize(180,260)
check(ULT.window:GetScale()>1.25 and ULT.window:GetScale()==ULT.sv.scale/100,"Corner dragging updates the actual personal scale without waiting for a power event")
Layout.EndResize()
check(handle.handlers.OnUpdate==nil,"Releasing the corner removes its pointer callback")
ULT.sv.hudWidth=400;ULT.sv.hudHeight=142;ULT.sv.trackMode="both";GuiRoot:SetDimensions(500,200)
ULT:ApplyLayout()
check(ULT.window:GetHeight()<=180.01,"Small-screen fitting uses native rendered dimensions exactly once")
Layout.Finish()
GuiRoot:SetDimensions(1920,1080)
ULT:RefreshHUD();ULT:SetLayoutOrientation("horizontal")
ULT.sv.hudWidth=640;ULT.sv.hudHeight=130;ULT.sv.scale=150;ULT:RefreshHUD()
local renderedWidth=ULT.window:GetWidth()
for _=1,8 do ULT:RefreshHUD() end
check(math.abs(ULT.window:GetWidth()-renderedWidth)<0.001,"Repeated refreshes do not double-apply native scale or oscillate")
local requestedX,requestedY=ULT.sv.x,ULT.sv.y
ULT.sv.x,ULT.sv.y=1200,720;ULT:ApplyPosition()
GuiRoot:SetDimensions(720,420);ULT:RefreshHUD()
check(ULT.sv.x==1200 and ULT.sv.y==720,"Automatic viewport fitting does not overwrite the saved personal anchor")
check(ULT.window:GetLeft()+ULT.window:GetWidth()<=720.01 and ULT.window:GetTop()+ULT.window:GetHeight()<=420.01,"Native scaled personal bounds fit the smaller viewport without a second scale multiplication")
GuiRoot:SetDimensions(1920,1080);ULT:ApplyPosition();ULT:RefreshHUD()
check(ULT.sv.x==1200 and ULT.sv.y==720,"Requested personal position survives return to a larger viewport")
ULT.sv.x,ULT.sv.y=requestedX,requestedY;ULT:ApplyPosition();ULT:RefreshHUD()
local geometryWrites=ULT.window.geometryWrites
ULT.currentUltimate=112;ULT:RefreshHUD()
check(ULT.window.geometryWrites==geometryWrites,"Resource-only updates do not rebuild unchanged geometry")
local livePrimary,liveBackup=ULT.bars.primary,ULT.bars.backup
local livePower=ULT.currentUltimate
Layout.Start()
ULT:SetLayoutPreview("mixed")
check(ULT:GetHUDBar("primary").ready and ULT:GetHUDBar("backup").state=="charging","Mixed personal preview displays ready and charging examples")
check(ULT.window.cards.primary.icon.texture=="native/40223.dds","Preview icons resolve their real ability identity through the native getter")
ULT:SetLayoutPreview("missing")
check(ULT.window.cards.primary.statusLabel.text=="EMPTY" and not ULT.window.cards.primary.icon.hidden,"Missing-slot preview uses the native empty frame with a readable state")
ULT:SetLayoutPreview("overload")
check(ULT.window.cards.primary.statusLabel.text=="ACTIVE" and ULT.window.cards.backup.statusLabel.text=="READY",
    "Overload preview pairs an active specialization with an available ordinary Ultimate")
check(ULT.window.cards.primary.valueLabel.text=="300" and ULT.window.cards.backup.valueLabel.text=="300 / 250",
    "Overload previews use the same shared Ultimate pool without contradictory specialization states")
check(ULT.bars.primary==livePrimary and ULT.bars.backup==liveBackup and ULT.currentUltimate==livePower,"Examples never replace native live bars or resource values")
ULT:SetLayoutPreview("live")
check(ULT:GetHUDBar("primary")==livePrimary,"Live preview uses the real bar without mutating it")
ULT:SetLayoutPreview("ready");Layout.Finish()
check(ULT:GetHUDBar("primary")==livePrimary,"Finishing placement immediately discards demo presentation")

assert(loadfile("AlphaSquadUI/Core/Preview.lua"))()
Layout.Start();Layout.Select(ULT)
local orientation=ULT:GetLayoutOrientation()
Layout.CycleOrientation(1)
check(ULT:GetLayoutOrientation()~=orientation,"The actual toolbar orientation action uses the module contract")
AlphaSquadUI.Preview.SetMode("missing")
check(ULT.window.cards.primary.statusLabel.text=="EMPTY","The central preview selector repaints actual personal card text immediately")
AlphaSquadUI.Preview.SetMode("ready")
check(ULT.window.cards.primary.statusLabel.text=="READY","Selecting Ready replaces missing examples without a resource event")
Layout.Finish()
check(ULT.window.cards.primary.statusLabel.text~="EMPTY" and ULT:GetHUDBar("primary")==livePrimary,"Closing the real editor restores current personal values immediately")
local cardUpdates=0
local renderCard=ULT.RefreshCard
ULT.RefreshCard=function(self,...) cardUpdates=cardUpdates+1;return renderCard(self,...) end
ULT:SetVisible(false)
cardUpdates=0
local hiddenProgressWrites=(ULT.window.cards.primary.progress.widthWrites or 0)+(ULT.window.cards.backup.progress.widthWrites or 0)
ULT:Refresh("power",173)
check(cardUpdates==0 and ULT.currentUltimate==173 and ULT.hudDirty,
    "A hidden personal HUD keeps current resources without updating its cards")
check((ULT.window.cards.primary.progress.widthWrites or 0)+(ULT.window.cards.backup.progress.widthWrites or 0)==hiddenProgressWrites,
    "Repeated hidden refreshes do not rewrite already stopped progress geometry")
ULT:SetVisible(true)
check(cardUpdates>0 and not ULT.hudDirty and not ULT.window:IsHidden(),
    "Showing the personal HUD flushes its deferred presentation")
ULT.RefreshCard=renderCard
-- Transition animations are bounded, cost-correct and dormant outside visible use.
ULT.Overload:SetOption("enabled",false)
local primary=ULT.bars.primary
primary.abilityId=101;primary.cost=100;primary.state="charging";primary.overload=false;primary.activeBar=true
ULT.currentUltimate=20;ULT:RefreshHUD()
local card=ULT.window.cards.primary
check(card.valueLabel.text=="20 / 100" and card.statusLabel.text=="" and card.progressValue==0.2,
    "Charging shows the exact reserve and native cost with a thin progress bar")
local numberWrites,statusWrites,textureWrites=card.valueLabel.textWrites,card.statusLabel.textWrites,card.icon.textureWrites
ULT:RefreshHUD()
check(card.valueLabel.textWrites==numberWrites and card.statusLabel.textWrites==statusWrites and card.icon.textureWrites==textureWrites,
    "Identical resource refreshes do not rewrite native text or skill textures")
ULT.currentUltimate=60;ULT:RefreshHUD()
check(ULT.progressRunning and ULT.window.handlers.OnUpdate~=nil and card.progressValue==0.2,"Only a rising charging value starts the short interpolation")
now=now+90;ULT:UpdateProgressAnimation()
check(card.progressValue>0.2 and card.progressValue<0.6,"Halfway progress remains strictly between old and new resource values")
now=now+100;ULT:UpdateProgressAnimation()
check(card.progressValue==0.6 and not ULT.progressRunning and ULT.window.handlers.OnUpdate==nil,"The progress callback removes itself after reaching its target")
ULT.currentUltimate=80;ULT:RefreshHUD();ULT:SetVisible(false)
check(not ULT.progressRunning and ULT.window.handlers.OnUpdate==nil,"Hiding the HUD immediately stops interpolation")
ULT:SetVisible(true);primary.state="charging";ULT.currentUltimate=99.9;ULT:RefreshHUD()
check(card.valueLabel.text=="99 / 100" and card.statusLabel.text=="","Charging cannot round to READY or the full activation cost early")
primary.cost=0;primary.state="unknown";ULT:RefreshHUD()
check(card.valueLabel.text=="99 / ?" and card.statusLabel.text=="?" and card.progressValue==0,"Unknown cost cannot produce inferred readiness or progress")
primary.cost=100;primary.state="ready";ULT.currentUltimate=250;ULT:RefreshHUD()
check(card.valueLabel.text=="250 / 100" and card.progressValue==1,
    "Ready progress saturates while the real pool remains visible above the activation cost")
primary.abilityId=0;primary.state="empty";ULT:RefreshHUD()
check(card.valueLabel.text=="—" and card.progressValue==0 and card.reserveMarker.hidden,
    "An empty native slot displays a dash without invented progress or reserve marker")
primary.abilityId=101
primary.overload=true;primary.overloadState="active";primary.cost=25;ULT:RefreshHUD()
check(card.statusLabel.text=="ACTIVE" and card.statusLabel.color[1]>card.statusLabel.color[2] and card.statusLabel.color[2]>card.statusLabel.color[3],"Active Overload uses gold status")
check(card.valueLabel.text=="250" and card.progressValue==0.625,
    "Overload progression uses its reminder scale without presenting it as an ability cost")
ULT.sv.overload.readyReminderThreshold=500;ULT:RefreshHUD()
check(card.progressValue==0.5 and math.abs(card.reserveMarker.x-card.progressBG.width*160/500)<0.001,
    "Changing the Overload reminder immediately updates both fill and reserve marker")
ULT.sv.overload.reserveAlertsEnabled=false;ULT:RefreshHUD()
check(card.reserveMarker.hidden,"Disabling reserve alerts removes the otherwise misleading warning tick")
ULT.sv.overload.reserveAlertsEnabled=true;ULT.sv.overload.reserveWarningThreshold=500;ULT.sv.overload.readyReminderThreshold=400;ULT:RefreshHUD()
check(card.reserveMarker.hidden,"A reserve beyond the displayed scale cannot create an out-of-bounds tick")
ULT.sv.overload.reserveWarningThreshold=160
primary.overloadState="ready";ULT:RefreshHUD();ULT:UpdateReadyPulse()
check(card.statusLabel.text=="READY" and card.statusLabel.color[2]>card.statusLabel.color[1] and card.readyGlow.color[2]>card.readyGlow.color[1],"Ready Overload blinks green")
primary.overloadState="warning";ULT:RefreshHUD();ULT:UpdateReadyPulse()
check(card.statusLabel.text=="STOP" and card.statusLabel.color[1]>card.statusLabel.color[2] and card.readyGlow.color[1]>card.readyGlow.color[2],"Low-reserve Overload blinks red with an action-oriented status")
primary.overloadState="off";ULT:RefreshHUD()
check(AlphaSquadUI.Localization.SetLanguage("fr") and card.statusLabel.text=="INACTIF",
    "The real language selector immediately translates the contextual Overload inactive status")
primary.overloadState="active";ULT:RefreshHUD()
check(card.statusLabel.text=="ACTIF" and card.valueLabel.text=="250",
    "French status changes preserve the shared numeric reserve")
primary.overloadState="ready";ULT:RefreshHUD()
check(card.statusLabel.text=="PRÊT","French readiness uses the existing localized status")
check(AlphaSquadUI.Localization.SetLanguage("en") and card.statusLabel.text=="READY",
    "Switching back to English repaints the current state without a resource event")
ULT:UpdateReadyPulse();ULT:ResetPulseVisuals()
check(card.statusLabel.alpha==1 and card.readyGlow.color[4]==0 and card.iconBorder.color[4]==0.9,
    "Resetting pulses restores baseline opacity and frame color even when readiness is unchanged")
ULT:SetVisible(false)
local hiddenStatusWrites=card.statusLabel.textWrites
check(AlphaSquadUI.Localization.SetLanguage("fr") and ULT.hudDirty and card.statusLabel.textWrites==hiddenStatusWrites,
    "A language change while hidden defers native text writes")
ULT:SetVisible(true)
check(card.statusLabel.text=="PRÊT" and not ULT.hudDirty and card.statusLabel.alpha==1 and card.iconBorder.color[4]==0.9,
    "Reopening the HUD immediately shows the selected language and current native state")
AlphaSquadUI.Localization.SetLanguage("en")
primary.overload=false
primary.cost=100;primary.state="ready"
local backup=ULT.bars.backup
backup.overload=false;backup.cost=250;backup.state="charging"
ULT.currentUltimate=200;ULT:RefreshHUD()
check(card.valueLabel.text=="200 / 100" and ULT.window.cards.backup.valueLabel.text=="200 / 250"
    and card.progressTarget==1 and ULT.window.cards.backup.progressTarget==0.8,
    "Both weapon rows share one raw pool while retaining their independent native activation costs")
primary.state="used";ULT.currentUltimate=0;ULT:RefreshHUD()
check(card.statusLabel.text=="USED" and card.valueLabel.text=="0 / 100" and card.progressValue==0,
    "Spending an ordinary Ultimate immediately clears its fill and shows the used state")
activeCategory=3
ULT.specialBar={abilityId=777,icon="native/temporary.dds",cost=80,state="charging",activeBar=true}
ULT.currentUltimate=60;ULT:RefreshHUD()
check(card.valueLabel.text=="60 / 80" and card.icon.texture=="native/temporary.dds" and ULT.window.cards.backup:IsHidden(),
    "A native temporary hotbar replaces both inaccessible weapon slots with its own live Ultimate")
activeCategory=HOTBAR_CATEGORY_PRIMARY;ULT.specialBar=nil;ULT:RefreshHUD()
check(not ULT.window.cards.backup:IsHidden(),"Returning from a temporary bar restores both normal rows")
for _,scale in ipairs({60,180}) do
    ULT.initialized=false
    ZO_SavedVars.NewAccountWide=function(_,name,_,_,defaults)
        if name=="AlphaSquadOverloadTrackerSavedVariables" then return {} end
        local sv={};for key,value in pairs(defaults) do sv[key]=value end
        sv.scale=scale;sv.trackMode="back";sv.unifiedUltimateVersion=1;return sv
    end
    ULT:Initialize()
    check(ULT.sv.trackMode==nil,"Initialization retires bar selection without adding a replacement setting")
    check(ULT.sv.scale==scale,"Reload normalization preserves both supported scale endpoints")
end
print(string.format("PASS: %d assertions; Lua %s. No ESO-runtime certification.",total,_VERSION))
