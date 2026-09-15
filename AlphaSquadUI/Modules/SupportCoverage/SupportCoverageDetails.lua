-- Precombat build sharing controlled in Libraries. Protocol 507 remains provisional.
-- Stop-and-wait flow control queues only one detail response per active transfer.
local SC=AlphaSquadUI.Modules.SupportCoverage
local Details={ID=507,VERSION=3,MAX_BYTES=64,CHUNK_BYTES=56,MAX_CHUNKS=64,MAX_HASH=16777214,
    FINGERPRINT_MODULUS=32767,CACHE_MS=120000,TIMEOUT_MS=20000,MIN_SEND_MS=1200}
SC.Details=Details
Details.Hash=SC.BuildCodec.Hash
Details.Checksum=Details.Hash

local function Integer(value,minimum,maximum)
    return type(value)=="number" and value%1==0 and value>=minimum and value<=maximum and value or nil
end
local function Enabled(sc)
    return sc.sv and sc.sv.experimentalSharing and sc.sv.shareData
        and not sc.inCombat and not sc.loading and sc:IsGrouped() and sc.share and not sc.share.controlError and sc.share.detailProtocol
end
local function ValidKey(key)
    return type(key)=="string" and #key>1 and #key<=60 and key:match("^@[^%c|]+$")
end
local function TagForKey(sc,key)
    local size=GetGroupSize and GetGroupSize() or 0
    if not Integer(size,0,12) then return nil end
    for index=1,size do
        local tag=GetGroupUnitTagByIndex and GetGroupUnitTagByIndex(index) or "group"..index
        if sc:GetPlayerKey(tag)==key then return tag end
    end
end
local function Frame(sc,kind,revision,checksum,body)
    if not Enabled(sc) or type(body)~="string" or #body>Details.MAX_BYTES then return false end
    local p=sc.share.detailProtocol
    if p.IsEnabled then
        local ok,enabled=pcall(p.IsEnabled,p)
        if not ok or enabled~=true then return false end
    end
    local ok,sent=pcall(p.Send,p,{version=Details.VERSION,kind=kind,revision=revision,checksum=checksum,body=body},
        {isRelevantInCombat=false,replaceQueuedMessages=false})
    if ok and sent==true then sc.share.mayHaveQueuedBuildData=true end
    return ok and sent==true
end
local function PackHash(hash)
    return string.char(math.floor(hash/65536),math.floor(hash/256)%256,hash%256)
end
local function UnpackHash(body)
    local a,b,c=body:byte(1,3)
    return a and b and c and a*65536+b*256+c or nil
