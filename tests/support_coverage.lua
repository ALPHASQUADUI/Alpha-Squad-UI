-- Deterministic tests for branch development. These doubles are not ESO runtime validation.
local total=0
local function check(value,message) total=total+1;assert(value,message) end
local now,epoch,groupSize=10000,100000,0
local later,updates,events={},{},{}
local function copy(value) if type(value)~="table" then return value end local out={};for k,v in pairs(value) do out[k]=copy(v) end;return out end
local constants={"EVENT_ADD_ON_LOADED","EVENT_PLAYER_ACTIVATED","EVENT_PLAYER_COMBAT_STATE","EVENT_GROUP_MEMBER_JOINED",
    "EVENT_GROUP_MEMBER_LEFT","EVENT_GROUP_UPDATE","EVENT_GROUP_MEMBER_CONNECTED_STATUS","EVENT_EFFECT_CHANGED",
    "EVENT_INVENTORY_ITEM_USED","ITEM_SOUND_CATEGORY_POTION","EVENT_INVENTORY_SINGLE_SLOT_UPDATE","EVENT_ACTION_SLOT_UPDATED",
    "EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED","EVENT_ACTIVE_WEAPON_PAIR_CHANGED","EVENT_SCREEN_RESIZED","EVENT_CURRENT_QUICKSLOT_CHANGED",
    "REGISTER_FILTER_UNIT_TAG","TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT","CENTER","TOP","LEFT","RIGHT","BOTTOM",
    "TEXT_ALIGN_CENTER","TEXT_ALIGN_LEFT","TEXT_ALIGN_RIGHT","TEXT_ALIGN_TOP","TEXT_WRAP_MODE_ELLIPSIS","MOUSE_BUTTON_INDEX_LEFT",
    "CT_CONTROL","CT_TEXTURE","CT_LABEL","DT_HIGH","DL_OVERLAY","TEX_BLEND_MODE_ADD","HOTBAR_CATEGORY_PRIMARY","HOTBAR_CATEGORY_BACKUP",
    "HOTBAR_CATEGORY_CHAMPION","HOTBAR_CATEGORY_QUICKSLOT_WHEEL","BAG_WORN","LINK_STYLE_DEFAULT","ITEMTYPE_POTION","SKILL_TYPE_CLASS",
    "EQUIP_SLOT_HEAD","EQUIP_SLOT_CHEST","EQUIP_SLOT_SHOULDERS","EQUIP_SLOT_WAIST","EQUIP_SLOT_HAND","EQUIP_SLOT_LEGS","EQUIP_SLOT_FEET",
    "EQUIP_SLOT_NECK","EQUIP_SLOT_RING1","EQUIP_SLOT_RING2","EQUIP_SLOT_MAIN_HAND","EQUIP_SLOT_OFF_HAND","EQUIP_SLOT_BACKUP_MAIN",
    "EQUIP_SLOT_BACKUP_OFF","EQUIP_SLOT_POISON","EQUIP_SLOT_BACKUP_POISON","WEAPONTYPE_FIRE_STAFF","WEAPONTYPE_FROST_STAFF",
    "WEAPONTYPE_LIGHTNING_STAFF","WEAPONTYPE_HEALING_STAFF","WEAPONTYPE_BOW","WEAPONTYPE_TWO_HANDED_SWORD",
    "WEAPONTYPE_TWO_HANDED_AXE","WEAPONTYPE_TWO_HANDED_HAMMER","BUFF_TYPE_MAJOR_COURAGE","BUFF_TYPE_MINOR_FORCE"}
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
    return b.name,0,b.ending or 99,index,b.stacks or 1,"icon",0,1,0,0,b.id,false,true
end
local buffTypes={}
function GetAbilityBuffType(id) return buffTypes[id] or 0,true end
function GetItemLink() return "" end
function GetItemLinkSetInfo() return false end
function GetSlotBoundId() return 0 end
function GetGroupMemberRoles() return true,false,false end
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
check(type(SLASH_COMMANDS['/assupport'])=='function','Commands registered')
SC:Refresh('test')
check(SC.localSnapshot~=nil,'Local snapshot built')
check(SC.coverage.ready==false,'Unknown coverage cannot be ready')
check(SC.coverage.missingCount==0,'Incomplete source catalog cannot prove absence')
check(SC.coverage.unknownCount>0,'Unverified sources are explicit')

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

