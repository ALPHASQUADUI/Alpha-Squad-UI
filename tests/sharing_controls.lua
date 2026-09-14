-- Production-shape LGB controls: internal is absent after library startup.
local checks=0
local function check(value,message) checks=checks+1;assert(value,message) end
local values={[20]=false,[21]=false,[40]=false,[507]=false,[510]=false,[22]=false}
local prefs,opens,registrations={},0,0
local optionTables={}
local function Section(title,headers)
    local controls={}
    for _,pair in ipairs(headers) do
        local id,name=pair[1],pair[2]
        controls[#controls+1]={type='header',name=name}
        controls[#controls+1]={type='checkbox',name='Allow Sending',getFunc=function()return values[id]end,
            setFunc=function(value)values[id]=value end}
    end
    return {type='submenu',name=title,controls=controls}
end
optionTables={Section('Group Combat Stats',{{20,'UltType'},{21,'UltValue'},{22,'Dps'}}),
    Section('Lib Set Detection',{{40,'SetData'}}),
    Section('Alpha Squad UI — Build Sharing',{{510,'AlphaSquadSupportCoverage'},{507,'AlphaSquadSupportDetails'}})}
local sc={sv={enabled=false,shareData=true,experimentalSharing=false},share={available=true},
    InitializeSharing=function()end,UpdateRuntime=function()end,MarkScanDirty=function()end,ResetSharingState=function()end}
AlphaSquadUI={Modules={SupportCoverage=sc},Preferences={sv=prefs,Initialize=function()end},
    Settings={CloseMain=function()opens=opens+1 end}}
LibGroupBroadcast={}
LibGroupCombatStats={RegisterAddon=function(_,stats)check(#stats==1 and stats[1]=='ULT','No unsolicited combat-stat categories are enabled');registrations=registrations+1;return {} end}
LibSetDetection={}
LibGroupBroadcastOptions={}
LibAddonMenu2={RegisterOptionControls=function(_,id,options)check(id=='LibGroupBroadcastOptions' and options==optionTables,'Native option registration is forwarded unchanged')end,
    OpenToPanel=function()opens=opens+1 end}
local originalRegister=LibAddonMenu2.RegisterOptionControls
CALLBACK_MANAGER={FireCallbacks=function(_,event,panel)
    check(event=='LAM-BeforePanelControlsCreated' and panel==LibGroupBroadcastOptions,'Only the native options-data producer is invoked')
    LibAddonMenu2:RegisterOptionControls('LibGroupBroadcastOptions',optionTables)
end}
assert(loadfile('AlphaSquadUI/Core/Sharing.lua'))()
local S=AlphaSquadUI.Sharing
S.Initialize()
check(S.IsEnabled('builds') and S.IsEnabled('ultimate') and S.IsEnabled('sets'),'Installing Alpha Squad turns its preinstalled native sharing categories ON without an internal table')
check(registrations==1 and opens==0,'Defaults start only one Ultimate sender without opening any settings')
check(prefs.sharingDefaultsVersion==1 and sc.sv.experimentalSharing and prefs.buildSharing,'The one-time bootstrap replaces an old implicit experimental OFF with sharing ON')
check(LibAddonMenu2.RegisterOptionControls==originalRegister,'Temporary options capture is always restored')
check(S.SetEnabled('ultimate',false) and not values[20] and not values[21],'OFF updates both real Ultimate Allow Sending settings')
check(not S.IsEnabled('ultimate') and prefs.ultimateSharing==false,'Displayed OFF reflects the native library settings')
check(values[40] and values[507] and values[510] and not values[22],'Unrelated set/build/DPS settings are preserved')
values[20],values[21]=true,true
check(S.IsEnabled('ultimate'),'Native ON is reflected even when a previous Alpha Squad preference says OFF')
values[40]=false;S.Initialize()
check(not S.IsEnabled('sets') and prefs.setsSharing==false,'After first setup, a native OFF survives reload initialization')
check(S.SetEnabled('sets',true) and values[40],'Set sharing turns ON from Alpha Squad without navigation')
check(S.SetEnabled('builds',false) and not values[507] and not values[510] and not sc.sv.shareData,'Build OFF disables both native protocols and local consent')
check(S.SetEnabled('builds',true) and values[507] and values[510] and sc.sv.shareData,'Build ON updates native protocols while tracking remains disabled')
check(sc.sv.enabled==false and opens==0,'Sharing never enables a tracking module or changes the visible settings panel')
-- A native setter failure must not leave half of a paired Ultimate protocol ON.
S.SetEnabled('ultimate',false)
local originalSet=optionTables[1].controls[4].setFunc
optionTables[1].controls[4].setFunc=function()error('Unavailable control')end
check(not S.SetEnabled('ultimate',true) and not values[20] and not values[21],'Paired controls roll back if either native setter fails')
optionTables[1].controls[4].setFunc=originalSet
S.Initialize();check(values[20] and values[21],'An explicit pending choice applies once controls become available')
-- Do not accept a similarly numbered/name-changed library or open its panel.
S.nativeControls={};optionTables[2].controls[1].name='OtherProtocol'
check(not S.SetEnabled('sets',false) and values[40] and opens==0,'An incompatible option identity stays untouched and never navigates')
optionTables[2].controls[1].name='SetData';S.Initialize()
check(not values[40],'An unavailable-library OFF choice is retained and applied when compatibility returns')
S.nativeControls={}
CALLBACK_MANAGER.FireCallbacks=function()error('Library initialization unavailable')end
local enabled,reason,available=S.GetStatus('sets')
check(not enabled and not available and type(reason)=='string','Missing controls report unavailable instead of a false active status')
check(LibAddonMenu2.RegisterOptionControls==originalRegister and opens==0,'Failed options discovery restores the library method and leaves the window alone')
-- Upgrade from the previous ineffective bridge honors explicit Alpha choices.
S.nativeControls={};prefs.sharingDefaultsVersion=nil
prefs.buildSharing=false;prefs.ultimateSharing=false;prefs.setsSharing=true
CALLBACK_MANAGER.FireCallbacks=function()LibAddonMenu2:RegisterOptionControls('LibGroupBroadcastOptions',optionTables)end
values[20],values[21],values[507],values[510]=true,true,true,true
S.Initialize()
check(not values[20] and not values[21] and not values[507] and not values[510] and values[40],
    'One-time bridge repair applies saved explicit Alpha OFF choices instead of resetting them')
check(not sc.sv.shareData and not sc.sv.experimentalSharing and prefs.sharingDefaultsVersion==1,
    'Build consent and the account migration marker match the repaired native choice')

-- Actual transport code: request failures, membership churn and identity bounds.
local now,scans=10000,0
local keys={group1='@Self',group2='@Other',player='@Self'}
function GetGroupSize()return 2 end
function GetGroupUnitTagByIndex(i)return 'group'..i end
function GetUnitName(tag)return (keys[tag] or '')..' Character' end
function AreUnitsEqual(a,b)return keys[a]~=nil and keys[a]==keys[b] end
function IsUnitOnline()return true end
function IsUnitDead()return false end
local function Hash(body)local result=0;for index=1,#body do result=(result*31+body:byte(index))%16777215 end;return result end
sc={sv={enabled=false,shareData=true,experimentalSharing=true},inCombat=false,peerData={},
    Catalog={effects={},wireV1Keys={},wireV2Keys={}},BuildCodec={Hash=Hash,Encode=function()return 'DATA'end},
    GetPlayerKey=function(_,tag)return keys[tag] or '' end,IsGrouped=function()return true end,
    IsSelf=function(_,tag)return keys[tag]=='@Self'end,NowMs=function()return now end,
    ScheduleRefresh=function()end,IsOnline=function()return true end,
    ScanLocalPlayer=function()scans=scans+1;error('Native capture unavailable')end}
AlphaSquadUI={Modules={SupportCoverage=sc}}
assert(loadfile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageShare.lua'))()
assert(loadfile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageDetails.lua'))()
sc.share.available=true;sc.share.detailProtocol={IsEnabled=function()return true end}
local request={version=3,kind=0,revision=1,checksum=Hash('@Self'),body='@Self'}
for _=1,20 do sc:OnDetailData('group2',request) end
check(scans==1,'Repeated requests cannot retrigger a failing native capture inside the rate limit')
now=now+20001;sc:OnDetailData('group2',request)
check(scans==2,'Capture retry resumes after the bounded cooldown')
sc.loading=true;now=now+20001;sc:OnDetailData('group2',request)
check(scans==2,'Loading blocks addressed build requests')
sc.loading=false;sc:OnDetailData('outsider',request)
check(scans==2,'Only current native group members can request a capture')
sc.localSnapshot={capabilities={},equipment={glyphs={}},food={}}
local payload=sc:BuildSharePayload()
for index=1,100 do keys.group2='@Member'..index;sc:OnPeerShareData('group2',payload) end
local size=0;for _ in pairs(sc.peerData) do size=size+1 end
check(size==1 and sc.peerData['@Member100'],'Roster churn stays bounded while the tracking module is disabled')
sc.share.outgoingBuild={requester='@Departed'};sc.share.incomingBuild={key='@Departed'};sc.share.requestedKey='@Departed'
sc:PrunePeerSharingData()
check(not sc.share.outgoingBuild and not sc.share.incomingBuild and not sc.share.requestedKey,'Departed peers cannot retain pending transfer state')
keys.group2='|t999999:999999:untrusted.dds|t';sc:OnPeerShareData('group2',payload)
check(sc.peerData[keys.group2]==nil,'Invalid account identities never become peer table keys')
print('Sharing controls and boundaries: '..checks..' assertions passed')
