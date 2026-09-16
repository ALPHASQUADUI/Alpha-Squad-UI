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
check(not S.IsEnabled('builds') and not S.IsEnabled('ultimate') and not S.IsEnabled('sets'),'Fresh installs preserve preinstalled native OFF and require explicit opt-in')
check(registrations==0 and opens==0,'Fresh OFF starts no Ultimate sender and opens no settings')
check(prefs.sharingDefaultsVersion==1 and not sc.sv.experimentalSharing and prefs.buildSharing==false,'New build consent defaults OFF')
check(LibAddonMenu2.RegisterOptionControls==originalRegister,'Temporary options capture is always restored')
check(S.SetEnabled('ultimate',true) and S.SetEnabled('sets',true) and S.SetEnabled('builds',true),'Explicit choices enable only the supported sharing categories')
check(registrations==1 and opens==0,'Explicit Ultimate consent starts exactly one sender without navigation')
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
S.nativeControls={}
local reentries=0
CALLBACK_MANAGER.FireCallbacks=function()
    reentries=reentries+1
    S.GetStatus('sets')
    LibAddonMenu2:RegisterOptionControls('LibGroupBroadcastOptions',optionTables)
end
local _,_,availableAfterReentry=S.GetStatus('sets')
check(reentries==1 and availableAfterReentry and LibAddonMenu2.RegisterOptionControls==originalRegister,
    'An options callback that queries sharing cannot recurse or leave an interceptor installed')
S.nativeControls={}
CALLBACK_MANAGER.FireCallbacks=function()LibAddonMenu2:RegisterOptionControls('LibGroupBroadcastOptions',optionTables)end
S.SetEnabled('builds',true)
sc.share.controlError='Earlier native control failure';S.errors.builds=sc.share.controlError
check(S.IsEnabled('builds') and not sc.share.controlError and not S.errors.builds,
    'Corrected native controls clear a stale error without requiring another explicit ON')
-- Upgrade from the previous ineffective bridge honors explicit Alpha choices.
S.nativeControls={};prefs.sharingDefaultsVersion=nil
prefs.buildSharing=false;prefs.ultimateSharing=false;prefs.setsSharing=true
CALLBACK_MANAGER.FireCallbacks=function()LibAddonMenu2:RegisterOptionControls('LibGroupBroadcastOptions',optionTables)end
values[20],values[21],values[507],values[510]=true,true,true,true
S.Initialize()
check(not values[20] and not values[21] and not values[507] and not values[510] and not values[40],
    'One-time bridge repair preserves saved explicit Alpha OFF and an existing native OFF')
check(not sc.sv.shareData and not sc.sv.experimentalSharing and prefs.sharingDefaultsVersion==1,
    'Build consent and the account migration marker match the repaired native choice')
-- A saved local ON does not authorize overriding a subsequent native OFF.
prefs.sharingDefaultsVersion=nil;prefs.buildSharing=true;prefs.ultimateSharing=true;prefs.setsSharing=true
prefs.buildSharingPending=nil;prefs.ultimateSharingPending=nil;prefs.setsSharingPending=nil
values[20],values[21],values[40],values[507],values[510]=false,true,false,false,true
S.Initialize()
check(not values[20] and values[21] and not values[40] and not values[507] and values[510],
    'A legacy saved ON preserves each preexisting native OFF, including a paired partial OFF')
check(prefs.buildSharing and sc.sv.shareData and sc.sv.experimentalSharing,
    'Preserving a native OFF does not silently delete the accepted local build preference')
-- A saved ON whose native category remains ON keeps working across upgrades.
prefs.sharingDefaultsVersion=nil
values[20],values[21],values[40],values[507],values[510]=true,true,true,true,true
S.Initialize()
check(S.IsEnabled('builds') and S.IsEnabled('ultimate') and S.IsEnabled('sets'),
    'A saved ON with native ON remains enabled across migration')
prefs.sharingDefaultsVersion=nil;prefs.buildSharing=nil;sc.sv.shareData=true;sc.sv.experimentalSharing=true
S.Initialize()
check(prefs.buildSharing==true and S.IsEnabled('builds'),
    'Accepted build consent in an older module profile migrates without a silent reset')
-- Unavailable/unknown native controls must not start a fresh Ultimate sender.
prefs.sharingDefaultsVersion=nil;prefs.buildSharing=nil;prefs.ultimateSharing=nil;prefs.setsSharing=nil
sc.sv.shareData=false;sc.sv.experimentalSharing=false
S.nativeControls={};S.ultimateSender=nil
local beforeMissing=registrations
local nativeCallbacks=CALLBACK_MANAGER.FireCallbacks
CALLBACK_MANAGER.FireCallbacks=function()end
S.Initialize()
check(registrations==beforeMissing and prefs.ultimateSharing==false and prefs.buildSharing==false and prefs.setsSharing==false,
    'Unknown native settings preserve new OFF preferences and cannot start a sender')
CALLBACK_MANAGER.FireCallbacks=nativeCallbacks;S.Initialize()
check(not values[20] and not values[21] and not values[40] and not values[507] and not values[510],
    'Deferred fresh OFF applies when native controls become available, without unsolicited ON')
local combatLibrary,setLibrary=LibGroupCombatStats,LibSetDetection
LibGroupCombatStats=nil;LibSetDetection=nil;S.nativeControls={}
prefs.ultimateSharing=nil;prefs.setsSharing=nil;S.Initialize()
check(not S.StartUltimateSender() and prefs.ultimateSharing==false and prefs.setsSharing==false,
    'Missing optional libraries never infer consent or register a sender')