local c1='1:COMBAT:11:50, 2:COMBAT:12:50, 3:COMBAT:13:50, 4:COMBAT:14:50'
local c2='8:COMBAT:14:50, 7:COMBAT:13:50, 6:COMBAT:12:50, 5:COMBAT:11:50'
check(SC.Audit.CompareValue('champion',c1,'COMBAT')==SC.Audit.CompareValue('champion',c2,'COMBAT'),'Champion slot order is irrelevant')
check(SC.Audit.CompareValue('champion',c1,'COMBAT')~=SC.Audit.CompareValue('champion',c2:gsub('14:50','14:40'),'COMBAT'),'Committed Champion points are checked')
check(SC.Audit.CompareValue('champion','1:UNKNOWN:2:50','COMBAT')==nil,'Missing CP metadata cannot pass')
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
SC.sv.checkModes.food='OFF'
check(#SC:EvaluateBuildAudit(player).rows==0,'OFF checks impose nothing')
check(not SC:CaptureExpectedBuild('UNKNOWN',player),'Unassigned role cannot establish a role template')

-- A six-recipient buff is not an unconditional twelve-person requirement.
SC.sv.effectRules.powerful_assault={}
check(SC:GetEffectRule('powerful_assault').targetCount==6,'PA defaults to six recipients')
SC.sv.effectRules.powerful_assault.targetCount=0
check(SC:GetEffectRule('powerful_assault').targetCount==nil,'Recipient count is configurable')
SC.sv.effectRules.stagger={expectedStacks=3}
check(SC:GetEffectRule('stagger').expectedStacks==3,'Stack requirements configured')

-- Mask positions remain stable after adding new catalog entries.
SC.localSnapshot={capabilities={major_courage={},bright_harbinger={}},equipment={setList={}}}
local payload=SC:BuildSharePayload()
local index
for i,key in ipairs(SC.Catalog.wireV1Keys) do if key=='major_courage' then index=i-1 end end
check(payload['cap'..(math.floor(index/24)+1)]==2^(index%24),'v1 capability mask does not shift')
groupSize=3;SC.sv.experimentalSharing=true
SC:OnPeerShareData('outsider',payload)
check(SC.peerData['@outsider']==nil,'Non-members cannot submit build data')
SC:OnPeerShareData('group2',payload)
check(SC.peerData['@group2'].capabilities.major_courage~=nil,'Stable capability wire decoded')
check(SC.peerData['@group2'].capabilities.bright_harbinger==nil,'Unknown v1 positions are not invented')
SC.peerData['@group2'].auditValues={food='902'};SC.peerData['@group2'].detailAt=now
SC.peerData['@group2'].liveCapabilities={major_courage={}};SC.peerData['@group2'].liveUpdatedAt=now
SC:OnPeerShareData('group2',payload)
check(SC.peerData['@group2'].auditValues.food=='902','Build updates preserve detailed fields')
check(SC.peerData['@group2'].liveCapabilities.major_courage~=nil,'Build updates preserve live fields')
local bad=copy(payload);bad.cap1=-1
local previous=SC.peerData['@group2']
SC:OnPeerShareData('group2',bad)
check(SC.peerData['@group2']==previous,'Malformed masks are rejected')
SC:OnPlanData('group2',{revision=1,kind=0,key=1,ownerHash=0})
check(SC.remotePlan==nil,'Non-leader cannot overwrite the plan')
SC:OnPlanData('group1',{revision=1,kind=0,key=1,ownerHash=0})
check(SC.remotePlan==nil,'Own loopback plan ignored')
SC.sv.experimentalSharing=false
SC:OnPeerLiveData('group3',{cap1=1,cap2=0,cap3=0,cap4=0})
check(SC.peerData['@group3']==nil,'Disabled experimental receiver is silent')

local D=SC.Details
local text=D.Encode({capabilities={},equipment=nil})
check(type(text)=='string' and D.Decode(text)~=nil,'Named field round trip')
check(D.Decode('evil=payload')==nil,'Unknown detail fields rejected')
check(D.Decode('food=1\nfood=2')==nil,'Duplicate detail fields rejected')
check(D.Decode('food=%GG')==nil,'Malformed escapes rejected')
check(D.Decode(string.rep('x',4097))==nil,'Detail payload bounded')

-- Interface: real row geometry and no scale drift.
SC.sv.visible=true;SC.sv.enabled=true;SC.uiObscured=false;SC.sv.scale=150;SC.sv.rowHeight=48
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
SC.sv.activeProfile='progression';SC:Refresh('profile test');SC:OpenMatrix()
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
SC:ResetHistory('Manual reset')
check(#SC:GetHistoryPulls()==0,'Manual reset is idempotent')
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
GetItemLinkEnchantInfo=function() return false end
GetItemSetUnperfectedSetId=function(id) return id==501 and 500 or 0 end
local function piece(slot,id,name,weapon) equipment[slot]={id=id,name=name or "Spell Power Cure",weapon=weapon} end
piece(EQUIP_SLOT_HEAD,500)
check(SC:ScanEquipment().capabilities.major_courage==nil,'One piece cannot provide a five-piece capability')
for _,slot in ipairs({EQUIP_SLOT_CHEST,EQUIP_SLOT_SHOULDERS,EQUIP_SLOT_WAIST}) do piece(slot,500) end
piece(EQUIP_SLOT_MAIN_HAND,500,nil,0)
local gear=SC:ScanEquipment()
check(gear.setList[1].mainCount==5 and gear.setList[1].backCount==4,'Main and backup counts remain separate')
check(gear.capabilities.major_courage.mainBar and not gear.capabilities.major_courage.backBar,'Set capability retains active-bar condition')
equipment[EQUIP_SLOT_MAIN_HAND]=nil
piece(EQUIP_SLOT_BACKUP_MAIN,500,nil,WEAPONTYPE_HEALING_STAFF)
check(SC:ScanEquipment().setList[1].backCount==6,'Two-handed staff counts as two pieces')
equipment={};piece(EQUIP_SLOT_HEAD,500);piece(EQUIP_SLOT_CHEST,500)
for _,slot in ipairs({EQUIP_SLOT_SHOULDERS,EQUIP_SLOT_WAIST,EQUIP_SLOT_HAND}) do piece(slot,501,"Perfected Spell Power Cure") end
gear=SC:ScanEquipment()
check(#gear.setList==1 and gear.setList[1].mainCount==5,'Mixed variants count toward the same native set family')
check(gear.capabilities.major_courage~=nil,'Mixed variants can unlock a valid shared bonus')
check(#gear.setList[1].variants==2,'Variant identities remain available for inspection')
equipment={};piece(EQUIP_SLOT_HEAD,700,'Symphony of Blades')
check(SC:ScanEquipment().capabilities.symphony==nil,'One monster piece cannot provide two-piece proc')
piece(EQUIP_SLOT_SHOULDERS,700,'Symphony of Blades')
check(SC:ScanEquipment().capabilities.symphony~=nil,'Two monster pieces provide the conditional capability')

SC.sv.enabled=true;SC.sv.visible=true;SC.sv.experimentalSharing=false
SC.sv.activeProfile='custom';SC.sv.customRequirements={stagger=true}
SC:AddCustomEffectId('stagger',993)
groupSize=3
local normalName=GetUnitName
GetUnitName=function(tag) if tag=='boss1' then return 'Lokkestiiz' elseif tag=='boss2' then return 'Second target' end;return normalName(tag) end
DoesUnitExist=function(tag) return tag=='boss1' or tag=='boss2' or tag=='player' or tag:match('^group')~=nil end
buffLists.boss1={{name='Stagger',id=993,stacks=1}};buffLists.boss2={{name='Stagger',id=993,stacks=3}}
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
local stale={asui=true,auditValues={food='902'},detailAt=now-11000,detailAliveAt=now-11000}
check(SC.Audit.Value(stale,'food')==nil,'Consumable fields become unknown without fresh evidence')
print(string.format('PASS: %d assertions; Lua %s. No ESO-runtime certification.',total,_VERSION))
