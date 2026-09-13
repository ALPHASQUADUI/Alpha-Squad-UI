-- Deterministic tests for branch development. These doubles are not ESO runtime validation.
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
    "LFG_ROLE_DPS","LFG_ROLE_HEAL","LFG_ROLE_TANK","LFG_ROLE_INVALID"}
for i,k in ipairs(constants) do _G[k]=i end
ACTION_BAR_ULTIMATE_SLOT_INDEX=7
SCENE_SHOWING=1;SCENE_SHOWN=2
local function Control()
    local c={width=410,height=100,x=0,y=0,scale=1,hidden=false,handlers={}}
    function c:SetDimensions(w,h) self.width=w;self.height=h end
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
    function c:SetHandler(name,fn) self.handlers[name]=fn end
    setmetatable(c,{__index=function(_,key)
        if key:match('^Set') or key:match('^Clear') or key:match('^Start') or key:match('^Stop') then return function() end end
        return nil
    end})
    return c
end
GuiRoot=Control();GuiRoot:SetDimensions(1920,1080)
WINDOW_MANAGER={CreateControl=function(_,name) local c=Control();_G[name]=c;return c end,CreateTopLevelWindow=function(_,name) local c=Control();_G[name]=c;return c end}
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

-- Load the exact shipped Support Coverage sequence, plus its Core infrastructure.
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
check(SC.initialized,'Initialization completes without ESO optional libraries')
check(SC.sv.checkModes.poisons=='OFF','Poisons are optional by default')
check(SC.sv.historyLimit==20,'Default pull budget')
check(not SC.share.available,'Missing libraries do not break initialization')
SC.sv.experimentalSharing=true
SC:InitializeSharing()
check(SC.share.registrationAttempted==false,'A library that loads later can be retried explicitly')
LibGroupBroadcast={RegisterHandler=function()
    return {DeclareProtocol=function() error('simulated partial registration failure') end}
end}
SC:InitializeSharing()
check(SC.share.registrationAttempted==true and SC.share.handler==nil,
    'A partial LGB registration failure is not retried as a duplicate handler')
