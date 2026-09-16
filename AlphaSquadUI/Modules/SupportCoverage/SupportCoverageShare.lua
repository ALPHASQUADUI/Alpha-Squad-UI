-- Ąlpha Şquad UI - Support Coverage compact group sharing
-- Protocol IDs remain provisional; conflicting registration fails closed.
-- Sharing starts OFF on a fresh installation and follows Libraries controls.

local SC = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end

local Catalog = SC.Catalog
local LGB_BUILD_PROTOCOL_ID = 510
local LGB_BUILD_PROTOCOL_NAME = "AlphaSquadSupportCoverage"
local MASK_BITS = 24
local MASK_MAX = 16777215 -- 2^24 - 1
local BUILD_VERSION = 3
-- Keep the existing highest set2 bit for glyph-scan completeness.
local GLYPHS_VERIFIED_BIT = 23
local SUMMARY_FIELDS={"version","role","classId","food","foodVerified","foodId","potion","missingGlyphs",
    "prism","mag","stam","health","supportScore","cap1","cap2","cap3","cap4","set1","set2"}

local function IsInteger(value, minimum, maximum)
    return type(value)=="number" and value%1==0 and value>=minimum and value<=maximum
end

local function BoundedInteger(value, minimum, maximum)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge then return minimum end
    return math.floor(math.max(minimum,math.min(maximum,value)))
end

SC.share = SC.share or {
    available = false,
    protocol = nil,
    handler = nil,
    lastSendAt = -60000,
    error = nil,
}

local ROLE_TO_ID = {
    ["UNKNOWN"] = 0,
    ["MT"] = 1,
    ["OT"] = 2,
    ["HEAL"] = 3,
    ["DD PARSE"] = 4,
    ["DD SUPPORT"] = 5,
    ["MT/OT"] = 6,
    ["H1"] = 7,
    ["H2"] = 8,
}
local ID_TO_ROLE = {}
for name, id in pairs(ROLE_TO_ID) do ID_TO_ROLE[id] = name end

local function BitSet(mask, bitIndex)
    if bitIndex < 0 or bitIndex >= MASK_BITS then return mask end
    local flag = 2 ^ bitIndex
    if math.floor(mask / flag) % 2 == 0 then mask = mask + flag end
    return mask
end

local function BitHas(mask, bitIndex)
    if bitIndex < 0 or bitIndex >= MASK_BITS then return false end
    local flag = 2 ^ bitIndex
    return math.floor((tonumber(mask) or 0) / flag) % 2 == 1
end

local function Normalize(value)
    if AlphaSquadUI.Utils and AlphaSquadUI.Utils.Normalize then
        return AlphaSquadUI.Utils.Normalize(value)
    end
    return string.lower(tostring(value or ""))
end

local function BuildEffectIndex()
    -- Protocol v2 only appends to the immutable v1 indices. UI sorting must never
    -- change this wire format.
    local keys = Catalog and (Catalog.wireV2Keys or Catalog.wireV1Keys) or {}
    local map = {}
    for index, key in ipairs(keys) do map[key] = index - 1 end
    return keys, map
end

local EFFECT_KEYS, EFFECT_INDEX = BuildEffectIndex()
local V1_EFFECT_COUNT = Catalog and #(Catalog.wireV1Keys or {}) or 0

local function EncodeCapabilities(capabilities)
    local masks = {0, 0, 0, 0}
    for key in pairs(capabilities or {}) do
        local index = EFFECT_INDEX[key]
        if index then
            local maskIndex = math.floor(index / MASK_BITS) + 1
            local bitIndex = index % MASK_BITS
            if masks[maskIndex] ~= nil then
                masks[maskIndex] = BitSet(masks[maskIndex], bitIndex)
            end
        end
    end
    return masks
end

local function DecodeCapabilities(data)
    local result = {}
    local masks = {
        tonumber(data.cap1) or 0,
        tonumber(data.cap2) or 0,
        tonumber(data.cap3) or 0,
        tonumber(data.cap4) or 0,
    }
    local count = data.version == 1 and V1_EFFECT_COUNT or #EFFECT_KEYS
    for index = 1, count do
        local key = EFFECT_KEYS[index]
        local zero = index - 1
        local maskIndex = math.floor(zero / MASK_BITS) + 1
        local bitIndex = zero % MASK_BITS
        if masks[maskIndex] and BitHas(masks[maskIndex], bitIndex) then
            result[key] = {sources={["ASUI peer"] = true}}
        end
    end
    return result
