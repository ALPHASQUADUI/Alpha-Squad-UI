-- Compatible-library evidence tests; no ESO renderer or network certification.
local total=0
local function check(value,message) total=total+1;assert(value,message) end
local now,size,online,dead,character=100000,2,true,false,"Remote character"
local SC={sv={enabled=true},NowMs=function() return now end,ScheduleRefresh=function(self) self.refreshes=(self.refreshes or 0)+1 end}
AlphaSquadUI={Modules={SupportCoverage=SC,ULTTracker={Group={}}}}
function GetGroupSize() return size end
function GetGroupUnitTagByIndex(index) return "group"..index end
function DoesUnitExist(tag) return tag=="group1" or (size>1 and tag=="group2") end
function IsUnitGrouped() return size>0 end
function IsUnitOnline(tag) return tag=="group1" or online end
function IsUnitDead(tag) return tag=="group2" and dead end
function AreUnitsEqual(tag,other) return tag==other or (tag=="group1" and other=="player") end
function GetUnitDisplayName(tag) return tag=="group1" and "@Self" or "@Remote" end
function GetUnitName(tag) return tag=="group1" and "Local character" or character end
local ultIds={[40223]=true,[122174]=true,[23634]=true,[500001]=true}
function IsAbilityUltimate(id) return ultIds[id]==true end
function GetAbilityName(id) return ({[40223]="Aggressive Horn",[122174]="Frozen Colossus",[23634]="Storm Atronach",[500001]="Personal Ultimate"})[id] or "Other skill" end
function GetSkillLineNameById(id) return ({[35]="Ardent Flame",[36]="Draconic Power",[37]="Earthen Heart"})[id] end
assert(loadfile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageCatalog.lua"))()
assert(loadfile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageExternal.lua"))()
local function Entry()
    return {unitTag="group2",displayName="@Remote",connected=true,dead=false,dataQuality="LIMITED",capabilitiesComplete=false,capabilities={}}
end
local entry=Entry()
check(not SC:MergeExternalCapabilities(entry),"Missing optional libraries keep remote details unknown")
local sharedUlt,sharedLines
local consumer={GetUnitULT=function() return sharedUlt end,GetUnitSkillLines=function() return sharedLines end}
AlphaSquadUI.Modules.ULTTracker.Group.lgcs=consumer
LibGroupCombatStats={RegisterAddon=function() error("Adapter must not register another consumer") end}
sharedUlt={ult1ID=40223,ult2ID=122174,_lastUpdated=now}
check(SC:MergeExternalCapabilities(entry),"Fresh compatible Ultimate sharing is consumed without another registration")
check(entry.capabilities.major_force and entry.capabilities.war_horn_resources and entry.capabilities.major_vulnerability,
    "Aggressive Horn and Colossus provide only their catalogued group effects")
check(entry.capabilities.major_force.mainBar and entry.capabilities.major_vulnerability.backBar,"Ultimate source bars remain distinct")
check(entry.externalUltimates[1].name=="Aggressive Horn" and entry.externalUltimates[2].bar=="back","Partial Ultimate view uses explicit names and bar labels")
check(not entry.skills and not entry.equipment and not entry.masteries and entry.capabilitiesComplete==false,
    "Partial library data never invents full equipment, skill bars or masteries")
local source="Shared ultimate: Aggressive Horn (front)"
check(entry.capabilities.major_force.sourceDetails[source].external and entry.capabilities.major_force.groupSource,
    "Source metadata clearly distinguishes shared Ultimate capability from an observed cast")
sharedUlt._lastUpdated=0
SC:MergeExternalCapabilities(entry)
check(not entry.capabilities.major_force and not entry.externalUltimates,"Default timestamp zero clears earlier external evidence")
sharedUlt._lastUpdated=now-75001;SC:MergeExternalCapabilities(entry)
check(entry.externalUltimates and entry.externalUltimates[1].updatedAt==now-75001
    and entry.capabilities.major_force,"Unchanged LGCS slot reports remain usable without inventing a new timestamp")
sharedUlt._lastUpdated=now+1;SC:MergeExternalCapabilities(entry)
check(not entry.externalUltimates,"Future timestamps are rejected")
sharedUlt._lastUpdated=0/0;SC:MergeExternalCapabilities(entry)
check(not entry.externalUltimates,"Non-finite library timestamps are rejected")
sharedUlt={ult1ID=40094,ult2ID=500001,_lastUpdated=now}
SC:MergeExternalCapabilities(entry)
check(not entry.capabilities.minor_berserk and #entry.externalUltimates==1,"A non-Ultimate ID cannot impersonate Combat Prayer; personal Ultimate creates no group effect")
sharedUlt={ult1ID=23634,ult2ID=0,_lastUpdated=now}
SC:MergeExternalCapabilities(entry)
check(entry.capabilities.major_berserk and not entry.capabilities.major_force,"Changing shared slots removes old providers before adding Atronach")
check(entry.capabilities.major_berserk.sourceDetails["Shared ultimate: Storm Atronach (front)"].conditions:find("synergy")
    or entry.capabilities.major_berserk.sourceDetails["Shared ultimate: Storm Atronach (front)"].conditions:find("Charged Lightning"),
    "Atronach retains its synergy condition")
sharedUlt={ult1ID=math.huge,ult2ID=1.5,_lastUpdated=now};SC:MergeExternalCapabilities(entry)
check(not entry.externalUltimates,"Non-finite and fractional slot IDs are ignored")
sharedLines={first=35,second=36,third=37,_lastUpdated=0};SC:MergeExternalCapabilities(entry)
check(not entry.externalSkillLines,"Unreceived library class guesses do not become subclass facts")
sharedLines._lastUpdated=now;SC:MergeExternalCapabilities(entry)
check(#entry.externalSkillLines.names==3 and entry.externalSkillLines.names[1]=="Ardent Flame" and not entry.masteries,
    "Received skill line IDs produce a named partial view without mastery inference")
sharedLines._lastUpdated=now-75001;SC:MergeExternalCapabilities(entry)
check(entry.externalSkillLines and entry.externalSkillLines.updatedAt==now-75001,
    "Change-driven skill lines retain the original receipt instead of expiring by polling age")
entry.externalSkillLines.ids[1]=999
check(sharedLines.first==35,"External views never mutate the library's skill line table")
sharedUlt={ult1ID=40223,ult2ID=0,_lastUpdated=now}
online=false;SC:MergeExternalCapabilities(entry)
check(not entry.externalUltimates and not entry.externalSkillLines,"Offline players cannot supply actionable external coverage")
online=true;dead=true;SC:MergeExternalCapabilities(entry)
check(not entry.externalUltimates,"Dead players cannot supply actionable external coverage")
dead=false;entry.unitTag="group1";SC:MergeExternalCapabilities(entry)
check(not entry.externalUltimates,"The local player never enters the remote adapter")
entry=Entry();entry.buildVerified=true;entry.capabilitiesComplete=true
SC:MergeExternalCapabilities(entry)
check(not entry.externalUltimates,"A complete verified build stays authoritative over another library's cached slots")
entry=Entry();sharedUlt=nil;sharedLines=nil
SC:MergeExternalCapabilities(entry)
check(not entry.externalUltimates and not entry.externalSkillLines,
    "Removal from the library-owned group cache clears previously reported slots and lines")
local calls,callback,setData,available=0,nil,{},true
local constants={event_data_update=2,unit_type_group=2,active_type_none=0,active_type_dual=1,active_type_front=2,active_type_back=3}
LibSetDetection={constants=constants,
    IsUnitDataAvailable=function() return available end,
    GetUnitSetData=function() return setData end,
    RegisterEvent=function(event,name,fn,unitType)
        check(event==2 and unitType==2 and name=="AlphaSquadSupportCoverageExternal","LSD uses the v5 namespaced group data event")
        calls=calls+1;callback=fn;return 0
    end}
SC:InitializeExternalSources();SC:InitializeExternalSources()
check(calls==1,"LSD listener registration is idempotent")
local function Set(id,body,front,back,active)
    return {[id]={setName=(SC.Catalog.setNameById or {})[id] or "Reported set",numEquip={body=body,front=front,back=back},activeType=active}}
end
setData=Set(185,3,2,0,2)
SC:MergeExternalCapabilities(entry)
check(not entry.externalSets,"Cached LSD data read before a real event is not assigned invented freshness")
callback("group2",false);SC:MergeExternalCapabilities(entry)
check(entry.capabilities.major_courage and entry.capabilities.major_courage.mainBar and not entry.capabilities.major_courage.backBar,
    "LSD body plus front weapon pieces cover a five-piece set on the front bar")
check(entry.externalSets.setList[1].bodyCount==3 and entry.externalSets.setList[1].mainCount==5
    and entry.externalSets.setList[1].backCount==3,"Already weighted two-handed weapon pieces are counted once")
check(not entry.equipment and not entry.skills and entry.capabilitiesComplete==false,"Set summaries do not fabricate per-slot gear, glyphs or full build completeness")
entry.externalSets.setList[1].mainCount=999
check(setData[185].numEquip.front==2,"Inspector set data is detached from mutable library-owned tables")
local received=now
now=now+600000;SC:MergeExternalCapabilities(entry)
check(entry.externalSets and entry.externalSets.updatedAt==received and entry.capabilities.major_courage,
    "A change-driven set report remains valid for the continuous group session without renewing its timestamp")
function GetItemSetUnperfectedSetId(id) return id==99951 and 185 or 0 end
setData=Set(99951,3,2,0,2);callback("group2",false);SC:MergeExternalCapabilities(entry)
check(entry.capabilities.major_courage and entry.externalSets.setList[1].id==185,
    "Native Perfected set identities resolve to their catalog family")
setData=Set(185,3,0,0,0);setData[99951]=Set(99951,0,2,0,2)[99951]
callback("group2",false);SC:MergeExternalCapabilities(entry)
check(entry.capabilities.major_courage and #entry.externalSets.setList==1 and entry.externalSets.setList[1].mainCount==5,
    "Mixed normal and Perfected family counts are merged without combining front and back")
setData=Set(185,3,1,1,0);callback("group2",false);SC:MergeExternalCapabilities(entry)
check(not entry.capabilities.major_courage,"Front and back weapon counts cannot be combined into a false five-piece set")
setData=Set(185,5,0,0,0);callback("group2",false);SC:MergeExternalCapabilities(entry)
check(not entry.capabilities.major_courage,"A library-inactive set never overrides its activation state by counts alone")
setData=Set(185,5,0,0,1);setData[1]={numEquip={body=3,front=0,back=0},activeType=0,setName="Incognito"}
callback("group2",false);SC:MergeExternalCapabilities(entry)
check(entry.externalSets.incognito and not entry.externalSets.complete and #entry.externalSets.setList==1,
    "Incognito stays partial and does not reveal the hidden set identity")
check(entry.capabilities.major_courage,"Intentionally disclosed whitelist sets remain useful in incognito mode")
setData=Set(185,11,0,0,1);callback("group2",false);SC:MergeExternalCapabilities(entry)
check(not entry.externalSets and not entry.capabilities.major_courage,"Impossible set counts invalidate the previous report")
setData=Set(185,5,0,0,1);setData[180]={numEquip={body=6,front=0,back=0},activeType=1,setName="Powerful Assault"}
callback("group2",false);SC:MergeExternalCapabilities(entry)
check(not entry.externalSets,"Aggregate body counts cannot exceed the actual armor and jewelry slots")
setData=Set(185,3,0/0,0,1);callback("group2",false);SC:MergeExternalCapabilities(entry)
check(not entry.externalSets,"Non-finite library piece counts are rejected")
setData=Set(185,5,0,0,1);callback("group2",false)
online=false;SC:MergeExternalCapabilities(entry);online=true;SC:MergeExternalCapabilities(entry)
check(not entry.externalSets,"An offline transition erases the session receipt; a cached reappearance is insufficient")
callback("group2",false);character="Another character";SC:MergeExternalCapabilities(entry)
check(not entry.externalSets,"A changed character cannot inherit the previous character's set report")
callback("group2",false);size=0;SC:PruneExternalSources();size=2;SC:MergeExternalCapabilities(entry)
check(not entry.externalSets,"Disband removes receipts even if the upstream library keeps its cache")
callback("group2",false);SC:ResetExternalSources();SC:MergeExternalCapabilities(entry)
check(not entry.externalSets,"Explicit session reset clears adapter evidence")
callback("group2",false);available=false;SC:MergeExternalCapabilities(entry)
check(not entry.externalSets,"A library cache removal invalidates the adapter's report immediately")
available=true;setData=Set(185,5,0,0,1);callback("group2",false)
sharedUlt={ult1ID=40223,ult2ID=0,_lastUpdated=now}
entry=Entry();entry.buildVerified=true;entry.scannedAt=now
entry.equipment={complete=true,setList={}};entry.skills={known=true,primary={},backup={}}
SC:MergeExternalCapabilities(entry)
check(not entry.capabilities.major_courage and not entry.capabilities.major_force and not entry.externalSets and not entry.externalUltimates,
    "Exact equipment and skills defeat contradictory library reports even while overall capability completeness stays false")
callback("group2",false);entry.buildVerified=false;entry.fullBuild={};entry.fullBuildFingerprint=33;entry.buildDetailFingerprint=33
SC:MergeExternalCapabilities(entry)
check(not entry.capabilities.major_courage and not entry.capabilities.major_force and not entry.externalUltimates,
    "A retained full build confirmed by the current fingerprint remains authoritative without a refreshed summary flag")
entry.buildVerified=false;entry.equipment=nil;entry.skills=nil;sharedUlt=nil;SC:MergeExternalCapabilities(entry)
check(not entry.externalSets,"A superseded LSD report cannot reappear after the newer full build expires")
constants.active_type_dual=nil;setData=Set(185,5,0,0,nil);callback("group2",false);SC:MergeExternalCapabilities(entry)
check(not entry.externalSets,"Missing active-type constants cannot turn an invalid state into an active set")
print(string.format("PASS: %d assertions; Lua %s. No ESO-runtime certification.",total,_VERSION))
