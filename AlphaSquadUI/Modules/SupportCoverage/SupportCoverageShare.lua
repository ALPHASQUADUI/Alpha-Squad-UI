-- Ąlpha Şquad UI - Support Coverage compact group sharing
-- Uses a provisional protocol ID behind explicit sharing opt-in. It must be
-- formally reserved in LibGroupBroadcast_IDs before a public release.

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
    local text = Normalize((potion.name or "") .. " " .. (potion.effects or ""))
    if text:find("heroism", 1, true) then return 4 end
    if text:find("spell power", 1, true) or text:find("sorcery", 1, true) then return 2 end
    if text:find("weapon power", 1, true) or text:find("brutality", 1, true) then return 3 end
    if text:find("health", 1, true) and text:find("magicka", 1, true) and text:find("stamina", 1, true) then return 1 end
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

function SC:BuildSharePayload()
    local s = self.localSnapshot
    if not s then return nil end

    local caps = EncodeCapabilities(s.capabilities)
    local body = self.BuildCodec and self.BuildCodec.Encode(s)
    if body then caps[4] = (caps[4] or 0) + (self.BuildCodec.Hash(body) % 32767 + 1) * 512 end
    self.share.preparedBuildBody = body
    local sets = {0,0} -- Exact native set identities are sent only in requested builds.
    local glyphs = s.equipment and s.equipment.glyphs or {}
    local food = s.food or {}
    if glyphs.verified == true then sets[2] = BitSet(sets[2], GLYPHS_VERIFIED_BIT) end

    return {
        version = BUILD_VERSION,
        role = ROLE_TO_ID[s.role] or 0,
        classId = BoundedInteger(s.classId, 0, 15),
        food = food.active == true,
        foodVerified = food.verified == true,
        foodId = BoundedInteger(food.abilityId, 0, 1048575),
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
    local key = self:GetPlayerKey(unitTag)
    local previous = self.peerData[key]

    local foodId = tonumber(data.foodId) or 0
    local foodName = ""
    if foodId > 0 and GetAbilityName then foodName = GetAbilityName(foodId) or "" end

    self.peerData[key] = {
        protocolVersion = tonumber(data.version) or 0,
        catalogPatch = self.catalogPatch,
        displayName = key,
        characterName = GetUnitName and GetUnitName(unitTag) or "",
        classId = tonumber(data.classId) or 0,
        className = GetUnitClass and GetUnitClass(unitTag) or "",
        role = ID_TO_ROLE[tonumber(data.role) or 0] or "UNKNOWN",
        supportScore = tonumber(data.supportScore) or 0,
        dataQuality = "ASUI",
        buildVerified = true,
        asui = true,
        connected = IsUnitOnline and IsUnitOnline(unitTag) or true,
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
    peer.buildDetailFingerprint = data.version == 3 and math.floor(data.cap4 / 512) or nil
    if previous and previous.fullBuild and previous.fullBuildFingerprint == peer.buildDetailFingerprint
        and previous.characterName == peer.characterName then
        peer.fullBuild, peer.fullBuildAt, peer.fullBuildFingerprint = previous.fullBuild, previous.fullBuildAt, previous.fullBuildFingerprint
        peer.capabilities = previous.fullBuild.capabilities
        peer.equipment, peer.skills, peer.masteries = previous.fullBuild.equipment, previous.fullBuild.skills, previous.fullBuild.masteries
        peer.curse = previous.fullBuild.curse
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

function SC:MayReceiveBuild(tag)
    return self.sv and self.sv.enabled and self.sv.shareData and self.sv.experimentalSharing
        and not self.inCombat and self:IsCurrentGroupMember(tag) and not self:IsSelf(tag)
end

function SC:IsRaidLead()
    return not self:IsGrouped() or Call(IsUnitGroupLeader,"player")==true
end

function SC:InitializeSharing()
    self.share=self.share or {}
    if not self.sv or not self.sv.enabled or not self.sv.experimentalSharing or not self.sv.shareData then
        self.share.available=false
        self.share.error="Build sharing is off. Enable sharing on each participating client."
        return
    end
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
        if handler.SetDisplayName then handler:SetDisplayName("Ąlpha Şquad UI — Build Sharing") end
        if handler.SetDescription then handler:SetDescription("Optional precombat build sharing. Protocol registration is pending; enable only with a coordinated group.") end
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

function SC:ShareLocalSnapshot(reason)
    if not self.sv or not self.sv.enabled or not self.sv.experimentalSharing or not self.sv.shareData or self.inCombat then return false end
    if not self:IsGrouped() or not self.share or not self.share.available or not self.share.protocol then return false end
    if self.share.protocol.IsEnabled and not self.share.protocol:IsEnabled() then return false end
    local now=self.NowMs()
    if now-(self.share.lastSendAt or -60000)<1500 then return false end
    local payload=self:BuildSharePayload()
    if not payload then return false end
    local ok,sent=pcall(self.share.protocol.Send,self.share.protocol,payload,{isRelevantInCombat=false,replaceQueuedMessages=true})
    if ok and sent==true then
        self.share.lastSendAt=now
        self.share.lastBuildFingerprint=math.floor(payload.cap4/512)
        if self.ShareCapabilitySummary then self:ShareCapabilitySummary() end
        return true
    end
    return false
end

function SC:GetSharingStatus()
    if not self.sv or not self.sv.experimentalSharing or not self.sv.shareData then return "LOCAL","Build sharing is off" end
    if self.share and self.share.available then return "SHARING",self.share.detailError end
    return "LOCAL",self.share and self.share.error or "LibGroupBroadcast unavailable"
end