end

local function ClassifyPotion(snapshot)
    local potion = snapshot and snapshot.potion
    if not potion or not potion.known then return 0 end
    local function Plain(value)
        return Normalize(tostring(value or ""):gsub("|c%x%x%x%x%x%x",""):gsub("|r",""):gsub("%^.*$",""))
    end
    local text=Plain(potion.effects)
    local function HasEffect(key)
        local id=Catalog and Catalog.visualAbilityIds and Catalog.visualAbilityIds[key]
        if not id or type(GetAbilityName)~="function" then return false end
        local ok,name=pcall(GetAbilityName,id)
        name=ok and Plain(name) or ""
        return name~="" and text:find(name,1,true)~=nil
    end
    -- These are description hints, never proof of consumption or group buffs.
    -- Native names follow the ESO client language, independent of addon UI.
    if HasEffect("minor_heroism") or HasEffect("major_heroism") then return 4 end
    if HasEffect("major_sorcery") then return 2 end
    if HasEffect("major_brutality") then return 3 end
    if HasEffect("major_fortitude") and HasEffect("major_intellect") and HasEffect("major_endurance") then return 1 end
    return 5
end

local POTION_LABELS = {
    [0] = "UNKNOWN",
    [1] = "TRI-STAT",
    [2] = "SPELL POWER",
    [3] = "WEAPON POWER",
    [4] = "HEROISM",
    [5] = "OTHER",
}

function SC:BuildSharePayload(prepared)
    local s = self.localSnapshot
    if not s then return nil end

    local caps = EncodeCapabilities(s.capabilities)
    local body
    if self.BuildCodec then
        -- A requested capture is encoded and validated before any traffic.
        -- Reuse only that exact local snapshot's body, never a previous capture.
        if type(prepared)=="table" and prepared.snapshot==s and type(prepared.body)=="string"
            and #prepared.body>=2 and #prepared.body<=self.BuildCodec.MAX_BYTES then
            body=prepared.body
        else body=self.BuildCodec.Encode(s) end
    end
    if body then caps[4] = (caps[4] or 0) + (self.BuildCodec.Hash(body) % 32767 + 1) * 512 end
    self.share.preparedBuildBody = body
    local sets = {0,0} -- Exact native set identities are sent only in requested builds.
    local glyphs = s.equipment and s.equipment.glyphs or {}
    local food = s.food or {}
    if glyphs.verified == true then sets[2] = BitSet(sets[2], GLYPHS_VERIFIED_BIT) end

    return {
        version = BUILD_VERSION,
        role = ROLE_TO_ID[s.role] or 0,
        classId = IsInteger(s.classId, 0, 15) and s.classId or 0,
        food = food.active == true,
        foodVerified = food.verified == true,
        foodId = IsInteger(food.abilityId, 0, 1048575) and food.abilityId or 0,
        potion = ClassifyPotion(s),
        missingGlyphs = BoundedInteger(glyphs.armorMissing, 0, 7),
        prism = BoundedInteger(glyphs.prismatic, 0, 7),
        mag = BoundedInteger(glyphs.magicka, 0, 7),
        stam = BoundedInteger(glyphs.stamina, 0, 7),
        health = BoundedInteger(glyphs.health, 0, 7),
        supportScore = BoundedInteger(s.supportScore, 0, 31),
        cap1 = caps[1] or 0,
        cap2 = caps[2] or 0,
        cap3 = caps[3] or 0,
        cap4 = caps[4] or 0,
        set1 = sets[1] or 0,
        set2 = sets[2] or 0,
    }
end