LibGroupCombatStats= combatLibrary;LibSetDetection=setLibrary;S.nativeControls={};S.Initialize()
prefs.buildSharing=true;prefs.buildSharingPending=true;prefs.buildSharingResumeRequired=true
sc.sv.shareData=true;sc.sv.experimentalSharing=true;sc.share.transportResumeRequired=nil
assert(loadfile('AlphaSquadUI/Core/Sharing.lua'))();S=AlphaSquadUI.Sharing
S.Initialize()
check(sc.share.transportResumeRequired and prefs.buildSharing and not values[507] and not values[510],
    'Reload restores the persisted manual-resume requirement before a pending ON can override native OFF')
check(S.SetEnabled('builds',true) and not prefs.buildSharingResumeRequired and not sc.share.transportResumeRequired,
    'A successful explicit full-addon ON clears the saved manual-resume requirement')

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
local nativeBuildEnabled=false
sc.share.available=true
sc.share.protocol={IsEnabled=function()return nativeBuildEnabled end}
sc.share.detailProtocol={IsEnabled=function()return nativeBuildEnabled end}
local request={version=3,kind=0,revision=1,checksum=Hash('@Self'),body='@Self'}
for _=1,20 do sc:OnDetailData('group2',request) end
check(scans==0 and sc.share.lastResponseAt==nil,'Native OFF requests cannot capture or consume the future ON response budget')
nativeBuildEnabled=true
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
-- Full-addon consent uses the same queue revocation as the companion. A queued
-- previous-group build stays blocked while solo, then the next grouped share
-- attempt resolves only that deferred choice before publishing a fresh build.
local sharingGrouped=true
local pendingFrames={}
sc.IsGrouped=function()return sharingGrouped end
sc.share.handler={}
local function NativeProtocol(id)
    return {IsEnabled=function()return values[id]end,Send=function(_,data,options)
        if not sharingGrouped then return false end
        if options and options.replaceQueuedMessages then
            for i=#pendingFrames,1,-1 do if pendingFrames[i].id==id then table.remove(pendingFrames,i) end end
        end
        pendingFrames[#pendingFrames+1]={id=id,data=data};return true
    end}
end
sc.share.protocol=NativeProtocol(510);sc.share.detailProtocol=NativeProtocol(507)
LibGroupBroadcast.RegisterHandler=function()return sc.share.handler end
CALLBACK_MANAGER.FireCallbacks=function()LibAddonMenu2:RegisterOptionControls('LibGroupBroadcastOptions',optionTables)end
assert(loadfile('AlphaSquadUI/Core/Sharing.lua'))()
local fullSharing=AlphaSquadUI.Sharing
check(fullSharing.SetEnabled('builds',true),'Full build sender starts with the supported native controls')
sc.share.lastSendAt=-60000
check(sc:ShareLocalSnapshot('queue before group leave') and sc.share.mayHaveQueuedBuildData,
    'Successful full-addon sends record the need to revoke possibly queued data')
for _,frame in ipairs(pendingFrames) do frame.previousGroup=true end
sharingGrouped=false
fullSharing.SetEnabled('builds',false);fullSharing.SetEnabled('builds',true)
check(not values[507] and not values[510] and sc.share.queueRevokeNeedsGroup,
    'Full-addon rapid solo OFF -> ON leaves both native protocols blocked')
sharingGrouped=true;now=now+1600
check(not sc:ShareLocalSnapshot('new group') and not values[507] and not values[510],
    'A grouped publication never silently restores native ON after failed queue revocation')
check(fullSharing.SetEnabled('builds',true) and sc:ShareLocalSnapshot('explicit new group consent')
    and values[507] and values[510] and not sc.share.queueRevokeNeedsGroup,
    'An explicit grouped ON resolves deferred revocation before publishing a fresh build')
for _,frame in ipairs(pendingFrames) do check(not frame.previousGroup,'No previous-group private frame survives full-addon reactivation') end
-- Neutral version-zero fragments are ignored without entering a response flow.
sc:OnDetailData('group2',{version=0,kind=0,revision=0,checksum=0,body=''})
check(not sc.share.outgoingBuild,'A native queue-revocation frame never starts a detail transfer')
fullSharing.SetEnabled('builds',false);sc:InitializeSharing()
local off,offReason,offAvailable=fullSharing.GetStatus('builds')
check(not off and offAvailable and offReason==nil,
    'Registered native controls keep a deliberate OFF available after transport initialization while disabled')
sc.share.controlError='Native OFF failed';values[507]=true
local blocked,blockedReason,blockedAvailable=fullSharing.GetStatus('builds')
check(not blocked and not blockedAvailable and blockedReason=='Native OFF failed',
    'An unsuccessful native OFF keeps its actionable error instead of showing an unqualified OFF')
values[507]=false
local corrected,correctedReason,correctedAvailable=fullSharing.GetStatus('builds')
check(not corrected and correctedAvailable and correctedReason==nil and not sc.share.controlError,
    'A corrected native OFF clears an obsolete error without enabling sharing')
fullSharing.SetEnabled('builds',true)
local originalBuildSet=optionTables[3].controls[2].setFunc
optionTables[3].controls[2].setFunc=function()error('Native pause unavailable')end
check(not fullSharing.SuspendBuildTransport() and not values[507] and values[510],
    'Failed native pause retains successful OFF controls instead of rolling them back ON')
local paused,pausedReason,pausedAvailable=fullSharing.GetStatus('builds')
check(not paused and not pausedAvailable and pausedReason:find('Reload the UI',1,true),
    'A partial failed native pause never reports an unqualified available OFF')
optionTables[3].controls[2].setFunc=originalBuildSet
check(fullSharing.SetEnabled('builds',false),'Explicit OFF can recover once native setters work again')
print('Sharing controls and boundaries: '..checks..' assertions passed')