LibGroupBroadcast=nil;SC.share.registrationAttempted=false;SC.sv.experimentalSharing=false
check(type(SLASH_COMMANDS['/assupport'])=='function','Commands registered')
check(events.AlphaSquadUI_SupportCoverage_Quickslot.event==EVENT_ACTIVE_QUICKSLOT_CHANGED,'Native quickslot event registered')
SC.scanDirty=false
events.AlphaSquadUI_SupportCoverage_Quickslot.fn()
check(not SC.scanDirty,'Quickslot selection refreshes readiness without invalidating the full build scan')
later[#later].fn()
SC.scanDirty=true
SC:Refresh('test')
check(SC.localSnapshot~=nil,'Local snapshot built')
check(SC.coverage.ready==false,'Unknown coverage cannot be ready')
check(SC.coverage.missingCount>0,'Requirements without a reported source remain visible')
check(SC.coverage.unknownCount>0,'Unverified sources are explicit')
check(SC.coverage.readinessUnknownCount>0,'Unverified food or glyph evidence cannot silently pass readiness')
check(SC.coverage.coveredCount+SC.coverage.missingCount==SC.coverage.requiredCount,'Every requirement is covered or lacks a source')
local hasUnknownIssue=false
for _,issue in ipairs(SC.coverage.issues) do if issue.severity=='unknown' then hasUnknownIssue=true end end
check(hasUnknownIssue,'Incomplete capability evidence is presented as unknown, not a hard failure')
local availableRoster,availableByKey=SC.roster,SC.byKey
local unavailable={key='@Unavailable',displayName='@Unavailable',role='H1',dataQuality='ASUI',
    capabilitiesComplete=true,connected=false,dead=false,capabilities={major_courage={sources={Test=true}}}}
SC.roster={unavailable};SC.byKey={['@Unavailable']=unavailable}
local unavailableCoverage=SC:EvaluateCoverage('offline readiness')
local hasOfflineIssue=false
for _,issue in ipairs(unavailableCoverage.issues) do if issue.text=='@Unavailable - offline' then hasOfflineIssue=true end end
check(#SC:GetCapabilityOwners('major_courage')==0 and not unavailableCoverage.ready and hasOfflineIssue,
    'Offline players neither provide capabilities nor allow READY')
unavailable.connected,unavailable.dead=true,true
local deadCoverage=SC:EvaluateCoverage('dead readiness')
local hasDeadIssue=false
for _,issue in ipairs(deadCoverage.issues) do if issue.text=='@Unavailable - dead' then hasDeadIssue=true end end
check(#SC:GetCapabilityOwners('major_courage')==0 and not deadCoverage.ready and hasDeadIssue,
    'Dead players neither provide capabilities nor allow READY')
SC.sv.assignmentLocks.major_courage='@Unavailable'
local deadOwner,deadLocked,deadLockProblem=SC:GetAssignedOwner('major_courage',{})
check(deadOwner==unavailable and deadLocked and deadLockProblem=='LOCKED_MISSING',
    'A locked dead owner is reported as unavailable')
SC.sv.assignmentLocks.major_courage=nil
SC.roster,SC.byKey=availableRoster,availableByKey;SC:EvaluateCoverage('restore roster')
local savedProfile,savedRequirements=SC.sv.activeProfile,SC.sv.customRequirements
local savedFoodCheck,savedGlyphCheck=SC.sv.checkFoodPresence,SC.sv.checkMissingGlyphs
SC.sv.activeProfile='custom';SC.sv.customRequirements={minor_force=true}
SC.sv.checkFoodPresence=false;SC.sv.checkMissingGlyphs=false
local personalOwner={key='@Personal',displayName='@Personal',role='DD PARSE',dataQuality='ASUI',
    capabilitiesComplete=true,connected=true,dead=false,capabilities={minor_force={sources={Test=true}}}}
SC.roster={personalOwner};SC.byKey={['@Personal']=personalOwner}
local personalCoverage=SC:EvaluateCoverage('personal critical coverage')
check(personalCoverage.coveredCount==1 and personalCoverage.critical.groupBonus==0,
    'Personal critical buffs never inflate the reported group critical-damage bonus')
check(SC.Catalog.effects.tremorscale.penetration==nil,
    'Dynamic Tremorscale scaling is not presented as a fixed penetration contribution')
SC.sv.activeProfile,SC.sv.customRequirements=savedProfile,savedRequirements
SC.sv.checkFoodPresence,SC.sv.checkMissingGlyphs=savedFoodCheck,savedGlyphCheck
SC.roster,SC.byKey=availableRoster,availableByKey;SC:EvaluateCoverage('restore roster after personal check')
SC:OnCombatState(true)
check(SC.inCombat==false and SC.pull==nil,'Solo combat does not start group pull sampling')
local savedCombatGetter=IsUnitInCombat
groupSize=2
IsUnitInCombat=function(tag) return tag=='player' end
SC.inCombat=false;SC.pull=nil;SC.scanDirty=false
SC:Refresh('group formed during combat')
check(SC.inCombat==true and SC.pull~=nil and updates.AlphaSquadUI_SupportCoverage_Live~=nil,
    'Forming a group during an existing combat starts pull collection without a second combat event')
SC:SetLiveUpdateActive(false);SC.inCombat=false;SC.pull=nil;groupSize=0;IsUnitInCombat=savedCombatGetter
local originalOnline,originalCombat,originalFinalize,originalRefresh=IsUnitOnline,IsUnitInCombat,SC.FinalizePull,SC.Refresh
local finalizedOfflineGroup=false
groupSize=2
IsUnitOnline=function(tag) return tag~='group2' end
IsUnitInCombat=function(tag) return tag=='group2' end
SC.FinalizePull=function() finalizedOfflineGroup=true end
SC.Refresh=function() end
SC.inCombat=true
SC:OnCombatState(false)
later[#later].fn()
check(finalizedOfflineGroup and not SC.inCombat,'A disconnected member with stale combat state cannot keep a pull open')
IsUnitOnline,IsUnitInCombat,SC.FinalizePull,SC.Refresh=originalOnline,originalCombat,originalFinalize,originalRefresh
groupSize=0;SC.pull=nil
local shareSnapshot=SC.ShareLocalSnapshot
local deferredReason
SC.ShareLocalSnapshot=function(_,reason) deferredReason=reason;return true end
SC.inCombat=true;SC.scanDirty=true;SC:Refresh('combat build change')
check(SC.buildSharePending==true and deferredReason==nil,'Combat build changes defer network sharing')
SC.inCombat=false;SC:Refresh('combat ended')
check(deferredReason~=nil and SC.buildSharePending==false,'Deferred build state shares once out of combat')
SC.ShareLocalSnapshot=shareSnapshot
buffLists.player={{name='Long provisioning buff',id=777,ending=4000,canClickOff=true}}
local fallbackFood=SC:ScanFood('player')
check(fallbackFood.active and fallbackFood.abilityId==777 and not fallbackFood.verified,'Food fallback receives the complete native buff tuple')
buffLists.player={}
local savedCurrentQuickslot,savedSlotItemLink,savedItemLinkType=GetCurrentQuickslot,GetSlotItemLink,GetItemLinkItemType
GetCurrentQuickslot=function() return 4 end
GetSlotItemLink=function() return '|H1:item:non-potion|h|h' end
GetItemLinkItemType=function() return ITEMTYPE_POTION+1 end
local nonPotion=SC:ScanPotion()
check(nonPotion.selectionKnown and not nonPotion.known and nonPotion.evidence=='SELECTED_NON_POTION',
    'A selected non-potion is verified as an invalid potion selection')
check(SC.Audit.Value({potion=nonPotion},'potion')=='NONE',
    'A verified non-potion mismatches a required potion instead of remaining unknown')
GetSlotItemLink=function(_,category)
    if category==HOTBAR_CATEGORY_QUICKSLOT_WHEEL then return '' end
    return '|H1:item:wrong-hotbar-fallback|h|h'
end
local emptyPotion=SC:ScanPotion()
check(emptyPotion.selectionKnown and not emptyPotion.known and emptyPotion.evidence=='EMPTY_QUICKSLOT',
    'An empty quickslot is verified without reading an unrelated default hotbar')
GetCurrentQuickslot=function() return 0/0 end
check(not SC:ScanPotion().selectionKnown,'A non-finite quickslot index is rejected before reading the action bar')
GetCurrentQuickslot,GetSlotItemLink,GetItemLinkItemType=savedCurrentQuickslot,savedSlotItemLink,savedItemLinkType
local savedChampionRange,savedBoundId=GetAssignableChampionBarStartAndEndSlots,GetSlotBoundId
GetAssignableChampionBarStartAndEndSlots=function() return 0/0,math.huge end
GetSlotBoundId=function() return 0 end
local malformedChampion=SC:ScanSkills()
check(not malformedChampion.championKnown and #malformedChampion.champion==0,
    'Malformed Champion slot bounds cannot create an unbounded scan')
GetAssignableChampionBarStartAndEndSlots,GetSlotBoundId=savedChampionRange,savedBoundId
local nativeSetCatalog=true
for _,source in ipairs(SC.Catalog.setSources) do
    if type(source.setId)~='number' or source.setId<=0 or source.setId%1~=0 then nativeSetCatalog=false;break end
end
check(nativeSetCatalog,'Every shipped set capability has a language-independent native ID')
local nativeSkill=SC.Catalog:MatchSkill(40223,'Nom localise sans correspondance anglaise')
check(nativeSkill.major_force==true,'Native skill IDs match independently of the client language')
local morphSkill=SC.Catalog:MatchSkill(85855,'Autre nom localise')
check(morphSkill.major_savagery_prophecy==true,'Skill morph IDs retain their support capability')
local savedEffectiveId,savedSlotName=GetEffectiveAbilityIdForAbilityOnHotbar,GetSlotName
GetSlotBoundId=function(slot,category)
    if slot==3 and category==HOTBAR_CATEGORY_PRIMARY then return 40223 end
    return 0
end
GetEffectiveAbilityIdForAbilityOnHotbar=function() return 999999 end
GetSlotName=function() return 'Nom de remplacement inconnu' end
local overriddenSkill=SC:ScanSkills()
check(overriddenSkill.primary[1].boundAbilityId==40223 and overriddenSkill.primary[1].abilityId==999999,
    'Skill scans preserve both bound and effective hotbar identities')
check(overriddenSkill.capabilities.major_force~=nil,
    'A localized hotbar override cannot hide the capability of its bound skill')
check(SC.Audit.Value({skills=overriddenSkill},'skills'):find('primary:3:40223',1,true)~=nil,
    'Build signatures use the stable bound skill instead of a transient effective override')
GetSlotBoundId,GetEffectiveAbilityIdForAbilityOnHotbar,GetSlotName=savedBoundId,savedEffectiveId,savedSlotName
local savedAbilityName=GetAbilityName
GetAbilityName=function(id) if id==40094 then return 'Priere de combat localisee' end;return '' end
local localizedSkill=SC.Catalog:MatchSkill(999,'Priere de combat localisee')
check(localizedSkill.minor_berserk and localizedSkill.minor_resolve,
    'Runtime-localized skill names match hotbar overrides with unfamiliar IDs')
GetAbilityName=savedAbilityName

local function MasterySkill(id,name,rank)
    local progression={GetAbilityId=function() return id end,GetName=function() return name end}
    return {IsPurchased=function() return true end,GetCurrentProgressionData=function() return progression end,
        GetCurrentRank=function() return rank end}
end
local prerequisite=MasterySkill(85879,'Don de la nature',2)
local selectedMastery=MasterySkill(263523,'Moisson genereuse',1)
local function MasteryLine(index,isMastery,skills)
    return {GetIndices=function() return SKILL_TYPE_CLASS,index end,GetClassId=function() return 1 end,
        SkillIterator=function()
            local position=0
            return function() position=position+1;if skills[position] then return position,skills[position] end end
        end,isMastery=isMastery}
end
local masteryLines={
    MasteryLine(1,false,{prerequisite}),MasteryLine(2,false,{}),MasteryLine(3,false,{}),
    MasteryLine(4,true,{selectedMastery}),
}
local classType={SkillLineIterator=function()
    local position=0
    return function() position=position+1;if masteryLines[position] then return position,masteryLines[position] end end
end}
local savedSkillsManager,savedDynamicInfo=SKILLS_DATA_MANAGER,GetSkillLineDynamicInfo
local savedAllMaxed=HasMaxRankInAllClassSkillLines
SKILLS_DATA_MANAGER={GetSkillTypeData=function() return classType end}
GetSkillLineDynamicInfo=function(_,index)
    local line=masteryLines[index]
    return line.isMastery and 1 or 50,nil,true,nil,nil,nil,line.isMastery
end
HasMaxRankInAllClassSkillLines=nil
local masteryScan=SC:ScanClassMasteries()
check(masteryScan.known and masteryScan.eligible and masteryScan.capabilities.major_heroism~=nil,
    'Localized U50 masteries and prerequisites match through native ability IDs')
check(masteryScan.capabilities.major_heroism.evidence=='SELECTED_MASTERY_ID'
    and SC.Catalog.effects.evasive_trance.label=="Cutthroat's Focus",
    'Live U50 mastery identities replace pre-release names without changing the wire key')
prerequisite.GetCurrentRank=function() return 1 end
check(SC:ScanClassMasteries().capabilities.major_heroism==nil,
    'A selected mastery cannot claim a rank-two prerequisite at rank one')
SKILLS_DATA_MANAGER,GetSkillLineDynamicInfo,HasMaxRankInAllClassSkillLines=savedSkillsManager,savedDynamicInfo,savedAllMaxed
SC:RebuildEffectIndex()
check(SC.effectIdIndex[134340]=='stagger' and SC.effectNameIndex.stagger=='stagger',
    'Heat Shock uses its U50 effect ID while retaining the legacy Stagger alias')
buffTypes[778]=BUFF_TYPE_MAJOR_COURAGE;buffLists.player={{name='Localized native buff',id=778}}
local nativeEffects=SC:ObserveEffectsOnUnit('player')
check(lastBuffCaster=='player' and nativeEffects.major_courage~=nil,'Native buff lookup receives the required caster unit tag')
buffLists.player={{name='Malformed native buff',id=0/0}}
local malformedEffects,malformedComplete=SC:ObserveEffectsOnUnit('player')
check(not malformedComplete and next(malformedEffects)==nil,'Non-finite native effect IDs are rejected safely')
SC:RebuildEffectIndex();buffTypes[990]=0/0;buffLists.player={{name='Unknown localized buff',id=990}}
SC:ObserveEffectsOnUnit('player')
check(SC.effectReadableKeys.minor_intellect~=true,
    'A malformed native buff-type result cannot prove absence for unrelated native effects')
buffTypes[990]=nil
buffLists.player={{name='Localized native buff',id=778,stacks=0/0}}
nativeEffects=SC:ObserveEffectsOnUnit('player')
check(nativeEffects.major_courage and nativeEffects.major_courage.stacks==nil,
    'Non-finite native stack counts remain unknown')
buffTypes[778]=nil;buffLists.player={}
activeMundusIndex=1;buffLists.player={{name='The Thief',id=779}}
local mundus=SC:ScanMundus()
check(mundus.known and mundus.ids[1]==779 and mundus.types[1]==1779,'Native Mundus scan reads the ability ID field')
activeMundusIndex=nil;buffLists.player={}
local missingBefore=SC.coverage.missingCount
SC.sv.showUnknown=false;SC:Refresh('display preference')
check(SC.coverage.missingCount==missingBefore,'Display preferences do not change coverage truth')
SC.sv.showUnknown=true

selectedRole=LFG_ROLE_TANK
check(SC:GetRoleHint('group2',{})=='MT/OT','Native selected group role maps tanks')
selectedRole=LFG_ROLE_HEAL
check(SC:GetRoleHint('group2',{})=='HEAL','Native selected group role maps healers')
selectedRole=LFG_ROLE_DPS
check(SC:GetRoleHint('group2',{})=='DD PARSE','Native selected group role maps damage dealers')
selectedRole=LFG_ROLE_INVALID;personalRole=LFG_ROLE_HEAL
check(SC:GetRoleHint('player',{})=='HEAL','Invalid solo group role falls back to the personal LFG role')
selectedRole=LFG_ROLE_DPS;personalRole=LFG_ROLE_DPS

-- Native identities work independently of client display language.
buffLists.player={{name='Localized courage name',id=901,stacks=1}}
buffTypes[901]=BUFF_TYPE_MAJOR_COURAGE
local found,complete=SC:ObserveEffectsOnUnit('player')
check(complete and found.major_courage~=nil,'Native buff-type classification')
check(found.major_courage.evidence=='NATIVE_BUFF_TYPE','Evidence retains native classification')
check(SC.effectIdIndex[901]=='major_courage','Observed ID indexed')
buffLists.player={}
local _,emptyKnown=SC:ObserveEffectsOnUnit('player')
check(emptyKnown and SC.effectReadableKeys.major_courage,'Complete local absence is known')
GetUnitActiveMundusStoneBuffIndices=function() return 1 end
buffLists.player={{name='Boon',id=902}}
check(SC:ScanMundus().ids[1]==902,'Mundus uses native buff index API')
GetUnitActiveMundusStoneBuffIndices=function() return 0 end
check(SC:ScanMundus().known and #SC:ScanMundus().ids==0,'No Mundus can be established locally')
GetUnitActiveMundusStoneBuffIndices=nil
check(not SC:ScanMundus().known,'Unavailable Mundus API stays unknown')
buffLists.player={}

-- Real elapsed time, unknown windows and independent targets.
local H=SC.History
local pull={startedAt=0,metrics={},metricCount=0,minimumMeasured=80}
H.Observe(pull,'player:a','major_courage',100,1,1000)
H.Observe(pull,'player:a','major_courage',1000,0,1600)
local rows=H.Finish(pull,2000)
check(rows[1].knownMs==1500,'Known time uses real elapsed intervals')
check(rows[1].unknownMs==500,'Unknown time is retained separately')
check(rows[1].uptime==60,'Uptime excludes unknown intervals')
check(rows[1].longestGapMs==600,'Expired evidence does not extend gap')
local two={startedAt=0,metrics={},metricCount=0}
H.Observe(two,'boss:A','major_breach',0,1,1000)
H.Observe(two,'boss:B','major_breach',0,0,1000)
local targetRows=H.Finish(two,1000)
check(#targetRows==2,'Multiple targets retain separate metrics')
check(targetRows[1].uptime~=targetRows[2].uptime,'One boss cannot cover another boss')
check(H.Assess({targetUptime=95,uptime=100,knownMs=100,minimumMeasured=80},1000)=='INSUFFICIENT_DATA','Sparse data cannot pass uptime goal')
check(H.Assess({targetUptime=90,uptime=95,knownMs=1000,minimumMeasured=80},1000)=='PASS','Measured goal passes')
check(H.Assess({targetUptime=95,uptime=90,knownMs=1000,minimumMeasured=80},1000)=='BELOW_TARGET','Measured goal mismatch')
check(H.Assess({targetUptime=0},1000)=='NOT_CONFIGURED','No forced uptime goal')
local malformedTrim={pulls={}}
for index=1,25 do malformedTrim.pulls[index]={rows={}} end
H.Trim(malformedTrim,0/0)
check(#malformedTrim.pulls==20,'A non-finite direct history limit recovers to the bounded default')

local c1='1:COMBAT:11:50, 2:COMBAT:12:50, 3:COMBAT:13:50, 4:COMBAT:14:50'
local c2='8:COMBAT:14:50, 7:COMBAT:13:50, 6:COMBAT:12:50, 5:COMBAT:11:50'
check(SC.Audit.CompareValue('champion',c1,'COMBAT')==SC.Audit.CompareValue('champion',c2,'COMBAT'),'Champion slot order is irrelevant')
check(SC.Audit.CompareValue('champion',c1,'COMBAT')~=SC.Audit.CompareValue('champion',c2:gsub('14:50','14:40'),'COMBAT'),'Committed Champion points are checked')
check(SC.Audit.CompareValue('champion','1:UNKNOWN:2:50','COMBAT')==nil,'Missing CP metadata cannot pass')
check(SC.Audit.CompareValue('champion','1:COMBAT:11:50, 1:COMBAT:12:50, 3:COMBAT:13:50, 4:COMBAT:14:50','COMBAT')==nil,
    'Duplicate Champion slots cannot satisfy a complete discipline')
local templateKey=SC:GetTemplateKey('H1')
SC.sv.buildTemplates[templateKey]={values={food='902',poisons=''}}
SC.sv.checkModes.food='REQUIRED'
local player={role='H1',displayName='@test',asui=false,food={verified=false,active=false}}
local audit=SC:EvaluateBuildAudit(player)
check(audit.unknown==1 and audit.requiredUnknown==1,'Missing remote data stays unknown, not mismatch')
player.food={verified=true,active=true,abilityId=902}
check(SC:EvaluateBuildAudit(player).rows[1].status=='PASS','Matching verified food passes')
player.food.abilityId=903
check(SC:EvaluateBuildAudit(player).rows[1].status=='MISMATCH','Wrong verified food is detected')
local savedDetailHash=SC.Details.Hash
SC.Details.Hash=function() return 1 end
check(SC:EvaluateBuildAudit(player).rows[1].status=='MISMATCH','Local exact values cannot pass through a hash collision')
SC.Details.Hash=savedDetailHash
SC.sv.checkModes.food='OFF'
check(#SC:EvaluateBuildAudit(player).rows==0,'OFF checks impose nothing')
check(not SC:CaptureExpectedBuild('UNKNOWN',player),'Unassigned role cannot establish a role template')
check(not SC:CaptureExpectedBuild('INVALID ROLE',player),'Unknown role identifiers cannot create templates')

local plannerPlayer={key='@Planner',displayName='@Planner',characterName='Planner Character',classId=1,role='H1',
    capabilities={major_courage={sources={Manual=true}}}}
for id=1,6 do
    plannerPlayer.equipment={complete=true,setList={{id=100+id,mainCount=5,backCount=5}},items={}}
    plannerPlayer.skills={known=true,primary={{slot=3,abilityId=200+id}},backup={}}
    check(SC:RememberLoadout(plannerPlayer,'Loadout '..id),'Verified planner loadout can be recorded')
end
check(#SC.sv.loadoutLibrary['@Planner']==4 and #SC:GetPlannerCandidates(plannerPlayer)==5,'Planner expansion is capped at five whole-build candidates')
check(SC:GetPlannerCandidates(plannerPlayer)[1].capabilities.major_courage==nil,'Manual capability overrides are not promoted to recorded proof')
SC.sv.loadoutLibrary['@Planner']=nil
local savedRoster,savedByKey=SC.roster,SC.byKey
local savedProfile,savedRequirements,savedLocks=SC.sv.activeProfile,SC.sv.customRequirements,SC.sv.assignmentLocks
local planningPlayer={key='@Planner',displayName='@Planner',characterName='Planner',classId=1,role='H1',connected=true,
    capabilities={major_courage={sources={Observed=true}}}}
SC.roster={planningPlayer};SC.byKey={['@Planner']=planningPlayer};SC.sv.activeProfile='custom'
SC.sv.customRequirements={major_courage=true};SC.sv.assignmentLocks={bright_harbinger='@Planner'}
local profilePlan=SC:ComputeBuildPlan()
check(profilePlan and profilePlan.lockFailures==0,'Planner ignores assignment locks outside the active profile')
SC.roster,SC.byKey=savedRoster,savedByKey
SC.sv.activeProfile,SC.sv.customRequirements,SC.sv.assignmentLocks=savedProfile,savedRequirements,savedLocks

buffLists.player={{name='The Thief',id=13940}}
GetUnitActiveMundusStoneBuffIndices=function() return 1 end
local mundus=SC:ScanMundus()
check(mundus.known and mundus.ids[1]==13940 and mundus.types[1]==14940,'Native Mundus indices provide exact identity')
GetUnitActiveMundusStoneBuffIndices=function() return end
check(SC:ScanMundus().known,'Native Mundus API can verify an empty selection')
buffLists.player={}

-- A six-recipient buff is not an unconditional twelve-person requirement.
SC.sv.effectRules.powerful_assault={}
check(SC:GetEffectRule('powerful_assault').targetCount==6,'PA defaults to six recipients')
SC.sv.effectRules.powerful_assault.targetCount=0
check(SC:GetEffectRule('powerful_assault').targetCount==nil,'Recipient count is configurable')
SC.sv.effectRules.stagger={expectedStacks=3}
check(SC:GetEffectRule('stagger').expectedStacks==3,'Stack requirements configured')

-- Mask positions remain stable after adding new catalog entries.
check(#SC.Catalog.wireV2Keys==81,'Wire v2 reserves cap4 high bits for the detail fingerprint')
SC.localSnapshot={capabilities={major_courage={},bright_harbinger={}},equipment={setList={},glyphs={
    verified=true,armorMissing=0,prismatic=0,magicka=0,stamina=0,health=0}}}
local payload=SC:BuildSharePayload()
local index
for i,key in ipairs(SC.Catalog.wireV1Keys) do if key=='major_courage' then index=i-1 end end
check(payload['cap'..(math.floor(index/24)+1)]==2^(index%24),'v1 capability mask does not shift')
check(payload.version==2,'Current builds advertise capability protocol v2')
local capabilitySnapshot=SC.localSnapshot
SC.localSnapshot={capabilities={},equipment={setList={{id=185,name='Nom de set localise'}},glyphs={verified=false}},food={}}
local localizedSetPayload=SC:BuildSharePayload()
check(localizedSetPayload.set1>0 or localizedSetPayload.set2>0,
    'Native set IDs are shared independently of the client language')
SC.localSnapshot={capabilities={},equipment={setList={{id=999999,name='spell power cure'}},glyphs={verified=false}},food={}}
local mismatchedSetPayload=SC:BuildSharePayload()
check(mismatchedSetPayload.set1==0 and mismatchedSetPayload.set2==0,
    'A known mismatched set ID cannot be reclassified from an English-looking name')
SC.localSnapshot={capabilities={},equipment={setList={{id=0,name='spell power cure'}},glyphs={verified=false}},food={}}
local fallbackSetPayload=SC:BuildSharePayload()
check(fallbackSetPayload.set1>0 or fallbackSetPayload.set2>0,
    'Set-name compatibility remains available only when no native identity exists')
SC.localSnapshot=capabilitySnapshot
local finiteSnapshot=SC.localSnapshot
SC.localSnapshot={classId=0/0,supportScore=math.huge,capabilities={},equipment={setList={},glyphs={
    armorMissing=0/0,prismatic=math.huge,magicka=-math.huge,stamina=0/0,health=math.huge}},
    food={active=true,verified=true,abilityId=0/0}}
local boundedPayload=SC:BuildSharePayload()
check(boundedPayload.classId==0 and boundedPayload.foodId==0 and boundedPayload.supportScore==0
    and boundedPayload.missingGlyphs==0 and boundedPayload.prism==0,
    'Non-finite local values cannot enter a group build payload')
SC.localSnapshot=finiteSnapshot
groupSize=3;SC.sv.experimentalSharing=true
local savedSessionReady,savedWasGrouped=SC.groupSessionReady,SC.wasGrouped
SC.groupSessionReady=true;SC.wasGrouped=false
SC.buildSharePending,SC.detailSharePending=false,false
SC:CheckGroupSession()
check(SC.buildSharePending and SC.detailSharePending,
    'Joining an already formed group queues the local summary and detail frame')
SC.groupSessionReady,SC.wasGrouped=savedSessionReady,savedWasGrouped
local pendingCallbacks=#later
SC.buildSharePending,SC.detailSharePending=false,false
events.AlphaSquadUI_SupportCoverage_Joined.fn()
check(SC.buildSharePending and SC.detailSharePending,
    'A joining member queues a fresh build summary and its matching detail frame')
while #later>pendingCallbacks do table.remove(later) end
SC.refreshPending=false
SC.buildSharePending,SC.detailSharePending=false,false
SC:OnPeerShareData('outsider',payload)
check(SC.peerData['@outsider']==nil,'Non-members cannot submit build data')
SC:OnPeerShareData('group2',payload)
check(SC.peerData['@group2'].capabilities.major_courage~=nil,'Stable capability wire decoded')
check(SC.peerData['@group2'].capabilities.bright_harbinger~=nil,'U50 mastery capability is encoded in v2')
check(SC.peerData['@group2'].equipment.glyphs.verified==true,'Build v2 transports glyph-scan completeness')
local legacy=copy(payload);legacy.version=1
for i,key in ipairs(SC.Catalog.wireV2Keys) do
    if key=='bright_harbinger' then
        local zero=i-1;local field='cap'..(math.floor(zero/24)+1)
        legacy[field]=legacy[field]-2^(zero%24)
    end
end
SC:OnPeerShareData('group2',legacy)
check(SC.peerData['@group2'].capabilities.bright_harbinger==nil,'Legacy v1 payloads do not invent appended capabilities')
check(SC.peerData['@group2'].equipment.glyphs.verified==false,'Legacy payloads cannot claim glyph-scan completeness')
SC:OnPeerShareData('group2',payload)
local buildFingerprint=math.floor(payload.cap4/512)
SC.peerData['@group2'].auditHashes={food=902};SC.peerData['@group2'].detailAt=now
SC.peerData['@group2'].detailBuildFingerprint=buildFingerprint
SC.peerData['@group2'].liveCapabilities={major_courage={}};SC.peerData['@group2'].liveUpdatedAt=now
SC:OnPeerShareData('group2',payload)
check(SC.peerData['@group2'].auditHashes.food==902,'Build updates preserve audit signatures')
check(SC.peerData['@group2'].liveCapabilities.major_courage~=nil,'Build updates preserve live fields')
local originalSnapshot=SC.localSnapshot
SC.localSnapshot={capabilities={major_courage={},bright_harbinger={}},equipment={setList={}},food={verified=true,active=true,abilityId=999}}
local changedPayload=SC:BuildSharePayload()
check(math.floor(changedPayload.cap4/512)~=buildFingerprint,'Build payload carries a changing detail fingerprint')
SC:OnPeerShareData('group2',changedPayload)
check(SC.peerData['@group2'].auditHashes==nil,'A changed build invalidates stale audit signatures immediately')
SC.localSnapshot=originalSnapshot
local bad=copy(payload);bad.cap1=-1
local previous=SC.peerData['@group2']
SC:OnPeerShareData('group2',bad)
check(SC.peerData['@group2']==previous,'Malformed masks are rejected')
bad=copy(payload);bad.role=99
local previousCapabilities=SC.peerData['@group2'].capabilities
SC:OnPeerShareData('group2',bad)
check(SC.peerData['@group2']==previous and SC.peerData['@group2'].capabilities==previousCapabilities,
    'A malformed non-mask field cannot partially update an existing peer')
SC:OnPlanData('group2',{revision=1,kind=0,key=1,ownerHash=0})
check(SC.remotePlan==nil,'Non-leader cannot overwrite the plan')
SC:OnPlanData('group1',{revision=1,kind=0,key=1,ownerHash=0})
check(SC.remotePlan==nil,'Own loopback plan ignored')
local groupLeader=IsUnitGroupLeader
IsUnitGroupLeader=function(tag) return tag=='group3' end
SC:OnPlanData('group3',{revision=7,kind=0,key=1,ownerHash=0})
SC:OnPlanData('group3',{revision=7,kind=1,key=index,ownerHash=123})
SC:OnPlanData('group3',{revision=7,kind=0,key=1,ownerHash=0})
check(SC.remotePlan.assignments.major_courage==123,'Duplicate plan markers preserve received assignments')
IsUnitGroupLeader=groupLeader
SC.sv.experimentalSharing=false
SC:OnPeerLiveData('group3',{cap1=1,cap2=0,cap3=0,cap4=0})
check(SC.peerData['@group3']==nil,'Disabled experimental receiver is silent')

local D=SC.Details
local detailSnapshot={capabilities={},equipment=nil,food={verified=true,active=true,abilityId=902}}
local text=D.Encode(detailSnapshot)
local decoded=D.Decode(text)
check(type(text)=='string' and #text<=D.MAX_BYTES and decoded.food==D.Hash('902'),'Compact signature round trip')
check(D.Decode(text:sub(1,-2))==nil,'Truncated detail payload rejected')
local corrupted=string.char(1)..text:sub(2)
check(D.Decode(corrupted)==nil,'Wrong detail format rejected')
check(D.Decode(string.rep('x',D.MAX_BYTES+1))==nil,'Detail payload bounded')

-- Persistence and protocol state reject malformed or stale input without losing compatibility.
SC.sv.buildTemplates={['']={values={}},valid={values={food='902'},hashes={}}}
SC.sv.playerTemplates={['']='valid',['@bad']=''}
SC.sv.historyLimit=0/0
SC.sv.contextProfiles={badtime={savedAt=0/0}}
SC:EnsureAuditSettings();SC:SanitizePlanningSettings()
check(SC.sv.buildTemplates['']==nil and SC.sv.playerTemplates['']==nil and SC.sv.playerTemplates['@bad']==nil,'Empty template identifiers are discarded')
check(SC.sv.historyLimit>=5 and SC.sv.historyLimit<=50,'Non-finite audit limits recover to a bounded value')
check(SC.sv.contextProfiles.badtime.savedAt==SC.sv.contextProfiles.badtime.savedAt,'Non-finite context timestamps are normalized')
SC.sv.buildTemplates.valid={values={food='902'},hashes={},createdAt=1}
SC.sv.playerTemplates={}
for i=1,300 do SC.sv.playerTemplates['@player'..i]='valid' end
SC:EnsureAuditSettings()
check(countKeys(SC.sv.playerTemplates)==256,'Recovered per-player template mappings are bounded')
SC.sv.roleOverrides={};SC.sv.manualCapabilities={};SC.sv.duplicateBackups={major_courage={}}
for i=1,100 do
    local key='@setting'..i
    SC.sv.roleOverrides[key]='H1'
    SC.sv.manualCapabilities[key]={major_courage=true}
    SC.sv.duplicateBackups.major_courage[key]=true
end
SC:SanitizePlanningSettings()
check(countKeys(SC.sv.roleOverrides)==64 and countKeys(SC.sv.manualCapabilities)==64
    and countKeys(SC.sv.duplicateBackups.major_courage)==12,
    'Recovered planning maps and per-effect backups have absolute limits')
SC.sv.roleOverrides={};SC.sv.manualCapabilities={};SC.sv.duplicateBackups={}
SC.sv.activeProfile='boss'
SC.sv.buildTemplates={
    ['boss:H1']={values={food='boss-saved'},hashes={},createdAt=1},
    ['boss:H1:@healer']={values={food='boss-player'},hashes={},createdAt=2},
    ['damage:H1']={values={food='damage-kept'},hashes={},createdAt=3},
}
SC.sv.playerTemplates={['boss:@healer']='boss:H1:@healer'}
SC.sv.profileOverrides={boss={major_courage=true},damage={minor_berserk=true}}
SC:SaveContextProfile(' Boss regression ')
local savedBossContext=SC.sv.contextProfiles['Boss regression']
check(savedBossContext and savedBossContext.buildTemplates['damage:H1']==nil,
    'A context stores only templates belonging to its active profile')
SC.sv.buildTemplates['boss:H1'].values.food='boss-changed'
SC.sv.buildTemplates['damage:H2']={values={food='damage-new'},hashes={},createdAt=4}
SC.sv.profileOverrides.damage.minor_berserk=false
check(SC:LoadContextProfile(' Boss regression '),'Trimmed context names can be loaded')
check(SC.sv.buildTemplates['boss:H1'].values.food=='boss-saved'
    and SC.sv.playerTemplates['boss:@healer']=='boss:H1:@healer',
    'Loading a context restores its profile templates and player mapping')
check(SC.sv.buildTemplates['damage:H1'].values.food=='damage-kept'
    and SC.sv.buildTemplates['damage:H2'].values.food=='damage-new'
    and SC.sv.profileOverrides.damage.minor_berserk==false,
    'Loading a context preserves templates and overrides for other profiles')
SC.sv.activeProfile='full'
SC.sv.loadoutLibrary={['@planner']={}}
for i=1,7 do
    SC.sv.loadoutLibrary['@planner'][i]={signature='build-'..i,character='Planner',classId=1,role='H1',
        capabilities={major_courage=true},savedAt=i}
end
SC:EnsureAuditSettings()
check(#SC.sv.loadoutLibrary['@planner']==4 and SC.sv.loadoutLibrary['@planner'][1].signature=='build-4'
    and SC.sv.loadoutLibrary['@planner'][4].signature=='build-7',
    'Restored planner state keeps the four newest saved alternatives')
local candidates=SC:GetPlannerCandidates({key='@planner',characterName='Planner',classId=1,role='H1',connected=true,capabilities={}})
check(#candidates==5,'Planner evaluates the current build plus at most four saved alternatives')

groupSize=3
SC.historyRestored=false;SC.sv.persistHistory=true;SC.sv.historyEnabled=true
local fingerprint=SC:GetGroupFingerprint();local counters={}
for i=1,150 do counters['encounter-'..i]=i end
SC.sv.raidHistory={version=1,fingerprint=fingerprint,savedAt=tostring(epoch-10),pulls={},counters=counters}
SC:RestoreHistorySession()
local restoredCounters=0;for _ in pairs(SC.historySession.counters) do restoredCounters=restoredCounters+1 end
check(restoredCounters==100,'Recovered encounter counters are bounded')
SC.historyRestored=false;SC.sv.raidHistory={version=1,fingerprint=fingerprint,savedAt=0/0,pulls={}}
SC:RestoreHistorySession()
check(SC.sv.raidHistory==nil,'Non-finite history timestamps are rejected safely')
SC.historyRestored=false;SC.sv.historyEnabled=false
SC.sv.raidHistory={version=1,fingerprint=fingerprint,savedAt=epoch,pulls={}}
SC:RestoreHistorySession()
check(SC.sv.raidHistory==nil,'Disabled history cannot restore an earlier raid session')
SC.sv.historyEnabled=true

SC.sv.enabled=true;SC.sv.shareData=true;SC.sv.experimentalSharing=true;SC.inCombat=false
local sent={}
SC.share.detailProtocol={Send=function(_,data,options) sent[#sent+1]={data=data,options=options};return true end,IsEnabled=function() return true end}
SC.localSnapshot=detailSnapshot
local matchingSummary=SC:BuildSharePayload()
SC:OnPeerShareData('group2',matchingSummary)
local wrongDetail=D.Encode({capabilities={},equipment=nil,food={verified=true,active=true,abilityId=903}})
SC:OnDetailData('group2',{version=D.VERSION,kind=1,revision=1,checksum=D.Checksum(wrongDetail),body=wrongDetail})
check(SC.peerData['@group2'].auditHashes==nil,'A detail frame for another build is rejected')
SC:OnDetailData('group2',{version=D.VERSION,kind=1,revision=2,checksum=D.Checksum(text),body=text})
check(SC.peerData['@group2'].auditHashes.food==D.Hash('902'),'A detail frame matching the build fingerprint is accepted')
SC.share.lastBuildFingerprint=0
local beforeUnlinkedDetail=#sent
check(not SC:QueueBuildDetails(true) and #sent==beforeUnlinkedDetail,'Details wait for their matching queued build summary')
SC.share.lastBuildFingerprint=D.Checksum(text)%D.FINGERPRINT_MODULUS+1
check(SC:QueueBuildDetails(true),'Build signature can be queued')
check(sent[#sent].options.replaceQueuedMessages==false,'Detail kinds cannot replace each other in the transport queue')
SC.pull={groupToken=epoch,meta={timestamp=epoch,zoneId=1121},potions={['@Self']={count=0,inferredCount=0,categoryMonitoring=true,cooldownMonitoring=true}}}
SC.share.lastPotionAt=-60000;SC.share.lastPotionText=nil
local beforePotion=#sent;SC:SharePotionEvidence();SC:SharePotionEvidence()
check(#sent==beforePotion+1,'Unchanged potion evidence is rate limited')
SC.pull.potions['@Self'].count=1;SC:SharePotionEvidence()
check(#sent==beforePotion+2,'Changed potion evidence is sent immediately')
local staleBody='2,0,'..tostring(epoch-1)..',1,1'
SC:OnDetailData('group2',{version=D.VERSION,kind=2,revision=1,checksum=D.Checksum(staleBody),body=staleBody})
check(not SC.peerData['@group2'].potionEvidence,'Potion evidence for another pull is rejected')
local currentBody='2,0,'..tostring(epoch)..',1,1'
SC:OnDetailData('group2',{version=D.VERSION,kind=2,revision=1,checksum=D.Checksum(currentBody),body=currentBody})
check(SC.peerData['@group2'].potionEvidence.count==2,'Potion evidence is accepted only for the active pull token')

SC.coverage={entries={}};SC.sv.roleOverrides={};SC.byKey={}
SC.lastPlanSignature=SC:GetPlanSignature();SC.share.lastPlanSentAt=now-300001;SC.share.lastPlanAttemptAt=now-5001
SC.share.planProtocol={Send=function() return true end,IsEnabled=function() return true end}
SC:MaybeBroadcastPlan()
check(SC.share.planPending==true,'Unchanged leader plans receive a bounded heartbeat')
later[#later].fn()
check(SC.share.lastPlanSentAt==now,'Successful plan heartbeat refreshes its lifetime')
SC.remotePlan={receivedAt=now-600001,assignments={}}
SC:GetMyRemoteAssignments()
check(SC.remotePlan==nil,'Remote plans expire after a missed heartbeat window')
SC.inCombat=true;SC.pull={meta={timestamp=epoch,zoneId=1121},potions={}}
SC.share.lastPullIdentityAt=-60000;SC.share.lastPullIdentityText=nil
local beforeIdentity=#sent;SC:SharePullIdentity();SC:SharePullIdentity()
check(#sent==beforeIdentity+1,'Unchanged pull identity is rate limited')
SC.inCombat=false;SC.pull=nil

-- Interface: real row geometry and no scale drift.
SC.sv.visible=true;SC.sv.enabled=true;SC.uiObscured=false;SC.sv.scale=150;SC.sv.rowHeight=48
local visibilityRefresh,refreshForVisibility=nil,SC.Refresh
SC.Refresh=function(_,reason) visibilityRefresh=reason end
SC:SetVisible(false);SC:SetVisible(true)
SC.Refresh=refreshForVisibility
check(visibilityRefresh=='visibility changed','Showing the HUD refreshes its state immediately')
SC:ApplyAppearance()
check(SC.window.rows[2].y-SC.window.rows[1].y==49,'Row-height setting changes anchors')
SC.window:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,200,200)
SC:ClampToScreen(false);local firstX=SC.window:GetLeft()
SC:ClampToScreen(false)
check(SC.window:GetLeft()==firstX,'Repeated clamping does not divide position by scale')
SC:OpenInspector('CHECKS')
check(not SC.inspectorWindow:IsHidden(),'Inspector can be opened')
check(#SC:GetInspectorRows()>12,'Optional controls paginate')
SC:CloseInspector()
check(SC.inspectorWindow:IsHidden(),'Inspector can be closed')
SC.assignmentBanner:SetHidden(false);SC.remotePlan=nil;SC.inCombat=false
SC:ShowPersonalAssignmentBanner()
check(SC.assignmentBanner:IsHidden(),'An empty remote plan clears a previous assignment banner')
SC.sv.activeProfile='progression';SC:Refresh('profile test');SC:OpenMatrix()
local matrixPlayer=SC.roster[1]
local previousFood=matrixPlayer and matrixPlayer.food
if matrixPlayer then matrixPlayer.food={active=true,verified=false};SC:RefreshMatrix() end
check(matrixPlayer and SC.matrixWindow.playerRows[1].food.text=='FOOD ?','Heuristic food is not displayed as verified')
if matrixPlayer then matrixPlayer.food=previousFood end
SC.matrixPage=2;SC:RefreshMatrix()
check(SC.matrixPage==2,'Matrix supports more than twenty requirements')
check(#SC.coverage.entries>20,'Pagination does not mutate engine coverage')
SC:CloseMatrix()
check(SC.matrixWindow:IsHidden(),'Matrix closes')

-- History retention and reopening reports.
SC.groupSessionReady=true;SC.wasGrouped=true;SC.sv.historyEnabled=true
SC.sv.checkModes.poisons='WARN'
SC.historySession={pulls={},counters={},sequence=0,generation=1}
local report={id=1,label='Lokkestiiz - Pull 1',meta={zoneName='Sunspire',bossName='Lokkestiiz'},durationMs=1000,rows=rows,potions={},subjects={},profile='boss'}
SC.historySession.pulls[1]=report
SC:OpenPullReport(report)
check(not SC.reportWindow:IsHidden(),'Report opens')
SC:ClosePullReport()
check(SC.reportWindow:IsHidden() and #SC:GetHistoryPulls()==1,'Closing does not erase history')
SC:OpenPullReport(SC:GetHistoryPulls()[1])
check(SC.reportWindow.report==report,'Accidentally closed report reopens')
SC.sv.historyLimit=5
for i=2,10 do SC.historySession.pulls[i]={rows={}} end
H.Trim(SC.historySession,5)
check(#SC.historySession.pulls==5,'Oldest pulls are evicted')
groupSize=0;SC:CheckGroupSession()
check(#SC:GetHistoryPulls()==0,'Disband clears stored pulls')
check(SC.sv.raidHistory==nil,'Disband clears persisted history')
check(SC.sv.checkModes.poisons=='WARN','History reset preserves optional checks')
check(SC.peerData['@group2']==nil,'Disband clears peer snapshots')
SC.inCombat=true;SC.pull={};SC:SetLiveUpdateActive(true)
SC:ResetHistory('Manual reset')
check(#SC:GetHistoryPulls()==0,'Manual reset is idempotent')
check(not SC.inCombat and updates.AlphaSquadUI_SupportCoverage_Live==nil,'History reset cannot leave combat sampling registered')
SC:SetEnabled(false)
check(not updates.AlphaSquadUI_SupportCoverage_Live,'Disabling stops live updates')
check(SC.window:IsHidden(),'Disabling hides HUD')


-- Actual equipment adapter: threshold, active bar and mixed Perfected family.
local equipment={}
GetItemLink=function(_,slot) return equipment[slot] and tostring(slot) or "" end
GetItemLinkName=function(link) return "Test item "..link end
GetItemLinkSetInfo=function(link)
    local item=equipment[tonumber(link)]; if not item then return false end
    return true,item.name,5,0,5,item.id,0
end
GetItemLinkWeaponType=function(link) return equipment[tonumber(link)].weapon or 0 end
GetItemLinkArmorType=function() return 1 end
GetItemLinkTraitInfo=function() return 4 end
GetItemLinkEnchantInfo=function(link)
    local item=equipment[tonumber(link)] or {}
    return item.charges==true,item.enchantName or '',item.enchantDescription or ''
end
GetItemLinkFinalEnchantId=function(link) return (equipment[tonumber(link)] or {}).enchantId or 0 end
GetItemSetUnperfectedSetId=function(id)
    if id==651 then return 648 end
    return 0
end
local function piece(slot,id,name,weapon) equipment[slot]={id=id,name=name or "Spell Power Cure",weapon=weapon} end
local localizedCourageSet='Nom de tenue localise'
piece(EQUIP_SLOT_HEAD,185,localizedCourageSet)
check(SC:ScanEquipment().capabilities.major_courage==nil,'One piece cannot provide a five-piece capability')
for _,slot in ipairs({EQUIP_SLOT_CHEST,EQUIP_SLOT_SHOULDERS,EQUIP_SLOT_WAIST}) do piece(slot,185,localizedCourageSet) end
piece(EQUIP_SLOT_MAIN_HAND,185,localizedCourageSet,0)
local gear=SC:ScanEquipment()
check(gear.setList[1].mainCount==5 and gear.setList[1].backCount==4,'Main and backup counts remain separate')
check(gear.capabilities.major_courage.mainBar and not gear.capabilities.major_courage.backBar,'Set capability retains active-bar condition')
check(gear.capabilities.major_courage.evidence=='SET_ID','Native set IDs work independently of the client language')
equipment[EQUIP_SLOT_MAIN_HAND]=nil
piece(EQUIP_SLOT_BACKUP_MAIN,185,localizedCourageSet,WEAPONTYPE_HEALING_STAFF)
check(SC:ScanEquipment().setList[1].backCount==6,'Two-handed staff counts as two pieces')
equipment={};piece(EQUIP_SLOT_HEAD,648,'Pearlescent Ward');piece(EQUIP_SLOT_CHEST,648,'Pearlescent Ward')
for _,slot in ipairs({EQUIP_SLOT_SHOULDERS,EQUIP_SLOT_WAIST,EQUIP_SLOT_HAND}) do piece(slot,651,"Perfected Pearlescent Ward") end
gear=SC:ScanEquipment()
check(#gear.setList==1 and gear.setList[1].mainCount==5,'Mixed variants count toward the same native set family')
check(gear.capabilities.pearlescent_ward~=nil,'Mixed variants can unlock a valid shared bonus')
check(#gear.setList[1].variants==2,'Variant identities remain available for inspection')
equipment={};piece(EQUIP_SLOT_HEAD,436,'Symphony of Blades')
check(SC:ScanEquipment().capabilities.symphony==nil,'One monster piece cannot provide two-piece proc')
piece(EQUIP_SLOT_SHOULDERS,436,'Symphony of Blades')
check(SC:ScanEquipment().capabilities.symphony~=nil,'Two monster pieces provide the conditional capability')
equipment={};piece(EQUIP_SLOT_HEAD,0,'Unknown Set A');piece(EQUIP_SLOT_CHEST,0,'Unknown Set B')
check(#SC:ScanEquipment().setList==2,'Unknown native set IDs do not merge unrelated sets')

equipment={};piece(EQUIP_SLOT_HEAD,800,'Plain armor');equipment[EQUIP_SLOT_HEAD].enchantId=1200
equipment[EQUIP_SLOT_HEAD].enchantName='Glyph of Health'
local enchanted=SC:ScanEquipment()
check(enchanted.items[1].hasEnchant==true,'Armor enchants do not depend on weapon charges')
equipment={};piece(EQUIP_SLOT_MAIN_HAND,0,'Crusher weapon',0);equipment[EQUIP_SLOT_MAIN_HAND].enchantId=1300
equipment[EQUIP_SLOT_MAIN_HAND].enchantName='Glyph of Crushing';equipment[EQUIP_SLOT_MAIN_HAND].charges=false
check(SC:ScanEquipment().capabilities.crusher==nil,'Empty weapon charges cannot claim active Crusher')
equipment[EQUIP_SLOT_MAIN_HAND].charges=true
check(SC:ScanEquipment().capabilities.crusher~=nil,'Charged Crusher enchant provides its conditional capability')

local partialChampion={displayName='@Self',equipment={complete=true,items={},setList={}},
    skills={known=true,championKnown=true,primary={},backup={},champion={
        {slot=1,id=11,points=50,discipline='COMBAT'},{slot=2,id=12,points=50,discipline='COMBAT'},
        {slot=3,id=13,points=50,discipline='COMBAT'}}},food={verified=true,active=true,abilityId=902}}
SC.sv.activeProfile='boss';SC.sv.championScope='COMBAT'
local captured,message=SC:CaptureExpectedBuild('H1',partialChampion)
check(captured and message:find('omitted',1,true),'Incomplete Champion layouts preserve other verified build fields')
check(SC.sv.buildTemplates[SC:GetTemplateKey('H1')].values.champion==nil,'Incomplete Champion layouts are never captured as targets')
local championOnly={displayName='@Self',skills={championKnown=true,known=false,champion={
    {slot=1,id=11,points=50,discipline='COMBAT'}}}}
check(SC.Audit.CompareValue('champion','1:COMBAT:11:50, 2:COMBAT:12:50, 3:COMBAT:13:50','COMBAT')==nil,
    'Incomplete legacy Champion values cannot compare as valid targets')
local onlyCaptured=SC:CaptureExpectedBuild('H2',championOnly)
check(not onlyCaptured and SC.sv.buildTemplates[SC:GetTemplateKey('H2')]==nil,'An incomplete Champion layout cannot create an empty expected build')

SC.sv.enabled=true;SC.sv.visible=true;SC.sv.experimentalSharing=false
SC.sv.activeProfile='custom';SC.sv.customRequirements={stagger=true}
SC:AddCustomEffectId('stagger',993)
groupSize=3
local normalName=GetUnitName
GetUnitName=function(tag) if tag=='boss1' then return 'Lokkestiiz' elseif tag=='boss2' then return 'Second target' end;return normalName(tag) end
DoesUnitExist=function(tag) return tag=='boss1' or tag=='boss2' or tag=='player' or tag:match('^group')~=nil end
buffLists.boss1={{name='Heat Shock',id=993,stacks=1}};buffLists.boss2={{name='Heat Shock',id=993,stacks=3}}
SC.roster={{key='@Self',displayName='@Self',unitTag='player',connected=true,asui=true,role='MT'}}
SC.coverage={entries={{key='stagger',effect=Catalog and Catalog.effects.stagger or SC.Catalog.effects.stagger}}}
SC.inCombat=true;SC:StartPull();SC:SampleLiveCoverage()
local row=SC.coverage.entries[1]
check(#row.targets==2,'Live coverage exposes both target states')
check(row.targets[1].value==0 and row.targets[2].value==1,'Stack thresholds enforced per target')
check(row.liveCount==1 and row.liveTotal==2 and row.live==false,'Live engine does not union target debuffs')
now=now+1000;SC.inCombat=false;SC:FinalizePull()
local stored=SC:GetHistoryPulls()
check(#stored==1 and stored[1].label:find('Lokkestiiz',1,true),'Stored pull includes observed boss name')
check(stored[1].label:find('Pull 1',1,true)~=nil,'First encounter pull is numbered')
SC.inCombat=true;SC:StartPull();now=now+1000;SC.inCombat=false;SC:FinalizePull()
stored=SC:GetHistoryPulls()
check(stored[2].label:find('Pull 2',1,true)~=nil,'Pull numbers increment within encounter')
check(SC.reportWindow and not SC.reportWindow:IsHidden(),'Completed pull can automatically open report')
SC.inCombat=true;SC:StartPull()
check(SC.reportWindow:IsHidden(),'Starting combat closes previous report')
SC.inCombat=false;SC.pull=nil
SC:ResetHistory('test')
check(SC:GetHistoryPulls()[1]==nil,'History reset removes encounter reports')
local stale={asui=true,auditHashes={food=D.Hash('902')},detailAt=now-121000,detailAliveAt=now-121000}
SC.sv.activeProfile='boss';SC.sv.buildTemplates[SC:GetTemplateKey('H1')]={values={food='902'}};SC.sv.checkModes.food='REQUIRED'
stale.role='H1'
check(SC:EvaluateBuildAudit(stale).rows[1].status=='UNKNOWN','Expired shared signatures become unknown')
SC.sv.enabled,SC.sv.visible,SC.sv.locked=false,false,true
SLASH_COMMANDS['/assupport']('move')
check(SC.sv.enabled and SC.sv.visible and not SC.sv.locked,'Support move command activates and exposes the HUD')
print(string.format('PASS: %d assertions; Lua %s. No ESO-runtime certification.',total,_VERSION))