function SC:OnPeerShareData(unitTag, data)
    if not self:MayReceiveBuild(unitTag) then return end
    if not unitTag or type(data) ~= "table" or (data.version ~= 1 and data.version ~= 2 and data.version ~= BUILD_VERSION) then return end
    for index=1,4 do
        local value=data["cap"..index]
        if type(value)~="number" or value<0 or value>MASK_MAX or value%1~=0 then return end
    end
    for _,field in ipairs({"set1","set2"}) do if not IsInteger(data[field],0,MASK_MAX) then return end end
    for field,maximum in pairs({role=8,classId=15,foodId=1048575,potion=7,missingGlyphs=7,
        prism=7,mag=7,stam=7,health=7,supportScore=31}) do
        if not IsInteger(data[field],0,maximum) then return end
    end
    if type(data.food)~="boolean" or type(data.foodVerified)~="boolean" then return end
    local pruned=self:PrunePeerSharingData()
    local key = self:GetPlayerKey(unitTag)
    if type(key)~="string" or #key<2 or #key>60 or not key:match("^@[^%c|]+$") then return end
    local previous = self.peerData[key]
    local characterName=GetUnitName and GetUnitName(unitTag) or ""
    local same=previous and previous.characterName==characterName and previous.summaryWire
    if same then
        for _,field in ipairs(SUMMARY_FIELDS) do
            if previous.summaryWire[field]~=data[field] then same=false;break end
        end
    end
    if same then
        -- Identical heartbeats refresh presence without rebuilding the roster.
        local wasStale=self.NowMs()-(previous.scannedAt or 0)>75000
        if self.NowMs()-(previous.scannedAt or 0)>=1000 then previous.scannedAt=self.NowMs() end
        local connected=self.IsOnline and self:IsOnline(unitTag)
        local dead=IsUnitDead and IsUnitDead(unitTag) or false
        local changed=previous.connected~=connected or previous.dead~=dead
        previous.connected,previous.dead,previous.unitTag=connected,dead,unitTag
        if changed or wasStale or pruned then self:ScheduleRefresh("peer availability",100) end
        return true
    end
    if not self:AcceptBuildPacket(key,"summary") then return end

    local foodId = tonumber(data.foodId) or 0
    local foodName = ""
    if foodId > 0 and GetAbilityName then foodName = GetAbilityName(foodId) or "" end

    self.peerData[key] = {
        protocolVersion = tonumber(data.version) or 0,
        catalogPatch = self.catalogPatch,
        displayName = key,
        characterName = characterName,
        classId = tonumber(data.classId) or 0,
        className = GetUnitClass and GetUnitClass(unitTag) or "",
        role = ID_TO_ROLE[tonumber(data.role) or 0] or "UNKNOWN",
        supportScore = tonumber(data.supportScore) or 0,
        dataQuality = "ASUI",
        buildVerified = true,
        asui = true,
        connected = self.IsOnline and self:IsOnline(unitTag),
        dead = IsUnitDead and IsUnitDead(unitTag) or false,
        capabilities = DecodeCapabilities(data),
        equipment = {
            complete = false,
            setList = {}, -- Legacy name-index hints are not safe across catalog revisions.
            glyphs = {
                verified = data.version >= 2 and BitHas(data.set2, GLYPHS_VERIFIED_BIT),
                armorMissing = tonumber(data.missingGlyphs) or 0,
                prismatic = tonumber(data.prism) or 0,
                magicka = tonumber(data.mag) or 0,
                stamina = tonumber(data.stam) or 0,
                health = tonumber(data.health) or 0,
            },
        },
        food = {
            active = data.food == true,
            verified = data.foodVerified == true,
            abilityId = foodId,
            name = foodName,
            source = "ASUI peer",
        },
        potion = {
            known = (tonumber(data.potion) or 0) > 0,
            kind = POTION_LABELS[tonumber(data.potion) or 0] or "UNKNOWN",
        },
        scannedAt = self.NowMs(),
        unitTag = unitTag,
    }

    local peer = self.peerData[key]
    peer.summaryWire={}
    for _,field in ipairs(SUMMARY_FIELDS) do peer.summaryWire[field]=data[field] end
    -- Retain bounded summary facts independently so detail expiry can remove
    -- exact items/skills immediately without losing a still-fresh summary.
    peer.summaryCapabilities,peer.summaryEquipment=peer.capabilities,peer.equipment
    peer.summaryFood,peer.summaryPotion=peer.food,peer.potion
    peer.buildDetailFingerprint = data.version == 3 and math.floor(data.cap4 / 512) or nil
    if previous and previous.fullBuild and previous.fullBuildFingerprint == peer.buildDetailFingerprint
        and previous.characterName == peer.characterName
        and self.NowMs()-(previous.fullBuildAt or 0)<=(self.Details and self.Details.CACHE_MS or 120000) then
        peer.fullBuild, peer.fullBuildAt, peer.fullBuildFingerprint = previous.fullBuild, previous.fullBuildAt, previous.fullBuildFingerprint
        peer.capabilities = previous.fullBuild.capabilities
        peer.equipment, peer.skills, peer.masteries = previous.fullBuild.equipment, previous.fullBuild.skills, previous.fullBuild.masteries
        peer.curse = previous.fullBuild.curse
    end
    if previous and previous.characterName==peer.characterName and previous.buildDetailFingerprint==peer.buildDetailFingerprint then
        peer.capabilityWire,peer.capabilityRevision=previous.capabilityWire,previous.capabilityRevision
        if previous.capabilityWire then
            peer.summaryCapabilities=previous.summaryCapabilities
            if not peer.fullBuild then peer.capabilities=peer.summaryCapabilities end
        end
    end
    self:ScheduleRefresh("peer data", 100)
    return true
