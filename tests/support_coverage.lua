-- Deterministic preparation/runtime regressions. These doubles are not ESO runtime validation.
local total=0
local function check(value,message) total=total+1;assert(value,message) end
local now,epoch,groupSize=10000,100000,0
local later,updates,events={},{},{}
local function copy(value) if type(value)~="table" then return value end local out={};for k,v in pairs(value) do out[k]=copy(v) end;return out end
local function countKeys(value) local count=0;for _ in pairs(value or {}) do count=count+1 end;return count end
local constants={"EVENT_ADD_ON_LOADED","EVENT_PLAYER_ACTIVATED","EVENT_PLAYER_COMBAT_STATE","EVENT_GROUP_MEMBER_JOINED",
    "EVENT_GROUP_MEMBER_LEFT","EVENT_GROUP_UPDATE","EVENT_GROUP_MEMBER_CONNECTED_STATUS","EVENT_EFFECT_CHANGED",
    "EVENT_INVENTORY_ITEM_USED","ITEM_SOUND_CATEGORY_POTION","EVENT_INVENTORY_SINGLE_SLOT_UPDATE","EVENT_ACTION_SLOT_UPDATED",
    "EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED","EVENT_ACTIVE_WEAPON_PAIR_CHANGED","EVENT_SCREEN_RESIZED","EVENT_ACTIVE_QUICKSLOT_CHANGED",
    "EVENT_CHAMPION_PURCHASE_RESULT","EVENT_SKILL_POINTS_CHANGED","EVENT_SKILL_LINE_ADDED","EVENT_SKILLS_FULL_UPDATE",
    "EVENT_SKILL_BUILD_SELECTION_UPDATED","EVENT_SKILL_RESPEC_RESULT","EVENT_ARMORY_BUILD_CHAMPION_SLOTS_MODIFIED",
    "REGISTER_FILTER_UNIT_TAG","TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT","CENTER","TOP","LEFT","RIGHT","BOTTOM",
    "TEXT_ALIGN_CENTER","TEXT_ALIGN_LEFT","TEXT_ALIGN_RIGHT","TEXT_ALIGN_TOP","TEXT_WRAP_MODE_ELLIPSIS","MOUSE_BUTTON_INDEX_LEFT",
    "CT_CONTROL","CT_TEXTURE","CT_LABEL","DT_HIGH","DL_OVERLAY","TEX_BLEND_MODE_ADD","HOTBAR_CATEGORY_PRIMARY","HOTBAR_CATEGORY_BACKUP",
    "HOTBAR_CATEGORY_CHAMPION","HOTBAR_CATEGORY_QUICKSLOT_WHEEL","BAG_WORN","LINK_STYLE_DEFAULT","ITEMTYPE_POTION","SKILL_TYPE_CLASS",
    "EQUIP_SLOT_HEAD","EQUIP_SLOT_CHEST","EQUIP_SLOT_SHOULDERS","EQUIP_SLOT_WAIST","EQUIP_SLOT_HAND","EQUIP_SLOT_LEGS","EQUIP_SLOT_FEET",
    "EQUIP_SLOT_NECK","EQUIP_SLOT_RING1","EQUIP_SLOT_RING2","EQUIP_SLOT_MAIN_HAND","EQUIP_SLOT_OFF_HAND","EQUIP_SLOT_BACKUP_MAIN",
    "EQUIP_SLOT_BACKUP_OFF","EQUIP_SLOT_POISON","EQUIP_SLOT_BACKUP_POISON","WEAPONTYPE_FIRE_STAFF","WEAPONTYPE_FROST_STAFF",
    "WEAPONTYPE_LIGHTNING_STAFF","WEAPONTYPE_HEALING_STAFF","WEAPONTYPE_BOW","WEAPONTYPE_TWO_HANDED_SWORD",
    "WEAPONTYPE_TWO_HANDED_AXE","WEAPONTYPE_TWO_HANDED_HAMMER","BUFF_TYPE_MAJOR_COURAGE","BUFF_TYPE_MINOR_FORCE",
    "LFG_ROLE_DPS","LFG_ROLE_HEAL","LFG_ROLE_TANK","LFG_ROLE_INVALID","EVENT_PLAYER_DEACTIVATED"}