end
local function EffectKeys()
    local keys={}
    for key in pairs(SC.Catalog.effects or {}) do keys[#keys+1]=key end
    table.sort(keys)
    return keys
end

-- Expanded static catalog mask supplements the immutable legacy build masks.
-- A schema mismatch is ignored rather than interpreting another client's indices.
function SC:ShareCapabilitySummary()
    if not Enabled(self) or not self.localSnapshot then return false end
    if self.share.outgoingBuild and self.NowMs()-self.share.outgoingBuild.updatedAt>Details.TIMEOUT_MS then
        self.share.outgoingBuild=nil
    end
    if self.share.outgoingBuild then return false end
    local keys,bytes=EffectKeys(),{}
    if #keys>256 then return false end
    bytes[1]=PackHash(Details.Hash(table.concat(keys,"|")))
    for offset=1,#keys,8 do
        local mask=0
        for bit=0,7 do if self.localSnapshot.capabilities[keys[offset+bit]] then mask=mask+2^bit end end
        bytes[#bytes+1]=string.char(mask)
    end
    local body=table.concat(bytes)
    return Frame(self,2,self.share.lastBuildFingerprint or 1,Details.Hash(body),body)
end

function SC:CancelBuildDetailTransfer(reason)
    if not self.share then return end
    self.share.transferGeneration=(self.share.transferGeneration or 0)+1
    self.share.outgoingBuild=nil
    if self.share.incomingBuild then self.share.buildStatus=reason or "Build request interrupted; request again out of combat." end
    self.share.incomingBuild=nil
end

function SC:ResetBuildDetailState()
    self:CancelBuildDetailTransfer()
    if not self.share then return end
    self.share.requestedKey=nil;self.share.buildStatus=nil
    self.share.lastResponseAt=nil;self.share.lastRequestAt=nil;self.share.preparedBuildBody=nil
    for _,peer in pairs(self.peerData or {}) do
        peer.fullBuild=nil;peer.fullBuildAt=nil;peer.fullBuildFingerprint=nil
    end
end

function SC:GetBuildDetailStatus(key)
    local _,status=self:GetPlayerBuildDetails(key)
    return status
end
function SC:GetPlayerBuildDetails(key)
    if key==self:GetPlayerKey("player") then return self.localSnapshot,"Local build" end
    local tag=TagForKey(self,key)
    if not tag then return nil,"Player is no longer in the group." end
    local peer=self.peerData and self.peerData[key]
    if self.IsOnline and self:IsOnline(tag)~=true then return nil,"Player is offline or unavailable." end
    if not peer or self.NowMs()-(peer.scannedAt or 0)>75000 then return nil,"Waiting for a fresh build summary from this player." end
    local character=GetUnitName and GetUnitName(tag) or ""
    if peer.characterName and character~="" and peer.characterName~=character then return nil,"Player changed character. Request a fresh build." end
    local pending=self.share and self.share.incomingBuild
    if pending and pending.key==key then
        if self.NowMs()-pending.updatedAt>Details.TIMEOUT_MS then
            self.share.incomingBuild=nil
            self.share.buildStatus="No response. Check that the player enabled compatible build sharing, then request again."
        else return nil,string.format("Receiving build: %d / %d",pending.received or 0,pending.total or 0) end
    end
    if peer and peer.fullBuild and self.NowMs()-(peer.fullBuildAt or 0)<=Details.CACHE_MS
        and (not peer.buildDetailFingerprint or peer.fullBuildFingerprint==peer.buildDetailFingerprint) then
        return peer.fullBuild,"Shared build — captured before combat"
    end
    if peer and peer.fullBuild then return nil,"Build changed or expired. Request a fresh build." end
    return nil,self.share and self.share.requestedKey==key and self.share.buildStatus
        or "No shared build. The player needs compatible build sharing enabled."
end

function SC:RequestPlayerBuild(key)
    if key==self:GetPlayerKey("player") then return true,"Local build" end
    if not ValidKey(key) or not TagForKey(self,key) then return false,"Select a current group member." end
    if not Enabled(self) then return false,"Enable build sharing and LibGroupBroadcast; requests are available out of combat." end
    local now=self.NowMs()
    if self.share.incomingBuild and self.share.incomingBuild.key==key
        and now-self.share.incomingBuild.updatedAt<Details.TIMEOUT_MS then return false,"Build request is already in progress." end
    if now-(self.share.lastRequestAt or -60000)<2500 then return false,"Please wait briefly before requesting another build." end
    self.share.requestRevision=((self.share.requestRevision or math.floor(now)%65534)%65534)+1
    local revision=self.share.requestRevision
    if not Frame(self,0,revision,Details.Hash(key),key) then return false,"Build request could not be queued." end
    self.share.lastRequestAt=now
    self.share.incomingBuild={key=key,revision=revision,updatedAt=now,received=0,parts={}}
    self.share.requestedKey=key
    self.share.buildStatus="Waiting for the selected player's compatible sender."
    local pending=self.share.incomingBuild
    zo_callLater(function()
        if SC.share and SC.share.incomingBuild==pending and SC.NowMs()-pending.updatedAt>=Details.TIMEOUT_MS then
            SC.share.incomingBuild=nil;SC.share.buildStatus="No response. Check the player's sharing settings and request again."
            SC:ScheduleRefresh("build request timeout",100)
        end
    end,Details.TIMEOUT_MS+50)
    return true,self.share.buildStatus
end

local function SendChunk(sc,stream,index)
    if not Enabled(sc) or sc.share.outgoingBuild~=stream or not TagForKey(sc,stream.requester)
        or sc.NowMs()-stream.updatedAt>Details.TIMEOUT_MS then return end
    local start=(index-1)*Details.CHUNK_BYTES+1
    local fragment=stream.body:sub(start,start+Details.CHUNK_BYTES-1)
    local body=PackHash(stream.targetHash)..string.char(index,stream.total)..fragment
    if Frame(sc,1,stream.revision,stream.checksum,body) then
        stream.sent=index;stream.sentAt=sc.NowMs();stream.updatedAt=stream.sentAt
        if index==stream.total then sc.share.outgoingBuild=nil end
    else sc.share.outgoingBuild=nil end
end

local function OnRequest(sc,tag,data)
    if not ValidKey(data.body) or data.body~=sc:GetPlayerKey("player") or data.checksum~=Details.Hash(data.body) then return end
    local now=sc.NowMs()
    local old=sc.share.outgoingBuild
    if old and now-old.updatedAt<=Details.TIMEOUT_MS then return end
    if now-(sc.share.lastResponseAt or -60000)<20000 then return end
    if not sc.ScanLocalPlayer then return end
    -- Rate-limit attempts too: unreadable native state must not permit a peer
    -- to trigger an expensive failed capture on every incoming request.
    sc.share.lastResponseAt=now
    local scanned,snapshot=pcall(sc.ScanLocalPlayer,sc)
    if not scanned or type(snapshot)~="table" then
        sc.share.detailError="Build capture unavailable. Try again after the current transition.";return
    end
    local encoded,body,errorText=pcall(sc.BuildCodec.Encode,snapshot)
    if not encoded then sc.share.detailError="Build capture could not be encoded.";return end
    sc.localSnapshot=snapshot
    if not body or #body>Details.CHUNK_BYTES*Details.MAX_CHUNKS then
        sc.share.detailError=errorText or "Build exceeds the sharing size limit.";return
    end
    sc.share.lastResponseAt=now
    -- Bind the capture to a freshly queued summary before starting its chunks.
    sc.share.lastSendAt=-60000
    if not sc:ShareLocalSnapshot("requested build") then return end
    local requester=sc:GetPlayerKey(tag)
    local stream={body=body,total=math.ceil(#body/Details.CHUNK_BYTES),checksum=Details.Hash(body),revision=data.revision,
        requester=requester,targetHash=Details.Hash(requester),updatedAt=now,sent=0}
    sc.share.outgoingBuild=stream
    SendChunk(sc,stream,1)
end

local function OnAcknowledgment(sc,tag,data)
    local stream=sc.share.outgoingBuild
    if stream and sc.NowMs()-stream.updatedAt>Details.TIMEOUT_MS then
        sc.share.outgoingBuild=nil;return
    end
    if not stream or stream.requester~=sc:GetPlayerKey(tag) or stream.revision~=data.revision
        or data.checksum~=Details.Hash(data.body) or #data.body<2 then return end
    local nextIndex=data.body:byte(1)
    if data.body:sub(2)~=sc:GetPlayerKey("player") or nextIndex~=(stream.sent or 0)+1 or nextIndex>stream.total then return end
    if stream.scheduled then return end
    stream.updatedAt=sc.NowMs();stream.scheduled=true
    local delay=math.max(0,Details.MIN_SEND_MS-(sc.NowMs()-(stream.sentAt or 0)))
    zo_callLater(function()
        if SC.share and SC.share.outgoingBuild==stream then stream.scheduled=false;SendChunk(SC,stream,nextIndex) end
    end,delay)
end

local function OnChunk(sc,tag,data)
    local pending=sc.share.incomingBuild
    if not pending or pending.key~=sc:GetPlayerKey(tag) or pending.revision~=data.revision or #data.body<6 then return end
    if sc.NowMs()-pending.updatedAt>Details.TIMEOUT_MS then
        sc.share.incomingBuild=nil;sc.share.buildStatus="Build transfer timed out; request again."
        sc:ScheduleRefresh("build transfer timeout",100)
        return
    end
    if UnpackHash(data.body)~=Details.Hash(sc:GetPlayerKey("player")) then return end
    local index,total=data.body:byte(4,5)
    if index<1 or total<1 or total>Details.MAX_CHUNKS or index>total or index~=(pending.received or 0)+1 then return end
    if pending.total and (pending.total~=total or pending.checksum~=data.checksum) then return end
    local fragment=data.body:sub(6)
    if #fragment>Details.CHUNK_BYTES or index<total and #fragment~=Details.CHUNK_BYTES then return end
    pending.total=total;pending.checksum=data.checksum;pending.parts[index]=fragment
    pending.received=index;pending.updatedAt=sc.NowMs()
    if index<total then
        local acknowledgment=string.char(index+1)..pending.key
        if not Frame(sc,3,pending.revision,Details.Hash(acknowledgment),acknowledgment) then
            sc.share.incomingBuild=nil;sc.share.buildStatus="Build transfer interrupted; request again."
        end
        sc:ScheduleRefresh("build transfer progress",150)
        return
    end
    sc.share.incomingBuild=nil
    local body=table.concat(pending.parts)
    if Details.Hash(body)~=pending.checksum then sc.share.buildStatus="Build verification failed; request again.";return end
    local snapshot=sc.BuildCodec.Decode(body)
    if not snapshot then sc.share.buildStatus="Incompatible or incomplete build; update both senders.";return end
    local peer=sc.peerData[pending.key]
    local fingerprint=pending.checksum%Details.FINGERPRINT_MODULUS+1
    if not peer or peer.buildDetailFingerprint~=fingerprint
        or sc.NowMs()-(peer.scannedAt or 0)>75000 or sc:IsOnline(tag)~=true then
        sc.share.buildStatus="The player changed builds or became unavailable during transfer. Request a fresh build."
        sc:ScheduleRefresh("discarded stale build",100)
        return
    end
    snapshot.displayName=pending.key;snapshot.unitTag=tag;snapshot.characterName=peer.characterName
    snapshot.className=peer.className;snapshot.role=peer.role;snapshot.asui=true;snapshot.dataQuality="SHARED BUILD"
    snapshot.scannedAt=sc.NowMs();snapshot.connected=sc:IsOnline(tag);snapshot.dead=IsUnitDead and IsUnitDead(tag) or false
    peer.fullBuild=snapshot;peer.fullBuildAt=sc.NowMs();peer.fullBuildFingerprint=fingerprint
    -- Keep the latest summary identity; never overwrite a newer advertisement.
    peer.asui=true;peer.buildVerified=true;peer.scannedAt=sc.NowMs()
    peer.capabilities=snapshot.capabilities;peer.equipment=snapshot.equipment;peer.skills=snapshot.skills
    peer.masteries=snapshot.masteries;peer.curse=snapshot.curse;peer.food=snapshot.food;peer.potion=snapshot.potion
    peer.dataQuality="SHARED BUILD";sc.peerData[pending.key]=peer
    sc.share.buildStatus="Shared build — captured before combat"
    sc:ScheduleRefresh("received complete build",100)
end

function SC:OnDetailData(tag,data)
    if not self:MayReceiveBuild(tag) or type(data)~="table" or data.version~=Details.VERSION
        or not Integer(data.kind,0,3) or not Integer(data.revision,1,65535)
        or not Integer(data.checksum,0,Details.MAX_HASH) or type(data.body)~="string" or #data.body>Details.MAX_BYTES then return end
    self:PrunePeerSharingData()
    if data.kind==0 then OnRequest(self,tag,data)
    elseif data.kind==1 then OnChunk(self,tag,data)
    elseif data.kind==3 then OnAcknowledgment(self,tag,data)
    elseif data.kind==2 then
        if data.checksum~=Details.Hash(data.body) then return end
        local keys=EffectKeys()
        if #data.body~=3+math.ceil(#keys/8) or UnpackHash(data.body)~=Details.Hash(table.concat(keys,"|")) then return end
        local key=self:GetPlayerKey(tag)
        local peer=self.peerData[key]
        if not peer then return end
        if peer.buildDetailFingerprint and peer.buildDetailFingerprint~=data.revision then return end
        local capabilities={}
        for index,effect in ipairs(keys) do
            local byte=data.body:byte(4+math.floor((index-1)/8))
            if math.floor(byte/2^((index-1)%8))%2==1 then
                capabilities[effect]={sources={["Shared build"]=true},evidence="PEER_CAPABILITY_HINT"}
            end
        end
        peer.summaryCapabilities=capabilities
        if not peer.fullBuild or peer.fullBuildFingerprint~=data.revision then peer.capabilities=capabilities end
        self:ScheduleRefresh("shared capabilities",100)
    end
end

function SC:InitializeDetailSharing(LGB,handler)
    if self.share.detailProtocol or self.share.detailRegistrationAttempted then return end
    self.share.detailRegistrationAttempted=true
    local ok,protocol=pcall(function()
        local p=handler:DeclareProtocol(Details.ID,"AlphaSquadSupportDetails")
        p:AddField(LGB.CreateNumericField("version",{minValue=0,maxValue=7}))
        p:AddField(LGB.CreateNumericField("kind",{minValue=0,maxValue=3}))
        p:AddField(LGB.CreateNumericField("revision",{minValue=0,maxValue=65535}))
        p:AddField(LGB.CreateNumericField("checksum",{minValue=0,maxValue=16777215}))
        p:AddField(LGB.CreateStringField("body",{maxLength=Details.MAX_BYTES}))
        p:OnData(function(tag,data) SC:OnDetailData(tag,data) end)
        assert(p:Finalize({isRelevantInCombat=false,replaceQueuedMessages=false}),"Build detail protocol unavailable")
        return p
    end)
    if ok then self.share.detailProtocol=protocol else self.share.detailError=tostring(protocol) end
end