end


local function Call(fn,...)
    if type(fn)~="function" then return nil end
    local ok,a=pcall(fn,...)
    if ok then return a end
end

function SC:IsCurrentGroupMember(tag)
    if type(tag)~="string" or not self:IsGrouped() then return false end
    local size=BoundedInteger(Call(GetGroupSize),0,12)
    for index=1,size do
        local other=Call(GetGroupUnitTagByIndex,index) or ("group"..index)
        if other==tag or Call(AreUnitsEqual,other,tag)==true then return true end
    end
    return false
end

-- Keep transient peer state bounded even when Dashboard tracking is OFF.
function SC:PrunePeerSharingData()
    local current={}
    local changed=false
    local size=self:IsGrouped() and BoundedInteger(Call(GetGroupSize),0,12) or 0
    for index=1,size do
        local tag=Call(GetGroupUnitTagByIndex,index) or ("group"..index)
        local key=self:GetPlayerKey(tag)
        if key and key~="" then current[key]=true end
    end
    for key,peer in pairs(self.peerData or {}) do
        if not current[key] or self.NowMs()-(peer.scannedAt or 0)>120000 then self.peerData[key]=nil;changed=true
        elseif peer.fullBuild and self.NowMs()-(peer.fullBuildAt or 0)>(self.Details and self.Details.CACHE_MS or 120000) then
            changed=true
            peer.fullBuild,peer.fullBuildAt,peer.fullBuildFingerprint=nil,nil,nil
            peer.capabilities,peer.equipment=peer.summaryCapabilities or {},peer.summaryEquipment
            peer.skills,peer.masteries,peer.curse,peer.poisons,peer.mundus=nil,nil,nil,nil,nil
            peer.food,peer.potion=peer.summaryFood or {active=false,verified=false},peer.summaryPotion
            peer.dataQuality="ASUI"
        end
    end
    local share=self.share
    if share then
        for key in pairs(share.receiveBudgets or {}) do if not current[key] then share.receiveBudgets[key]=nil end end
        if share.outgoingBuild and not current[share.outgoingBuild.requester] then
            share.outgoingBuild.body=nil;share.outgoingBuild=nil
        end
        if share.incomingBuild and not current[share.incomingBuild.key] then
            share.incomingBuild.parts={}
            share.incomingBuild=nil;share.buildStatus="Player left the group."
        end
        if share.requestedKey and not current[share.requestedKey] then share.requestedKey=nil end
    end
    return changed
end

-- Fixed-size budgets follow current membership, never arbitrary packet keys.
-- Normal senders advertise at most once per 1.5 seconds; a small burst also
-- permits a requested snapshot and its companion capability mask.
function SC:AcceptBuildPacket(key,kind)
    self.share.receiveBudgets=self.share.receiveBudgets or {}
    local peer=self.share.receiveBudgets[key]
    if not peer then peer={};self.share.receiveBudgets[key]=peer end
    local now=self.NowMs()
    local budget=peer[kind]
    if not budget or now-budget.at>=1000 then budget={at=now,count=0};peer[kind]=budget end
    if budget.count>=8 then return false end
    budget.count=budget.count+1
    return true
end

-- Only our two protocols are replaced. LGB's relevance flag prioritizes combat
-- traffic; it is not a guarantee that already queued build bytes stay unsent.
function SC:PauseBuildSharing(reason)
    if not self.share then return true end
    self.share.transportPaused=true
    if self.CancelBuildDetailTransfer then self:CancelBuildDetailTransfer(reason) end
    local cleared=true
    if self.share.mayHaveQueuedBuildData or self.share.queueRevokeFailed then cleared=self:ClearQueuedBuildMessages() end
    if not cleared then
        local sharing=AlphaSquadUI.Sharing
        if sharing and sharing.SuspendBuildTransport then sharing.SuspendBuildTransport() end
        self.share.pauseError="Queued build data could not be cleared. Re-enable sharing after joining a group, or reload the UI."
    end
    return cleared
