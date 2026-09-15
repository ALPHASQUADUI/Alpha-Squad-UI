-- Exercise the actual precombat sharing state machines with three isolated ESO clients.
-- The fake library records queue acceptance; explicit delivery models broadcast loss/order.
local assertions=0
local function check(value,message) assertions=assertions+1;assert(value,message) end
local function copy(value)
    if type(value)~="table" then return value end
    local result={};for key,entry in pairs(value) do result[key]=copy(entry) end;return result
end
local function Load(path,env)
    if setfenv then local chunk=assert(loadfile(path));setfenv(chunk,env);chunk()
    else assert(loadfile(path,"t",env))() end
end
local now,timers,frames,clients,members,online,characters
local function ResetWorld()
    now=10000;timers={};frames={};clients={};members={"@Alice","@Bob","@Carol"}
    online={["@Alice"]=true,["@Bob"]=true,["@Carol"]=true}
    characters={["@Alice"]="Alice Character",["@Bob"]="Bob Character",["@Carol"]="Carol Character"}
end
local function Advance(milliseconds)
    local target=now+milliseconds
    while true do
        local found,at
        for index,timer in ipairs(timers) do
            if timer.at<=target and (not at or timer.at<at) then found,at=index,timer.at end
        end
        if not found then break end
        now=at;local timer=table.remove(timers,found);timer.callback()
    end
    now=target