for i,k in ipairs(constants) do _G[k]=i end
ACTION_BAR_ULTIMATE_SLOT_INDEX=7
SCENE_SHOWING=1;SCENE_SHOWN=2
HUD_SCENE={GetState=function() return SCENE_SHOWN end,RegisterCallback=function() end}
local function Control()
    local c={width=410,height=100,x=0,y=0,scale=1,hidden=false,handlers={},children={}}
    function c:SetDimensions(w,h) self.width=w;self.height=h end
    function c:GetName() return self.name or "TestControl" end
    function c:GetParent() return self.parent end
    function c:GetNamedChild(name) if not self.children[name] then local child=Control();child.parent=self;self.children[name]=child end;return self.children[name] end
    function c:GetBottom() return self.y+self.height*self.scale end
    function c:GetRight() return self.x+self.width*self.scale end
    function c:GetWidth() return self.width end
    function c:GetHeight() return self.height end
    function c:SetWidth(w) self.width=w end
    function c:SetHeight(h) self.height=h end
    function c:SetScale(s) self.scale=s end
    function c:GetScale() return self.scale end
    function c:SetAnchor(_,_,_,x,y) self.x=x or 0;self.y=y or 0 end
    function c:GetLeft() return self.x end
    function c:GetTop() return self.y end
    function c:SetHidden(h) self.hidden=h end
    function c:IsHidden() return self.hidden end
    function c:SetText(t) self.text=t end
    function c:GetTextHeight() return math.max(20,math.ceil(#tostring(self.text or "")/math.max(1,self.width/8))*20) end
    function c:GetTextWidth() return #tostring(self.text or "")*8 end
    function c:SetHandler(name,fn) self.handlers[name]=fn end
    setmetatable(c,{__index=function(_,key)
        if key:match('^Set') or key:match('^Clear') or key:match('^Start') or key:match('^Stop') then return function() end end
        return nil
    end})
    return c
end
GuiRoot=Control();GuiRoot:SetDimensions(1920,1080)
WINDOW_MANAGER={CreateControl=function(_,name) local c=Control();c.name=name;if name then _G[name]=c end;return c end,CreateTopLevelWindow=function(_,name) local c=Control();c.name=name;if name then _G[name]=c end;return c end}
EVENT_MANAGER={RegisterForEvent=function(_,name,event,fn) events[name]={event=event,fn=fn} end,
    UnregisterForEvent=function(_,name) events[name]=nil end,AddFilterForEvent=function() end,
    RegisterForUpdate=function(_,name,ms,fn) updates[name]={ms=ms,fn=fn} end,UnregisterForUpdate=function(_,name) updates[name]=nil end}
ZO_SavedVars={NewAccountWide=function(_,_,_,_,defaults) return copy(defaults) end}
SLASH_COMMANDS={}
function zo_callLater(fn,ms) later[#later+1]={fn=fn,ms=ms} end
function zo_strformat(_,value) return value end
function d() end
function GetGameTimeMilliseconds() return now end
function GetTimeStamp() return epoch end
function GetWorldName() return "TestWorld" end
function GetGroupSize() return groupSize end
function IsUnitGrouped() return groupSize>0 end
function GetGroupUnitTagByIndex(i) return "group"..i end
function GetUnitDisplayName(tag) if tag=="player" or tag=="group1" then return "@Self" end;return "@"..tag end
function GetUnitName(tag) return tag=="player" and "Self Character" or tag end
function GetUnitZone() return "Sunspire" end
function GetUnitZoneIndex() return 1 end
function GetZoneId() return 1121 end
function GetCurrentZoneDungeonDifficulty() return 2 end
function AreUnitsEqual(a,b) return a==b or (a=="group1" and b=="player") or (b=="group1" and a=="player") end
function DoesUnitExist(tag) return tag=="player" or tag:match('^group')~=nil end
function IsUnitOnline() return true end
function IsUnitDead() return false end
function IsUnitInCombat() return false end
function IsUnitGroupLeader(tag) return tag=="player" or tag=="group1" end
local buffLists={player={}}
function GetNumBuffs(tag) return #(buffLists[tag] or {}) end
function GetUnitBuffInfo(tag,index)
    local b=(buffLists[tag] or {})[index];if not b then return end
    return b.name,0,b.ending or 99,index,b.stacks or 1,"icon",0,1,0,0,b.id,b.canClickOff==true,true
end
local activeMundusIndex
function GetUnitActiveMundusStoneBuffIndices() return activeMundusIndex end
function GetAbilityMundusStoneType(id) return id+1000 end
local buffTypes,lastBuffCaster={}
function GetAbilityBuffType(id,casterUnitTag) lastBuffCaster=casterUnitTag;return buffTypes[id] or 0 end
function GetItemLink() return "" end
function GetItemLinkSetInfo() return false end
function GetSlotBoundId() return 0 end
local selectedRole,personalRole=LFG_ROLE_DPS,LFG_ROLE_DPS
function GetGroupMemberSelectedRole() return selectedRole end
function GetSelectedLFGRole() return personalRole end
function GetUnitClassId() return 1 end
function GetUnitClass() return "Test Class" end


function WINDOW_MANAGER:CreateControlFromVirtual(name,parent,template)
    local control=self:CreateControl(name);control.parent=parent;return control
end
function WINDOW_MANAGER:GetMouseOverControl() return nil end
function ZO_Scroll_ResetToTop() end
function ZO_Scroll_UpdateScrollBar() end

-- Load the actual manifest order: this catches missing adapters and stale calls.
local manifest=assert(io.open('AlphaSquadUI/AlphaSquadUI.txt','r')):read('*a')
local seen={}
for line in manifest:gmatch('[^\r\n]+') do
    if line:match('^Core/') or line:match('^Modules/SupportCoverage/.*%.lua$') then
        check(not seen[line],'Duplicate manifest path: '..line);seen[line]=true
        assert(loadfile('AlphaSquadUI/'..line))()
    end
end
local SC=AlphaSquadUI.Modules.SupportCoverage
SC:Initialize()
check(SC.loading and SC.localSnapshot==nil and not SC:NeedsBuildData(),
    'Initial load suspends native scans until player activation')
SC:Refresh('still loading')
check(SC.localSnapshot==nil,'An initial refresh cannot capture uncommitted loading-screen equipment')
events.AlphaSquadUI_SupportCoverage_Activated.fn()
-- Execute startup's deferred bootstrap once before measuring individual events.
-- Sharing now defaults ON and intentionally schedules one initial build scan.
local startupIndex=1
while startupIndex<=#later do
    assert(startupIndex<=64,'Startup cannot create an unbounded deferred queue')
    later[startupIndex].fn();startupIndex=startupIndex+1
end
later={}
check(SC.initialized,'Initialization works without optional libraries')
check(SC.sv.activeProfile=='trial','New installs default to trial preparation')
check(SC.sv.shareData and SC.sv.experimentalSharing,'Fresh installation enables the build-sharing preference')
check(AlphaSquadUI.Preferences.sv.buildSharing==true and AlphaSquadUI.Preferences.sv.sharingDefaultsVersion==1,'Bootstrap records the account-wide sharing default once')
check(SC.share and SC.share.available==false and SC.share.protocol==nil,'Missing optional transport cannot be mistaken for active exchange')
check(SC.sv.enabled and SC.sv.visible and SC.sv.locked,'Fresh tracking is enabled while normal gameplay remains locked')
check(not SC.StartPull and not SC.FinalizePull,'Pull collection is absent from runtime')
check(not updates.AlphaSquadUI_SupportCoverage_Live,'No live combat sampling loop')
check(not SLASH_COMMANDS['/asreport'],'No report command')
SC:Refresh('initial test')
check(SC.localSnapshot~=nil,'Local scanner initializes')
check(SC.coverage.ready==false,'Unavailable requirements cannot become ready')
check(SC.coverage.unknownCount>0,'Incomplete roster has explicit unknown source evidence')
check(SC.coverage.readinessUnknownCount>0,'Unavailable food and glyph checks are unknown')
check(SC.coverage.coveredCount+SC.coverage.missingCount==SC.coverage.requiredCount,'All selected requirements are evaluated')
check(type(SLASH_COMMANDS['/assupport'])=='function','Support commands are registered')

-- Each context persists its own tracking switches, including false.
SC:SetEffectTracking('major_courage',false)
check(not SC:IsEffectTracked('major_courage'),'Tracking OFF removes effect from active evaluation')
SC:SetActiveProfile('dungeon');SC:SetEffectTracking('major_courage',true)
check(SC:IsEffectTracked('major_courage'),'Dungeon context has its own selection')
SC:SetActiveProfile('trial')
check(not SC:IsEffectTracked('major_courage'),'Trial OFF survives profile round-trip')
check(SC:SetEffectTracking('not_a_catalog_key',true)==false,'Unknown effect cannot enter selections')
SC:SetEffectTracking('major_courage',true)

-- Lightweight changes do not rescan every equipped item.
SC.scanDirty=false
local originalScan=SC.ScanLocalPlayer
local scans=0
SC.ScanLocalPlayer=function(self) scans=scans+1;return originalScan(self) end
events.AlphaSquadUI_SupportCoverage_Quickslot.fn();later[#later].fn()
check(not SC.scanDirty and scans==0,'Quickslot change refreshes readiness only')
events.AlphaSquadUI_SupportCoverage_WeaponPair.fn();later[#later].fn()
check(scans==0,'Weapon swapping uses already-scanned front/back equipment')
SC:OnCombatState(true)
check(SC.inCombat and not updates.AlphaSquadUI_SupportCoverage_Live,'Combat sets a pause flag without a loop')
SC:MarkScanDirty('changed in combat');later[#later].fn()
check(scans==0 and SC.scanDirty,'Heavy scans defer until combat ends')
SC:OnCombatState(false);later[#later].fn()
check(scans==1 and not SC.scanDirty,'One deferred scan runs after combat')
SC.ScanLocalPlayer=originalScan

-- Exact source owners, no role-based suppression, offline/dead owners excluded.
local function Player(name,source)
    return {key=name,displayName=name,dataQuality='ASUI',capabilitiesComplete=true,connected=true,dead=false,
        capabilities={major_courage={sources={[source]=true}}},food={verified=true,active=true},
        equipment={glyphs={verified=true,armorMissing=0}},unitTag='player'}
end
local first,second=Player('@A','Spell Power Cure'),Player('@B','Vestment of Olorime')
SC.roster={first,second};SC.byKey={['@A']=first,['@B']=second}
local coverage=SC:EvaluateCoverage('duplicates')
check(#coverage.duplicates.major_courage==2,'Duplicates list every source holder')
check(coverage.duplicates.major_courage[1]=='@A' and coverage.duplicates.major_courage[2]=='@B','Duplicate order is deterministic')
local sources=SC.UI.PlayerSources(first,'major_courage')
check(sources:find('Spell Power Cure',1,true)~=nil,'Player tooltip names actual source')
first.connected=false;second.dead=true
check(#SC:GetCapabilityOwners('major_courage')==0,'Offline/dead players cannot cover a requirement')
check(not SC:EvaluateCoverage('unavailable').ready,'Unavailable players prevent READY')
first.connected=true;second.dead=false

-- A personal buff on a single member is not full group coverage.
SC:SetEffectTracking('minor_slayer',true)
first.capabilities.minor_slayer={sources={['Trial three-piece set']=true}}
SC.roster={first,second};SC.byKey={['@A']=first,['@B']=second}
coverage=SC:EvaluateCoverage('personal buff')
local personal
for _,row in ipairs(coverage.entries) do if row.key=='minor_slayer' then personal=row end end
check(personal and personal.status~='covered','Personal buff requires every relevant player')
second.capabilities.minor_slayer={sources={['Trial three-piece set']=true}}
coverage=SC:EvaluateCoverage('all personal')
for _,row in ipairs(coverage.entries) do if row.key=='minor_slayer' then personal=row end end
check(personal.status=='covered','Personal buff on all members can be covered')

-- Missing food is different from unreadable food; glyphs are optional.
first.food={verified=true,active=false};second.food={verified=false}
coverage=SC:EvaluateCoverage('food')
check(#coverage.foodMissing==1 and coverage.foodMissing[1]=='@A','Confirmed missing food names the player')
check(coverage.readinessUnknownCount>0,'Unreadable food remains unknown')
SC.sv.checkFoodPresence=false
check(#SC:EvaluateCoverage('food off').foodMissing==0,'Food check can be disabled')
SC.sv.checkFoodPresence=true

-- A summary that expires must not leave private equipment/skills visible.
groupSize=2;now=100000
SC.peerData['@group2']={displayName='@group2',characterName='group2',unitTag='group2',scannedAt=1,
    dataQuality='ASUI',buildVerified=true,capabilities={major_courage={sources={Old=true}}},
    equipment={items={{name='Old equipment'}}},skills={primary={{name='Old skill'}}},masteries={selected={{name='Old mastery'}}}}
SC:BuildRoster()
local stale=SC.byKey['@group2']
check(stale and stale.dataQuality=='STALE','Old shared snapshot is marked stale')
check(not stale.equipment and not stale.skills and not stale.masteries,'All private build fields expire together')
check(not next(stale.capabilities),'Expired capability is not credited')
SC.peerData['@group2'].characterName='Previous character'
SC:BuildRoster()
check(SC.peerData['@group2']==nil,'Character change cannot inherit old account build')
SC.peerData['@left']={};SC:BuildRoster()
check(not SC.peerData['@left'],'Departed peers are purged')
SC.wasGrouped=true;groupSize=0;SC:CheckGroupSession()
check(not next(SC.peerData),'Disband clears remote builds')

-- Food and Mundus retain the native API tuple positions.
buffLists.player={{name='Long provisioning buff',id=777,ending=4000,canClickOff=true}}
local food=SC:ScanFood('player')
check(food.abilityId==777 and food.active and not food.verified,'Food heuristic is not mistaken for exact food evidence')
activeMundusIndex=1
local mundus=SC:ScanMundus()
check(mundus.known and mundus.ids[1]==777,'Mundus scan uses abilityId, not canClickOff')
buffLists.player={};activeMundusIndex=nil

-- Disable/show cycles do not restart hidden gameplay work or networking.
SC:SetEnabled(false)
check(not updates.AlphaSquadUI_SupportCoverage_Safety,'Disabled module unregisters safety update')
local before=scans
SC:MarkScanDirty('disabled change')
check(scans==before,'Disabled changes do not scan')
SLASH_COMMANDS['/assupport']('move')
check(not SC.sv.enabled and SC.sv.locked and SC.window:IsHidden(),'Move never enables a Dashboard-disabled module')
check(not AlphaSquadUI.Layout.active,'With every module disabled, Move leaves gameplay and settings unchanged')
SC:SetEnabled(true);SC:SetVisible(false)
SLASH_COMMANDS['/assupport']('move')
check(AlphaSquadUI.Layout.IsMoving(SC) and not SC.window:IsHidden() and not SC.sv.locked,'Common placement previews and unlocks the enabled Support HUD')
check(not SC.sv.visible,'Placement preserves the saved hidden preference')
check(updates.AlphaSquadUI_SupportCoverage_Safety.ms>=5000,'Preparation safety refresh remains bounded during placement')
SC.window.x,SC.window.y=281,397
SLASH_COMMANDS['/assupport']('lock')
check(not AlphaSquadUI.Layout.active and SC.sv.locked and SC.sv.x==281 and SC.sv.y==397,'Done saves the real dragged position and locks Support')
check(SC.window:IsHidden() and not SC.sv.visible,'Completing placement restores the hidden preference')
SC:SetVisible(true)
check(not updates.AlphaSquadUI_SupportCoverage_Live,'Move never enables combat collection')

-- Actual windows are constructed once and reused with the compact coverage grid.
SC:OpenMatrix();local matrix=SC.matrixWindow
check(matrix and not matrix:IsHidden(),'Coverage list opens')
SC:OpenInspector('BUILD')
check(SC.inspectorWindow and not SC.inspectorWindow:IsHidden(),'Build browser opens')
check(matrix:IsHidden(),'Opening builds closes coverage popup')
SC:OpenFoodCheck()
check(SC.inspectorWindow and not SC.inspectorWindow:IsHidden(),'Legacy food command opens the consolidated Builds view')
SC:OnCombatState(true)
check(SC.inspectorWindow:IsHidden(),'Combat closes the preparation inspector')
SC:OnCombatState(false)
GuiRoot:SetDimensions(1280,720);SC:ApplyAppearance();SC:ResizeInspector()
check(SC:GetEffectiveScale()>0 and SC:GetEffectiveScale()<=1.8,'Small-screen HUD scale remains bounded')
SC:OpenMatrix();check(matrix==SC.matrixWindow,'Coverage popup controls are reused')
SC:CloseMatrix()

-- Existing installations keep layout and switches while retiring saved reports.
local savedVariables,originalSavedGetter=SC.sv,ZO_SavedVars.NewAccountWide
local migrated={scale=135,width=510,opacity=80,x=123,y=456,positionSaved=true,activeProfile="full",
    profileOverrides={full={major_courage=false}},raidHistory={pulls={{}}},effectRules={major_breach={enabled=false,uptimeTarget=80}},
    roleOverrides=19}
local oldProfile=AlphaSquadUI.Preferences.entries.SupportCoverage
AlphaSquadUI.Preferences.entries.SupportCoverage=nil
ZO_SavedVars.NewAccountWide=function() return migrated end
SC:EnsureSavedVariables()
check(SC.sv.scale==135 and SC.sv.x==123 and SC.sv.y==456,'Migration preserves layout preferences')
check(SC.sv.activeProfile=='trial' and SC.sv.profileOverrides.trial.major_courage==false,'Migration preserves previous tracking OFF')
check(SC.sv.profileOverrides.trial.major_breach==false and SC.sv.profileOverrides.dungeon.major_breach==false,'Legacy effect OFF survives both new profiles')
check(SC.sv.raidHistory==nil and SC.sv.historyEnabled==false,'Retired report data is removed')
check(SC:GetRoleHint('player',{})~=nil,'Corrupt retired role override cannot break native role')
SC.sv.scale=0/0;SC.sv.width=math.huge;SC.sv.profileOverrides={trial={major_courage='yes',bad=true},[42]=true}
SC:EnsureSavedVariables()
check(SC.sv.scale==100 and SC.sv.width==410,'Non-finite saved geometry returns to valid defaults')
check(SC.sv.profileOverrides.trial.major_courage==nil and SC.sv.profileOverrides[42]==nil,'Malformed tracking values cannot enter evaluation')
ZO_SavedVars.NewAccountWide=originalSavedGetter;SC.sv=savedVariables
AlphaSquadUI.Preferences.entries.SupportCoverage=oldProfile

-- Hiding tracking cannot stop a consented sender, but loading must stop both.
groupSize=2;SC.sv.shareData=true;SC.sv.experimentalSharing=true
SC:SetEnabled(false);SC:ApplyVisibility()
check(SC.window:IsHidden() and updates.AlphaSquadUI_SupportCoverage_Safety.ms==60000,'Dashboard OFF preserves the slow sender heartbeat while hiding the HUD')
check(events.AlphaSquadUI_SupportCoverage_Inventory~=nil,'Consented sharing retains build invalidation events')
SC.sv.shareData=false;SC.sv.experimentalSharing=false;SC:UpdateRuntime();SC:ApplyVisibility()
check(not updates.AlphaSquadUI_SupportCoverage_Safety and not events.AlphaSquadUI_SupportCoverage_Inventory,'Disabling both consumers removes tracking work')
SC:SetEnabled(true);SC.sv.hideInMenus=false
check(events.AlphaSquadUI_SupportCoverage_Inventory~=nil,'Re-enabling the module restores its gameplay subscriptions')
events.AlphaSquadUI_SupportCoverage_Deactivated.fn()
SC:ApplyVisibility();local scansBeforeLoading=scans;SC:Refresh('delayed loading refresh')
check(SC.loading and SC.window:IsHidden() and not updates.AlphaSquadUI_SupportCoverage_Safety,'Loading hides the HUD and cannot restart a timer even with menu hiding off')
check(not events.AlphaSquadUI_SupportCoverage_Inventory and scans==scansBeforeLoading,'Loading unregisters scanning events and rejects an already queued refresh')
check(SC:OpenInspector()==false and SC:OpenMatrix()==false,'Preparation windows cannot open during loading')
events.AlphaSquadUI_SupportCoverage_Activated.fn();later[#later].fn()
check(not SC.loading and events.AlphaSquadUI_SupportCoverage_Inventory and SC.scanDirty,'Zone activation resumes subscriptions and marks the build for refresh')

print(string.format('Support Coverage preparation: %d assertions passed',total))