end

function SC:ResumeBuildSharing()
    if not self.share or self.inCombat or self.loading or not self:IsGrouped() then return false end
    local wasPaused=self.share.transportPaused
    if self.share.queueRevokeFailed and not self:ClearQueuedBuildMessages() then return false end
    self.share.transportPaused=nil
    local sharing=AlphaSquadUI.Sharing
    if sharing and sharing.RestoreBuildTransport and sharing.RestoreBuildTransport()==false then return false end
    if self.share.transportResumeRequired then return false end
    if wasPaused then self.share.lastSendAt=-60000 end
    self.share.pauseError=nil
    return true
end

function SC:MayReceiveBuild(tag)
    return self.sv and self.sv.shareData and self.sv.experimentalSharing
        and not (self.share and (self.share.transportPaused or self.share.transportResumeRequired))
        and not self.loading and not self.inCombat and self:IsCurrentGroupMember(tag) and not self:IsSelf(tag)
end

function SC:IsRaidLead()
    return not self:IsGrouped() or Call(IsUnitGroupLeader,"player")==true
end

function SC:InitializeSharing()
    self.share=self.share or {}
    -- Registration exposes native OFF controls; it never sends a snapshot.
    -- Consent remains enforced at every sending/receiving boundary.
    if not self.sv then return end
    local LGB=rawget(_G,"LibGroupBroadcast")
    if not LGB or type(LGB.RegisterHandler)~="function" then
        self.share.available=false;self.share.error="LibGroupBroadcast is not installed";return
    end
    if self.share.handler then
        self.share.available=self.share.protocol~=nil and self.share.detailProtocol~=nil
        return
    end
    if self.share.registrationAttempted then return end
    self.share.registrationAttempted=true
    local ok,result=pcall(function()
        local handler=LGB:RegisterHandler("AlphaSquadUI","ASUI")
        assert(handler,"Build sharing registration failed")
        self.share.handler=handler
        if handler.SetDisplayName then handler:SetDisplayName("Alpha Squad UI — Build Sharing") end
        if handler.SetDescription then handler:SetDescription("Precombat build sharing, controlled in Alpha Squad UI Libraries. Protocol IDs are provisional; incompatible registration disables this transport.") end
        local protocol=handler:DeclareProtocol(LGB_BUILD_PROTOCOL_ID,LGB_BUILD_PROTOCOL_NAME)
        protocol:AddField(LGB.CreateNumericField("version",{minValue=0,maxValue=7}))
        protocol:AddField(LGB.CreateNumericField("role",{minValue=0,maxValue=15}))
        protocol:AddField(LGB.CreateNumericField("classId",{minValue=0,maxValue=15}))
        protocol:AddField(LGB.CreateFlagField("food"))
        protocol:AddField(LGB.CreateFlagField("foodVerified"))
        protocol:AddField(LGB.CreateNumericField("foodId",{minValue=0,maxValue=1048575}))
        protocol:AddField(LGB.CreateNumericField("potion",{minValue=0,maxValue=7}))
        for _,field in ipairs({"missingGlyphs","prism","mag","stam","health"}) do
            protocol:AddField(LGB.CreateNumericField(field,{minValue=0,maxValue=7}))
        end
        protocol:AddField(LGB.CreateNumericField("supportScore",{minValue=0,maxValue=31}))
        for _,field in ipairs({"cap1","cap2","cap3","cap4","set1","set2"}) do
            protocol:AddField(LGB.CreateNumericField(field,{minValue=0,maxValue=MASK_MAX}))
        end
        protocol:OnData(function(tag,data) SC:OnPeerShareData(tag,data) end)
        assert(protocol:Finalize({isRelevantInCombat=false,replaceQueuedMessages=true}),"Build protocol unavailable")
        self.share.protocol=protocol
        self:InitializeDetailSharing(LGB,handler)
        assert(self.share.detailProtocol,self.share.detailError or "Detail protocol unavailable")
    end)
    self.share.available=ok
    self.share.error=ok and nil or tostring(result)
end