end
local function Snapshot()
    local itemLink="|H1:item:123456:364:50:0:0:0:0:0:0:0:0:0:0:0:0:-1:0:0:0:0:0:0:0:0|h|h"
    local snapshot={classId=1,role="DD PARSE",supportScore=7,
        equipment={complete=true,slots={},items={},setList={{id=30,mainCount=5,backCount=3}},glyphs={verified=true,armorMissing=0}},
        skills={known=true,primary={},backup={},championKnown=true,champion={}},
        masteries={known=true,eligible=true,selected={{id=1200,rank=1}},learnedIds={},skillLines={},passives={}},
        food={verified=true,active=true,abilityId=440,timeEnds=2000},
        potion={known=true,selectionKnown=true,isPotion=true,link=itemLink,count=100},
        poisons={known=true,items={}},curse={known=true,kind="WEREWOLF",transformed=false},
        capabilities={major_courage={mainBar=true,backBar=false,conditional=true}}}
    snapshot.skills.werewolfKnown=true
    snapshot.skills.werewolf={{slot=3,abilityId=58865,boundAbilityId=58865,rank=4},{slot=8,abilityId=32464,boundAbilityId=32464,rank=4}}
    for slot=0,13 do
        local item=slot<3 and {slot=slot,link=itemLink,enchantHasCharges=true,enchantSuppressedByPoison=false} or nil
        snapshot.equipment.slots[#snapshot.equipment.slots+1]={slot=slot,known=true,empty=item==nil,item=item}
        if item then snapshot.equipment.items[#snapshot.equipment.items+1]=item end
    end
    for index=1,6 do
        snapshot.skills.primary[index]={slot=index+2,abilityId=20000+index,boundAbilityId=20000+index,lineId=44}
        snapshot.skills.backup[index]={slot=index+2,abilityId=30000+index,boundAbilityId=30000+index,lineId=41}
    end
    for index=1,12 do snapshot.skills.champion[index]={slot=index,id=100+index,points=50} end
    for index=1,24 do snapshot.masteries.learnedIds[50000+index]=2 end
    for index=1,3 do snapshot.masteries.skillLines[index]={id=40+index,classId=1,rank=50,active=true,native=true} end
    return snapshot
end
local function NewClient(key,options)
    options=options or {}
    local env=setmetatable({},{__index=_G});env._G=env
    local client={key=key,protocols={},declarations={},registrations=0,options=options}
    clients[key]=client
    local function Key(tag)
        if tag=="player" then return key end
        local index=type(tag)=="string" and tonumber(tag:match("^group(%d+)$"))
        return index and members[index] or ""
    end
    env.GetGameTimeMilliseconds=function() return now end
    env.GetGroupSize=function() return #members end
    env.IsUnitGrouped=function() return #members>0 end
    env.GetGroupUnitTagByIndex=function(index) return "group"..index end
    env.GetUnitDisplayName=Key
    env.GetUnitName=function(tag) return characters[Key(tag)] or "" end
    env.GetUnitClass=function() return "Test class" end
    env.AreUnitsEqual=function(a,b) return Key(a)~="" and Key(a)==Key(b) end
    env.IsUnitOnline=function(tag) return online[Key(tag)]==true end
    env.IsUnitDead=function() return false end
    env.GetAbilityName=function(id) return "Ability "..id end
    env.GetAbilityIcon=function() return "ability.dds" end
    env.GetChampionSkillName=function(id) return "Champion "..id end
    env.GetSkillLineNameById=function(id) return "Line "..id end
    env.GetItemSetName=function() return "Translated set" end
    env.GetItemLinkName=function() return "Translated item" end
    env.GetItemLinkItemId=function() return 123456 end
    env.EVENT_ADD_ON_LOADED=1
    env.EVENT_MANAGER={RegisterForEvent=function() end,UnregisterForEvent=function() end,
        RegisterForUpdate=function() end,UnregisterForUpdate=function() end}
    env.zo_callLater=function(callback,delay) timers[#timers+1]={at=now+delay,callback=callback,owner=key} end
    env.AlphaSquadUI={Modules={SupportCoverage={}}}
    Load("AlphaSquadUI/Modules/SupportCoverage/SupportCoverage.lua",env)
    local SC=env.AlphaSquadUI.Modules.SupportCoverage
    client.SC,client.env=SC,env
    SC.Catalog={effects={major_courage={},minor_courage={},crusher={}},wireV1Keys={"major_courage"},
        wireV2Keys={"major_courage","minor_courage"}}
    SC.sv={enabled=true,experimentalSharing=true,shareData=true}
    SC.initialized=true
    SC.localSnapshot=Snapshot()
    function SC:IsSelf(tag) return env.AreUnitsEqual(tag,"player") end
    function SC:IsOnline(tag) return env.IsUnitOnline(tag) end
    function SC:ScanLocalPlayer() return copy(self.localSnapshot) end
    function SC:ScheduleRefresh(reason) self.lastRefreshReason=reason end
    function SC:Refresh(reason) self.lastRefreshReason=reason end
    function SC:DescribeEquipmentItem(slot,link)
        if link=="" then return nil end
        return {slot=slot,link=link,name="Translated item",setId=30,setName="Translated set",slotName="Equipment",bar="BOTH"}
    end
    function SC:GetChampionDiscipline() return "COMBAT" end
    local LGB={CreateNumericField=function(name) return name end,CreateFlagField=function(name) return name end,
        CreateStringField=function(name) return name end}
    function LGB:RegisterHandler()
        client.registrations=client.registrations+1
        if options.registerError then error("Registration failed") end
        local handler={}
        function handler:DeclareProtocol(id)
            client.declarations[id]=(client.declarations[id] or 0)+1
            local protocol={id=id,enabled=true}
            client.protocols[id]=protocol
            function protocol:AddField() end
            function protocol:OnData(callback) self.callback=callback end
            function protocol:Finalize(config) self.config=config;return options.failFinalize~=id end
            function protocol:IsEnabled() return self.enabled end
            function protocol:Send(payload,config)
                if self.rejectSend then return false end
                frames[#frames+1]={sender=key,id=id,data=copy(payload),at=now,config=copy(config)}
                return true
            end
            return protocol
        end
        return handler
    end
    client.library=LGB
    if not options.missingLibrary then env.LibGroupBroadcast=LGB end
    Load("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageBuildCodec.lua",env)
    Load("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageShare.lua",env)
    Load("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageDetails.lua",env)
    SC:InitializeSharing()
    return client
end
local function Tag(key)
    for index,member in ipairs(members) do if member==key then return "group"..index end end
    return "reticleover"
end
local function Deliver(frame,receiver)
    local protocol=receiver.protocols[frame.id]
    assert(protocol and protocol.callback,"Receiver has no registered callback")
    protocol.callback(Tag(frame.sender),copy(frame.data))
end
local function Take(sender,id,kind)
    for index,frame in ipairs(frames) do
        if (not sender or frame.sender==sender) and (not id or frame.id==id)
            and (kind==nil or frame.data.kind==kind) then return table.remove(frames,index) end
    end
end
local function CountFrames(sender,kind)
    local count=0
    for _,frame in ipairs(frames) do
        if (not sender or frame.sender==sender) and frame.id==507 and frame.data.kind==kind then count=count+1 end
    end
    return count
end
local function PrimeSummary(receiver,sender)
    sender.SC.share.lastSendAt=-60000
    assert(sender.SC:ShareLocalSnapshot("test"))
    Deliver(assert(Take(sender.key,510)),receiver)
    local expanded=Take(sender.key,507,2);if expanded then Deliver(expanded,receiver) end
end
local function WireChunk(receiver,sender,body,revision,index,total)
    local hash=receiver.SC.Details.Hash(receiver.key)
    return {version=3,kind=1,revision=revision,checksum=receiver.SC.Details.Hash(body),
        body=string.char(math.floor(hash/65536),math.floor(hash/256)%256,hash%256,index,total)
            ..body:sub((index-1)*56+1,index*56)}
end
local function ReceiveBody(receiver,sender,body,revision)
    local total=math.ceil(#body/56)
    for index=1,total do receiver.SC:OnDetailData(Tag(sender.key),WireChunk(receiver,sender,body,revision,index,total)) end
end

ResetWorld()
local alice,bob,carol=NewClient("@Alice"),NewClient("@Bob"),NewClient("@Carol")
check(alice.SC.share.available and alice.declarations[507]==1 and alice.declarations[510]==1,
    "Both real sharing protocols initialize exactly once")
check(alice.protocols[507].config.replaceQueuedMessages==false and alice.protocols[510].config.replaceQueuedMessages==true,
    "Detail chunks preserve order while summaries may replace obsolete queued summaries")
check(alice.SC:RequestPlayerBuild("@Bob"),"A current group member can be requested")
local request=assert(Take("@Alice",507,0))
check(request.data.body=="@Bob" and #frames==0,"A build request queues only its addressed request frame")
Deliver(request,carol)
check(#frames==0,"A third group member cannot answer another player's request")
Deliver(request,bob)
local summary=assert(Take("@Bob",510));local expanded=Take("@Bob",507,2)
local chunk=assert(Take("@Bob",507,1))
check(summary.at<=chunk.at and bob.SC.share.lastBuildFingerprint>0,"The sender binds its exact build to a queued summary before chunks")
check(CountFrames("@Bob",1)==0 and bob.SC.share.outgoingBuild.sent==1,"Only one response chunk is queued before acknowledgment")
Deliver(summary,alice);if expanded then Deliver(expanded,alice) end
Deliver(chunk,carol)
check(not carol.SC.peerData["@Bob"] and #frames==0,"An unrequested observer ignores directed build data")
Deliver(chunk,alice)
check(alice.SC.share.incomingBuild.received==1 and not alice.SC.peerData["@Bob"].fullBuild,
    "Partial builds are not exposed as complete")
local acknowledgment=assert(Take("@Alice",507,3))
local wrongAck=copy(acknowledgment);wrongAck.sender="@Carol"
Deliver(wrongAck,bob)
check(not bob.SC.share.outgoingBuild.scheduled,"Another group member cannot acknowledge the requester's chunks")
wrongAck=copy(acknowledgment);wrongAck.data.revision=wrongAck.data.revision+1
Deliver(wrongAck,bob)
check(not bob.SC.share.outgoingBuild.scheduled,"ACKs from a different request revision are ignored")
wrongAck=copy(acknowledgment);wrongAck.data.checksum=(wrongAck.data.checksum+1)%16777215
Deliver(wrongAck,bob)
check(not bob.SC.share.outgoingBuild.scheduled,"An ACK with a corrupted checksum is ignored")
wrongAck=copy(acknowledgment);wrongAck.data.body=string.char(3).."@Bob"
wrongAck.data.checksum=bob.SC.Details.Hash(wrongAck.data.body)
Deliver(wrongAck,bob)
check(not bob.SC.share.outgoingBuild.scheduled,"An ACK cannot skip ahead to an unsent response chunk")
Deliver(acknowledgment,bob);Deliver(acknowledgment,bob)
check(CountFrames("@Bob",1)==0,"Acknowledgment schedules the next chunk instead of immediately flooding the queue")
Advance(1199)
check(CountFrames("@Bob",1)==0,"Next chunk waits until the full 1.2-second minimum")
Advance(1)
local nextChunk=assert(Take("@Bob",507,1))
check(nextChunk.at-chunk.at==1200 and CountFrames("@Bob",1)==0,"Duplicate ACK cannot schedule duplicate chunks")
local chunkTimes={chunk.at,nextChunk.at}
Deliver(nextChunk,alice)
for step=1,64 do
    if alice.SC.peerData["@Bob"].fullBuild then break end
    local ack=assert(Take("@Alice",507,3),"Receiver must acknowledge the next required chunk")
    Deliver(ack,bob);Advance(1200)
    local frame=assert(Take("@Bob",507,1),"Sender should advance one chunk after acknowledgment")
    check(CountFrames("@Bob",1)==0 and #frame.data.body<=61,"Each ACK advances only one bounded response chunk")
    chunkTimes[#chunkTimes+1]=frame.at;Deliver(frame,alice)
end
local full=alice.SC.peerData["@Bob"].fullBuild
check(full and full.skills.primary[1].abilityId==20001 and #full.equipment.slots==14,
    "Request/summary/chunk/ACK flow produces the exact decoded build")
check(full.curse.kind=="WEREWOLF" and full.curse.transformed==false and full.skills.werewolf[2].ultimate
    and full.skills.werewolf[2].rank==4 and full.skills.champion[1].pointsKnown,
    "End-to-end sharing retains Werewolf state, ultimate morph rank and verified Champion allocation")
check(not alice.SC.share.incomingBuild and not bob.SC.share.outgoingBuild,"Completed transfers leave no active sender or receiver")
check(alice.SC:GetPlayerBuildDetails("@Bob")==full,"A fresh matching build is available to the inspector")
for index=2,#chunkTimes do check(chunkTimes[index]-chunkTimes[index-1]>=1200,"Every response interval respects the rate limit") end

-- An unchanged heartbeat retains complete evidence; a changed curse invalidates its fingerprint.
PrimeSummary(alice,bob)
check(alice.SC.peerData["@Bob"].curse==full.curse and alice.SC.peerData["@Bob"].fullBuild==full,
    "A matching heartbeat retains detailed curse and skill evidence")
local beforeForm=bob.SC.share.lastBuildFingerprint
bob.SC.localSnapshot.curse.transformed=true
local changedForm=bob.SC:BuildSharePayload()
check(math.floor(changedForm.cap4/512)~=beforeForm,"Changing Werewolf form invalidates the captured build fingerprint")
bob.SC.localSnapshot.curse.transformed=false
-- Fresh summary, connected identity and the exact build fingerprint bound cached data.
local peer=alice.SC.peerData["@Bob"]
local scannedAt,capturedAt=peer.scannedAt,peer.fullBuildAt
peer.scannedAt=now-75001
check(alice.SC:GetPlayerBuildDetails("@Bob")==nil,"A summary older than 75 seconds cannot authorize a cached build")
peer.scannedAt=now;online["@Bob"]=false
check(alice.SC:GetPlayerBuildDetails("@Bob")==nil,"An offline player's cached build is unavailable")
online["@Bob"]=true;characters["@Bob"]="Bob Other Character"
check(alice.SC:GetPlayerBuildDetails("@Bob")==nil,"Character changes invalidate cached build identity")
characters["@Bob"]="Bob Character";peer.fullBuildAt=now-120001
check(alice.SC:GetPlayerBuildDetails("@Bob")==nil,"A detailed capture older than two minutes expires")
peer.fullBuildAt=capturedAt;peer.buildDetailFingerprint=peer.fullBuildFingerprint%32767+1
check(alice.SC:GetPlayerBuildDetails("@Bob")==nil,"An updated build fingerprint invalidates the old detailed capture")
peer.buildDetailFingerprint=peer.fullBuildFingerprint;members={"@Alice","@Carol"}
check(alice.SC:GetPlayerBuildDetails("@Bob")==nil,"A departed player's cache cannot be opened")
members={"@Alice","@Bob","@Carol"};peer.scannedAt=scannedAt
peer.fullBuildAt=now-119999
PrimeSummary(alice,bob)
check(alice.SC.peerData["@Bob"].fullBuild==full,"The capture stays available until its own expiry boundary")
Advance(2);alice.SC:PrunePeerSharingData()
check(alice.SC.peerData["@Bob"].fullBuild==nil and alice.SC.peerData["@Bob"].skills==nil
    and alice.SC.peerData["@Bob"].capabilities.major_courage~=nil,
    "Periodic pruning expires old detailed coverage between heartbeats while retaining fresh summary facts")
peer=alice.SC.peerData["@Bob"]
peer.fullBuild=full;peer.fullBuildFingerprint=peer.buildDetailFingerprint
peer.fullBuildAt=now-120001
PrimeSummary(alice,bob)
check(alice.SC.peerData["@Bob"].fullBuild==nil and alice.SC.peerData["@Bob"].skills==nil,
    "An unchanged heartbeat cannot prolong an expired detailed capture")
check(alice.SC.peerData["@Bob"].capabilities.major_courage~=nil,
    "Expired details fall back to fresh compatible summary evidence")
online["@Bob"]=false
PrimeSummary(alice,bob)
check(alice.SC.peerData["@Bob"].connected==false,"A native offline result never becomes connected through a fallback")
online["@Bob"]=true
local oldClass,oldFood=bob.SC.localSnapshot.classId,bob.SC.localSnapshot.food.abilityId
bob.SC.localSnapshot.classId=100;bob.SC.localSnapshot.food.abilityId=1048576
local futureIdentity=bob.SC:BuildSharePayload()
check(futureIdentity.classId==0 and futureIdentity.foodId==0,
    "Future IDs outside the summary wire range remain unknown rather than becoming another class or food")
bob.SC.localSnapshot.classId=oldClass;bob.SC.localSnapshot.food.abilityId=oldFood
PrimeSummary(alice,bob)
alice.SC.peerData["@Bob"].scannedAt=now-120001
alice.SC:PrunePeerSharingData()
check(alice.SC.peerData["@Bob"]==nil,"Abandoned peer snapshots are evicted even if membership remains unchanged")
PrimeSummary(alice,bob)

-- Malformed summaries must not partially mutate an existing peer record.
local valid=bob.SC:BuildSharePayload()
local invalidFields={role=-1,classId=16,foodId=1048576,potion=8,missingGlyphs=8,prism=-1,mag=0/0,
    stam=math.huge,health=1.5,supportScore=32,cap1=-1,cap2=math.huge,cap3=0/0,cap4=16777216,set1=-1,set2="0",
    version=4,food="true",foodVerified=0}
for field,value in pairs(invalidFields) do
    local bad=copy(valid);bad[field]=value;local previous=alice.SC.peerData["@Bob"]
    alice.SC:OnPeerShareData("group2",bad)
    check(alice.SC.peerData["@Bob"]==previous,"Malformed summary rejected atomically: "..field)
end
for _,version in ipairs({1,2,3}) do
    local payload=copy(valid);payload.version=version;payload.cap1=3
    check(alice.SC:OnPeerShareData("group2",payload)==true,"Supported build summary version accepted: "..version)
    local received=alice.SC.peerData["@Bob"]
    check(received.capabilities.major_courage~=nil,"Legacy first capability bit retains its meaning")
    check((received.capabilities.minor_courage~=nil)==(version>=2),"Version one cannot read appended capability bits")
    check((received.buildDetailFingerprint~=nil)==(version==3),"Only current summaries claim the detail fingerprint format")
end
local previous=alice.SC.peerData["@Bob"]
alice.SC:OnPeerShareData("reticleover",valid)
alice.SC:OnPeerShareData("player",valid)
check(alice.SC.peerData["@Bob"]==previous and not alice.SC.peerData["@Alice"],"Self and non-group senders cannot inject peer summaries")

-- Directed chunks and acknowledgments are bound to sender, recipient, revision and order.
ResetWorld();alice,bob,carol=NewClient("@Alice"),NewClient("@Bob"),NewClient("@Carol")
PrimeSummary(alice,bob);frames={}
assert(alice.SC:RequestPlayerBuild("@Bob"));frames={}
local pending=alice.SC.share.incomingBuild
local body=assert(bob.SC.BuildCodec.Encode(bob.SC.localSnapshot))
local total=math.ceil(#body/56)
local first=WireChunk(alice,bob,body,pending.revision,1,total)
alice.SC:OnDetailData("group3",first)
check(pending.received==0,"A different group member cannot fulfill the selected player's request")
local wrongRevision=copy(first);wrongRevision.revision=wrongRevision.revision+1
alice.SC:OnDetailData("group2",wrongRevision)
check(pending.received==0,"A response from another request revision is ignored")
local wrongTarget=WireChunk(carol,bob,body,pending.revision,1,total)
alice.SC:OnDetailData("group2",wrongTarget)
check(pending.received==0,"A response addressed to another receiver is ignored")
for _,bad in ipairs({{version=2},{kind=4},{revision=0},{checksum=16777215},{body=string.rep("x",65)}}) do
    local packet=copy(first);for key,value in pairs(bad) do packet[key]=value end
    alice.SC:OnDetailData("group2",packet)
    check(pending.received==0,"Malformed outer detail envelope is rejected")
end
local outOfOrder=WireChunk(alice,bob,body,pending.revision,2,total)
alice.SC:OnDetailData("group2",outOfOrder)
check(pending.received==0,"Out-of-order chunks cannot skip an unreceived fragment")
alice.SC:OnDetailData("group2",first);alice.SC:OnDetailData("group2",first)
check(pending.received==1 and CountFrames("@Alice",3)==1,"A duplicate fragment neither replaces data nor duplicates its ACK")
local changedChecksum=copy(outOfOrder);changedChecksum.checksum=(changedChecksum.checksum+1)%16777215
alice.SC:OnDetailData("group2",changedChecksum)
check(pending.received==1,"Mid-transfer checksum changes cannot join unrelated builds")
local short=copy(outOfOrder);short.body=short.body:sub(1,-2)
alice.SC:OnDetailData("group2",short)
check(pending.received==1,"A non-final short chunk is rejected")

-- A newer advertisement must survive a delayed completion of an older request.
local newer=copy(bob.SC.localSnapshot);newer.skills.primary[1].abilityId=99999
bob.SC.localSnapshot=newer;PrimeSummary(alice,bob)
local newFingerprint=alice.SC.peerData["@Bob"].buildDetailFingerprint
local latestCapture={marker="Newer capture"}
alice.SC.peerData["@Bob"].fullBuild=latestCapture
alice.SC.peerData["@Bob"].fullBuildFingerprint=newFingerprint
for index=2,total do alice.SC:OnDetailData("group2",WireChunk(alice,bob,body,pending.revision,index,total)) end
check(alice.SC.peerData["@Bob"].fullBuild==latestCapture
    and alice.SC.peerData["@Bob"].buildDetailFingerprint==newFingerprint,
    "Late completion cannot replace a newer summary or its associated detailed capture")
check(alice.SC.share.buildStatus:find("changed builds",1,true)~=nil,"Discarded stale completion gives a retry explanation")

for _,reason in ipairs({"summary age","offline","checksum"}) do
    ResetWorld();alice,bob=NewClient("@Alice"),NewClient("@Bob")
    PrimeSummary(alice,bob);frames={};assert(alice.SC:RequestPlayerBuild("@Bob"));frames={}
    local requestRevision=alice.SC.share.incomingBuild.revision
    local captured=assert(bob.SC.BuildCodec.Encode(bob.SC.localSnapshot))
    if reason=="summary age" then alice.SC.peerData["@Bob"].scannedAt=now-75001
    elseif reason=="offline" then online["@Bob"]=false
    else
        -- Keep the advertised checksum while corrupting one transferred payload byte.
        local count=math.ceil(#captured/56)
        for index=1,count do
            local packet=WireChunk(alice,bob,captured,requestRevision,index,count)
            if index==count then packet.body=packet.body:sub(1,-2)..string.char((packet.body:byte(-1)+1)%256) end
            alice.SC:OnDetailData("group2",packet)
        end
    end
    if reason~="checksum" then ReceiveBody(alice,bob,captured,requestRevision) end
    check(not alice.SC.peerData["@Bob"].fullBuild and not alice.SC.share.incomingBuild,
        "An invalid completed transfer is not cached: "..reason)
end

-- Tracking visibility and sender consent have independent lifecycles.
ResetWorld();alice,bob=NewClient("@Alice"),NewClient("@Bob")
PrimeSummary(alice,bob);frames={}
assert(alice.SC:RequestPlayerBuild("@Bob"));local pending=alice.SC.share.incomingBuild
alice.SC:SetEnabled(false)
check(alice.SC.sv.shareData and alice.SC.sv.experimentalSharing,"Dashboard OFF preserves explicit sender consent")
check(alice.SC.share.incomingBuild==pending and alice.SC:MayReceiveBuild("group2"),"Disabling tracking preserves the active shared-data transport")
check(alice.SC:ShareLocalSnapshot("sharing without UI")~=nil,"Transport remains callable when tracking is disabled")

-- Pause and lifecycle cleanup use the real module methods, not mocked reset wrappers.
for _,reason in ipairs({"sharing","experimental","disband","combat"}) do
    ResetWorld();alice,bob=NewClient("@Alice"),NewClient("@Bob")
    PrimeSummary(alice,bob);frames={}
    assert(alice.SC:RequestPlayerBuild("@Bob"));local active=alice.SC.share.incomingBuild
    alice.SC.share.outgoingBuild={updatedAt=now};alice.SC.peerData["@Bob"].fullBuild={marker="Cached"}
    if reason=="module" then alice.SC:SetEnabled(false)
    elseif reason=="sharing" then alice.SC:SetShareData(false)
    elseif reason=="experimental" then alice.SC:SetExperimentalSharing(false)
    elseif reason=="disband" then alice.SC.wasGrouped=true;members={};alice.SC:CheckGroupSession()
    else alice.SC:OnCombatState(true) end
    check(not alice.SC.share.incomingBuild and not alice.SC.share.outgoingBuild,"Lifecycle cancels active transfers: "..reason)
    if reason~="combat" then check(next(alice.SC.peerData)==nil,"Lifecycle clears private peer cache: "..reason) end
    frames={};Advance(21000)
    check(#frames==0 and alice.SC.share.incomingBuild~=active,"Canceled timeout callbacks produce no traffic: "..reason)
    check(alice.SC:RequestPlayerBuild("@Bob")==false and alice.SC:ShareLocalSnapshot("blocked")==false,
        "Disabled, solo and combat states block outgoing traffic: "..reason)
    local before=alice.SC.peerData["@Bob"]
    alice.SC:OnPeerShareData("group2",valid)
    check(alice.SC.peerData["@Bob"]==before,"Blocked states reject incoming summaries: "..reason)
end

-- Lost traffic fails closed; a request timeout never exposes a partially decoded build.
ResetWorld();alice,bob=NewClient("@Alice"),NewClient("@Bob")
assert(alice.SC:RequestPlayerBuild("@Bob"));frames={};Advance(20050)
check(not alice.SC.share.incomingBuild and alice.SC.share.buildStatus:find("No response",1,true),
    "An unanswered request expires with an actionable status")
check(#frames==0,"A timeout does not start an unsolicited retransmission loop")
alice.protocols[507].rejectSend=true
check(alice.SC:RequestPlayerBuild("@Bob")==false and not alice.SC.share.incomingBuild,
    "A rejected request is not presented as an active transfer")
alice.protocols[507].rejectSend=false;alice.protocols[507].enabled=false
check(alice.SC:RequestPlayerBuild("@Bob")==false,"A library-disabled detail protocol cannot send requests")

-- Scheduled chunks must re-check lifecycle state, and an abandoned sender stops blocking summaries.
ResetWorld();alice,bob=NewClient("@Alice"),NewClient("@Bob")
assert(alice.SC:RequestPlayerBuild("@Bob"));Deliver(assert(Take("@Alice",507,0)),bob)
local initial=assert(Take("@Bob",507,1));Deliver(assert(Take("@Bob",510)),alice)
Take("@Bob",507,2);Deliver(initial,alice);Deliver(assert(Take("@Alice",507,3)),bob)
check(bob.SC.share.outgoingBuild.scheduled,"An acknowledged response schedules the next outgoing chunk")
bob.SC:OnCombatState(true);frames={};Advance(1200)
check(#frames==0 and not bob.SC.share.outgoingBuild,"A chunk scheduled before combat is canceled before it can send")
bob.SC:OnCombatState(false);bob.SC.share.outgoingBuild={updatedAt=now-20001}
check(bob.SC:ShareCapabilitySummary()==true and not bob.SC.share.outgoingBuild,
    "An abandoned stream expires so it cannot suppress future capability summaries")

for _,failure in ipairs({510,507}) do
    ResetWorld();local broken=NewClient("@Alice",{failFinalize=failure})
    check(not broken.SC.share.available and broken.SC.share.error~=nil,"Partial registration failure is visible: "..failure)
    broken.SC:InitializeSharing();broken.SC:InitializeSharing()
    check(broken.registrations==1 and broken.declarations[failure]==1,"Partial registration never redeclares a protocol: "..failure)
    check(broken.SC:ShareLocalSnapshot("unavailable")==false and broken.SC:RequestPlayerBuild("@Bob")==false
        and #frames==0,"Partial registration cannot emit half-working sharing traffic: "..failure)
end
ResetWorld();local broken=NewClient("@Alice",{registerError=true})
broken.SC:InitializeSharing()
check(not broken.SC.share.available and broken.registrations==1,"Registration exceptions fail closed without repeated declarations")
ResetWorld();broken=NewClient("@Alice",{missingLibrary=true})
check(not broken.SC.share.available and broken.registrations==0,"A missing optional library leaves the local addon usable")
broken.env.LibGroupBroadcast=broken.library;broken.SC:InitializeSharing()
check(broken.SC.share.available and broken.registrations==1,"A library that becomes available can initialize cleanly")

-- A late packet must not restart a transfer after its inactivity boundary.
ResetWorld();alice,bob=NewClient("@Alice"),NewClient("@Bob")
assert(alice.SC:RequestPlayerBuild("@Bob"));Deliver(assert(Take("@Alice",507,0)),bob)
Deliver(assert(Take("@Bob",510)),alice);Take("@Bob",507,2)
Deliver(assert(Take("@Bob",507,1)),alice)
local lateAck=assert(Take("@Alice",507,3))
frames={};Advance(20001);Deliver(lateAck,bob)
check(bob.SC.share.outgoingBuild==nil and #frames==0,"A late acknowledgment cannot revive an expired outgoing capture")
ResetWorld();alice,bob=NewClient("@Alice"),NewClient("@Bob")
PrimeSummary(alice,bob);assert(alice.SC:RequestPlayerBuild("@Bob"));frames={}
local revision=alice.SC.share.incomingBuild.revision
local captured=assert(bob.SC.BuildCodec.Encode(bob.SC.localSnapshot))
local chunks=math.ceil(#captured/bob.SC.Details.CHUNK_BYTES)
Advance(10000)
alice.SC:OnDetailData("group2",WireChunk(alice,bob,captured,revision,1,chunks))
Advance(20001);frames={}
alice.SC:OnDetailData("group2",WireChunk(alice,bob,captured,revision,2,chunks))
check(alice.SC.share.incomingBuild==nil and not alice.SC.peerData["@Bob"].fullBuild and #frames==0,
    "A chunk arriving after inactivity cannot extend an abandoned partial capture")
ResetWorld();alice=NewClient("@Alice")
alice.protocols[507].IsEnabled=function()error("Library setting unavailable")end
check(alice.SC:RequestPlayerBuild("@Bob")==false and #frames==0,
    "An incompatible native detail setting fails closed without a Lua error")
alice.protocols[510].IsEnabled=function()error("Library setting unavailable")end
check(alice.SC:ShareLocalSnapshot("unavailable setting")==false and #frames==0,
    "An incompatible native summary setting fails closed without a Lua error")
print("Build sharing: "..assertions.." assertions passed")