function SC:ShareLocalSnapshot(reason,prepared)
    if not self.sv or not self.sv.experimentalSharing or not self.sv.shareData or self.inCombat or self.loading then return false end
    if self.share and (self.share.transportPaused or self.share.transportResumeRequired) then return false end
    if self.share and self.share.queueRevokeNeedsGroup and self:IsGrouped() and AlphaSquadUI.Sharing then
        -- A solo opt-out cannot call LGB's grouped-only Send API. Keep native
        -- protocols OFF until replacement is possible in the new group.
        AlphaSquadUI.Sharing.SetEnabled("builds",true)
    end
    if not self:IsGrouped() or not self.share or not self.share.available or self.share.controlError or not self.share.protocol then return false end
    if self.share.protocol.IsEnabled then
        local ok,enabled=pcall(self.share.protocol.IsEnabled,self.share.protocol)
        if not ok or enabled~=true then return false end
    end
    local now=self.NowMs()
    if now-(self.share.lastSendAt or -60000)<1500 then return false end
    local payload=self:BuildSharePayload(prepared)
    if not payload then return false end
    local ok,sent=pcall(self.share.protocol.Send,self.share.protocol,payload,{isRelevantInCombat=false,replaceQueuedMessages=true})
    if ok and sent==true then
        self.share.mayHaveQueuedBuildData=true
        self.share.lastSendAt=now
        self.share.lastBuildFingerprint=math.floor(payload.cap4/512)
        if self.ShareCapabilitySummary then self:ShareCapabilitySummary() end
        return true
    end
    return false
end

-- LGB's public replacement option removes older messages for this protocol at
-- enqueue time. Empty version-zero frames are rejected by every ASUI receiver;
-- they contain no player data and are pruned once native Allow Sending is OFF.
-- This avoids resurrecting a queued build after a rapid OFF -> ON toggle.
function SC:ClearQueuedBuildMessages()
    if not self.share then return true end
    if not self:IsGrouped() then
        if self.share.mayHaveQueuedBuildData or self.share.queueRevokeFailed then
            self.share.queueRevokeFailed=true;self.share.queueRevokeNeedsGroup=true
            return false
        end
        return true
    end
    -- A failed supported-API attempt needs an explicit retry, not an automatic
    -- refresh loop. Only a transition from solo to grouped is retried here.
    self.share.queueRevokeNeedsGroup=nil
    local summary={version=0,role=0,classId=0,food=false,foodVerified=false,foodId=0,potion=0,
        missingGlyphs=0,prism=0,mag=0,stam=0,health=0,supportScore=0,
        cap1=0,cap2=0,cap3=0,cap4=0,set1=0,set2=0}
    local detail={version=0,kind=0,revision=0,checksum=0,body=""}
    local cleared=true
    for _,entry in ipairs({{self.share.protocol,summary},{self.share.detailProtocol,detail}}) do
        local protocol=entry[1]
        if protocol and type(protocol.Send)=="function" then
            local ok,sent=pcall(protocol.Send,protocol,entry[2],{isRelevantInCombat=false,replaceQueuedMessages=true})
            if not ok or sent~=true then cleared=false end
        end
    end
    self.share.queueRevokeFailed=not cleared or nil
    if cleared then
        self.share.mayHaveQueuedBuildData=nil;self.share.queueRevokeNeedsGroup=nil
    end
    return cleared
end

function SC:GetSharingStatus()
    if not self.sv or not self.sv.experimentalSharing or not self.sv.shareData then return "LOCAL","Build sharing is off" end
    if self.share and self.share.transportPaused then return "LOCAL",self.share.pauseError or "Build sharing is paused during a transition" end
    if AlphaSquadUI.Sharing and type(AlphaSquadUI.Sharing.GetStatus)=="function" then
        local enabled,reason,available=AlphaSquadUI.Sharing.GetStatus("builds")
        if not available or not enabled then return "LOCAL",reason or "Build sharing is disabled in LibGroupBroadcast" end
    end
    if self.share and self.share.controlError then return "LOCAL",self.share.controlError end
    if self.share and self.share.available then
        for _,field in ipairs({"protocol","detailProtocol"}) do
            local protocol=self.share[field]
            if not protocol or type(protocol.IsEnabled)~="function" then return "LOCAL","Build transport status unavailable" end
            local ok,enabled=pcall(protocol.IsEnabled,protocol)
            if not ok or type(enabled)~="boolean" then return "LOCAL","Build transport status unavailable" end
            if not enabled then return "LOCAL","Build sharing is disabled in LibGroupBroadcast" end
        end
        return "SHARING",self.share.detailError
    end
    return "LOCAL",self.share and self.share.error or "LibGroupBroadcast unavailable"
end
