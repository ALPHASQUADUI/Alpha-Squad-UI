-- Ąlpha Şquad UI - Support Coverage compact group sharing
-- Uses a provisional test protocol ID on this development branch. It must be
-- formally reserved in LibGroupBroadcast_IDs before a public release.

local SC = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end

local Catalog = SC.Catalog
local LGB_BUILD_PROTOCOL_ID = 510
local LGB_BUILD_PROTOCOL_NAME = "AlphaSquadSupportCoverage"
local LGB_PLAN_PROTOCOL_ID = 509
local LGB_PLAN_PROTOCOL_NAME = "AlphaSquadSupportPlan"
local LGB_LIVE_PROTOCOL_ID = 508
local LGB_LIVE_PROTOCOL_NAME = "AlphaSquadSupportLive"
local MASK_BITS = 24
local MASK_MAX = 16777215 -- 2^24 - 1

SC.share = SC.share or {
    available = false,
    protocol = nil,
    planProtocol = nil,
    liveProtocol = nil,
    handler = nil,
    lastSendAt = 0,
    lastLiveSendAt = 0,
    planRevision = 0,
    planPending = false,
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

local PROFILE_TO_ID = {full=1, progression=2, damage=3, trash=4, boss=5, custom=6}
local ID_TO_PROFILE = {}
for name, id in pairs(PROFILE_TO_ID) do ID_TO_PROFILE[id] = name end

local function HashUserId(value)
    value = string.lower(tostring(value or ""))
    local hash = 216613
    for i = 1, #value do
        hash = (hash * 131 + string.byte(value, i)) % MASK_MAX
    end
    return math.floor(hash)
end


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
    local keys = Catalog and Catalog:GetAllEffectKeys() or {}
    local map = {}
    for index, key in ipairs(keys) do map[key] = index - 1 end
    return keys, map
end

local EFFECT_KEYS, EFFECT_INDEX = BuildEffectIndex()

local function BuildSetIndex()
    local tokens, seen = {}, {}
    for _, source in ipairs(Catalog and Catalog.setSources or {}) do
        local token = Normalize(source.token)
        if token ~= "" and not seen[token] then
            tokens[#tokens + 1] = source.token
            seen[token] = true
        end
    end
    table.sort(tokens, function(a, b) return Normalize(a) < Normalize(b) end)
    return tokens
end

local SET_TOKENS = BuildSetIndex()

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
    for index, key in ipairs(EFFECT_KEYS) do
        local zero = index - 1
        local maskIndex = math.floor(zero / MASK_BITS) + 1
        local bitIndex = zero % MASK_BITS
        if masks[maskIndex] and BitHas(masks[maskIndex], bitIndex) then
            result[key] = {sources={["ASUI peer"] = true}}
        end
    end
    return result
end

local function EncodeSets(setList)
    local masks = {0, 0}
    for _, set in ipairs(setList or {}) do
        local name = Normalize(set.name)
        for index, token in ipairs(SET_TOKENS) do
            if name:find(Normalize(token), 1, true) then
                local zero = index - 1
                local maskIndex = math.floor(zero / MASK_BITS) + 1
                local bitIndex = zero % MASK_BITS
                if masks[maskIndex] then masks[maskIndex] = BitSet(masks[maskIndex], bitIndex) end
            end
        end
    end
    return masks
end

local function DecodeSets(data)
    local list = {}
    local masks = {tonumber(data.set1) or 0, tonumber(data.set2) or 0}
    for index, token in ipairs(SET_TOKENS) do
        local zero = index - 1
        local maskIndex = math.floor(zero / MASK_BITS) + 1
        local bitIndex = zero % MASK_BITS
        if masks[maskIndex] and BitHas(masks[maskIndex], bitIndex) then
            list[#list + 1] = {id=0, name=token, equipped=5, shared=true}
        end
    end
    return list
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
    local sets = EncodeSets(s.equipment and s.equipment.setList)
    local glyphs = s.equipment and s.equipment.glyphs or {}
    local food = s.food or {}

    return {
        version = 1,
        role = ROLE_TO_ID[s.role] or 0,
        classId = math.max(0, math.min(15, tonumber(s.classId) or 0)),
        food = food.active == true,
        foodVerified = food.verified == true,
        foodId = math.max(0, math.min(1048575, tonumber(food.abilityId) or 0)),
        potion = ClassifyPotion(s),
        missingGlyphs = math.max(0, math.min(7, tonumber(glyphs.armorMissing) or 0)),
        prism = math.max(0, math.min(7, tonumber(glyphs.prismatic) or 0)),
        mag = math.max(0, math.min(7, tonumber(glyphs.magicka) or 0)),
        stam = math.max(0, math.min(7, tonumber(glyphs.stamina) or 0)),
        health = math.max(0, math.min(7, tonumber(glyphs.health) or 0)),
        supportScore = math.max(0, math.min(31, tonumber(s.supportScore) or 0)),
        cap1 = caps[1] or 0,
        cap2 = caps[2] or 0,
        cap3 = caps[3] or 0,
        cap4 = caps[4] or 0,
        set1 = sets[1] or 0,
        set2 = sets[2] or 0,
    }
end

function SC:OnPeerShareData(unitTag, data)
    if not unitTag or not data then return end
    local key = self:GetPlayerKey(unitTag)

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
            setList = DecodeSets(data),
            glyphs = {
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

    self:ScheduleRefresh("peer data", 25)
end


function SC:IsRaidLead()
    if not self:IsGrouped() then return true end
    if IsUnitGroupLeader then
        local ok, leader = pcall(IsUnitGroupLeader, "player")
        if ok then return leader == true end
    end
    return false
end

function SC:GetLocalLiveCapabilities()
    local observed = {}
    if self.ObserveEffectsOnUnit then
        observed = select(1, self:ObserveEffectsOnUnit("player")) or {}
    end
    local capabilities = {}
    for key in pairs(observed) do capabilities[key] = {sources={["LIVE"] = true}} end
    self.localLive = {
        capabilities = capabilities,
        updatedAt = self.NowMs(),
    }
    return capabilities
end

function SC:ShareLiveSnapshot()
    if not self.sv or not self.sv.shareData or not self.inCombat then return false end
    if not self:IsGrouped() then return false end
    local protocol = self.share and self.share.liveProtocol
    if not protocol then return false end
    if protocol.IsEnabled and not protocol:IsEnabled() then return false end

    local now = self.NowMs()
    if now - (self.share.lastLiveSendAt or 0) < 1800 then return false end

    local caps = EncodeCapabilities(self:GetLocalLiveCapabilities())
    local payload = {
        cap1 = caps[1] or 0,
        cap2 = caps[2] or 0,
        cap3 = caps[3] or 0,
        cap4 = caps[4] or 0,
    }
    local ok, sent = pcall(function() return protocol:Send(payload) end)
    if ok and sent ~= false then
        self.share.lastLiveSendAt = now
        return true
    end
    return false
end

function SC:OnPeerLiveData(unitTag, data)
    if not unitTag or not data then return end
    local key = self:GetPlayerKey(unitTag)
    local peer = self.peerData[key]
    if not peer then
        peer = self.ScanLimitedUnit and self:ScanLimitedUnit(unitTag) or {
            displayName=key, capabilities={}, dataQuality="ASUI",
        }
        self.peerData[key] = peer
    end
    peer.asui = true
    if peer.buildVerified == true then
        peer.dataQuality = "ASUI"
    else
        peer.dataQuality = "ASUI LIVE"
    end
    peer.liveCapabilities = DecodeCapabilities(data)
    peer.liveUpdatedAt = self.NowMs()
    peer.unitTag = unitTag
end

function SC:GetMyHash()
    return HashUserId(self:GetPlayerKey("player"))
end

function SC:GetPlanSignature()
    local parts = {tostring(self.sv and self.sv.activeProfile or "full")}
    local coverage = self.coverage or {}

    for _, row in ipairs(coverage.entries or {}) do
        local owner = row.assigned and row.assigned.key or ""
        parts[#parts + 1] = tostring(row.key) .. "=" .. tostring(owner)
    end

    local roleKeys = {}
    for playerKey in pairs(self.sv and self.sv.roleOverrides or {}) do
        roleKeys[#roleKeys + 1] = playerKey
    end
    table.sort(roleKeys)
    for _, playerKey in ipairs(roleKeys) do
        parts[#parts + 1] = "role:" .. tostring(playerKey) .. "=" .. tostring(self.sv.roleOverrides[playerKey])
    end

    return table.concat(parts, "|")
end

function SC:MaybeBroadcastPlan()
    if not self:IsRaidLead() or self.inCombat then return end
    local signature = self:GetPlanSignature()
    if signature == self.lastPlanSignature then return end
    self.lastPlanSignature = signature
    self:SchedulePlanBroadcast()
end

function SC:SchedulePlanBroadcast()
    if not self.share or not self.share.planProtocol then return end
    if not self:IsRaidLead() or self.inCombat then return end
    if self.share.planPending then return end
    self.share.planPending = true
    zo_callLater(function()
        if not SC or not SC.share then return end
        SC.share.planPending = false
        SC:BroadcastPlan()
    end, 900)
end

function SC:BroadcastPlan()
    if not self.sv or not self.sv.shareData or self.inCombat then return false end
    if not self:IsGrouped() or not self:IsRaidLead() then return false end
    local protocol = self.share and self.share.planProtocol
    if not protocol then return false end
    if protocol.IsEnabled and not protocol:IsEnabled() then return false end

    self.share.planRevision = ((self.share.planRevision or 0) % 250) + 1
    local revision = self.share.planRevision
    local profileId = PROFILE_TO_ID[self.sv.activeProfile] or 1

    -- Reset/new-plan marker. key contains profile ID.
    pcall(function()
        protocol:Send({revision=revision, kind=0, key=profileId, ownerHash=0})
    end)

    local coverage = self.coverage or {}
    for _, row in ipairs(coverage.entries or {}) do
        local owner = row.assigned
        local effectIndex = EFFECT_INDEX[row.key]
        if owner and effectIndex and effectIndex < 128 then
            pcall(function()
                protocol:Send({
                    revision=revision,
                    kind=1,
                    key=effectIndex,
                    ownerHash=HashUserId(owner.key),
                })
            end)
        end
    end

    for playerKey, role in pairs(self.sv.roleOverrides or {}) do
        local roleId = ROLE_TO_ID[role]
        if roleId then
            pcall(function()
                protocol:Send({
                    revision=revision,
                    kind=2,
                    key=roleId,
                    ownerHash=HashUserId(playerKey),
                })
            end)
        end
    end

    return true
end

function SC:OnPlanData(unitTag, data)
    if not data then return end
    local revision = tonumber(data.revision) or 0
    local kind = tonumber(data.kind) or 0
    local key = tonumber(data.key) or 0
    local ownerHash = tonumber(data.ownerHash) or 0

    self.remotePlan = self.remotePlan or {revision=-1, assignments={}}
    if kind == 0 then
        self.remotePlan = {
            revision = revision,
            sender = self:GetPlayerKey(unitTag),
            profile = ID_TO_PROFILE[key] or "full",
            assignments = {},
            myRole = nil,
        }
    elseif self.remotePlan.revision == revision then
        if kind == 1 then
            local effectKey = EFFECT_KEYS[key + 1]
            if effectKey then
                self.remotePlan.assignments[effectKey] = ownerHash
            end
        elseif kind == 2 and ownerHash == self:GetMyHash() then
            self.remotePlan.myRole = ID_TO_ROLE[key] or "UNKNOWN"
        end
    end

    if self.assignmentBannerPending then return end
    self.assignmentBannerPending = true
    zo_callLater(function()
        if SC then
            SC.assignmentBannerPending = false
            if SC.ShowPersonalAssignmentBanner then SC:ShowPersonalAssignmentBanner() end
        end
    end, 350)
end

function SC:GetMyRemoteAssignments()
    local result = {}
    local plan = self.remotePlan
    if not plan then return result end
    local myHash = self:GetMyHash()
    for effectKey, ownerHash in pairs(plan.assignments or {}) do
        if ownerHash == myHash and Catalog.effects[effectKey] then
            result[#result + 1] = Catalog.effects[effectKey].label
        end
    end
    table.sort(result)
    return result
end

function SC:InitializeSharing()
    local LGB = rawget(_G, "LibGroupBroadcast")
    if not LGB or type(LGB.RegisterHandler) ~= "function" then
        self.share.available = false
        self.share.error = "LibGroupBroadcast unavailable"
        return
    end

    local ok, handlerOrError = pcall(function()
        local handler = LGB:RegisterHandler("AlphaSquadUI", "ASUI")
        if not handler then error("handler registration failed") end
        if handler.SetDisplayName then handler:SetDisplayName("Ąlpha Şquad UI") end
        if handler.SetDescription then
            handler:SetDescription("Shares compact Support Coverage capability data with group members.")
        end

        local protocol = handler:DeclareProtocol(LGB_BUILD_PROTOCOL_ID, LGB_BUILD_PROTOCOL_NAME)
        protocol:AddField(LGB.CreateNumericField("version", {minValue=0,maxValue=7}))
        protocol:AddField(LGB.CreateNumericField("role", {minValue=0,maxValue=15}))
        protocol:AddField(LGB.CreateNumericField("classId", {minValue=0,maxValue=15}))
        protocol:AddField(LGB.CreateFlagField("food"))
        protocol:AddField(LGB.CreateFlagField("foodVerified"))
        protocol:AddField(LGB.CreateNumericField("foodId", {minValue=0,maxValue=1048575}))
        protocol:AddField(LGB.CreateNumericField("potion", {minValue=0,maxValue=7}))
        protocol:AddField(LGB.CreateNumericField("missingGlyphs", {minValue=0,maxValue=7}))
        protocol:AddField(LGB.CreateNumericField("prism", {minValue=0,maxValue=7}))
        protocol:AddField(LGB.CreateNumericField("mag", {minValue=0,maxValue=7}))
        protocol:AddField(LGB.CreateNumericField("stam", {minValue=0,maxValue=7}))
        protocol:AddField(LGB.CreateNumericField("health", {minValue=0,maxValue=7}))
        protocol:AddField(LGB.CreateNumericField("supportScore", {minValue=0,maxValue=31}))
        protocol:AddField(LGB.CreateNumericField("cap1", {minValue=0,maxValue=MASK_MAX}))
        protocol:AddField(LGB.CreateNumericField("cap2", {minValue=0,maxValue=MASK_MAX}))
        protocol:AddField(LGB.CreateNumericField("cap3", {minValue=0,maxValue=MASK_MAX}))
        protocol:AddField(LGB.CreateNumericField("cap4", {minValue=0,maxValue=MASK_MAX}))
        protocol:AddField(LGB.CreateNumericField("set1", {minValue=0,maxValue=MASK_MAX}))
        protocol:AddField(LGB.CreateNumericField("set2", {minValue=0,maxValue=MASK_MAX}))
        protocol:OnData(function(unitTag, data)
            if SC then SC:OnPeerShareData(unitTag, data) end
        end)
        protocol:Finalize({isRelevantInCombat=false, replaceQueuedMessages=true})

        local liveProtocol = handler:DeclareProtocol(LGB_LIVE_PROTOCOL_ID, LGB_LIVE_PROTOCOL_NAME)
        liveProtocol:AddField(LGB.CreateNumericField("cap1", {minValue=0,maxValue=MASK_MAX}))
        liveProtocol:AddField(LGB.CreateNumericField("cap2", {minValue=0,maxValue=MASK_MAX}))
        liveProtocol:AddField(LGB.CreateNumericField("cap3", {minValue=0,maxValue=MASK_MAX}))
        liveProtocol:AddField(LGB.CreateNumericField("cap4", {minValue=0,maxValue=MASK_MAX}))
        liveProtocol:OnData(function(unitTag, data)
            if SC then SC:OnPeerLiveData(unitTag, data) end
        end)
        liveProtocol:Finalize({isRelevantInCombat=true, replaceQueuedMessages=true})

        local planProtocol = handler:DeclareProtocol(LGB_PLAN_PROTOCOL_ID, LGB_PLAN_PROTOCOL_NAME)
        planProtocol:AddField(LGB.CreateNumericField("revision", {minValue=0,maxValue=255}))
        planProtocol:AddField(LGB.CreateNumericField("kind", {minValue=0,maxValue=3}))
        planProtocol:AddField(LGB.CreateNumericField("key", {minValue=0,maxValue=127}))
        planProtocol:AddField(LGB.CreateNumericField("ownerHash", {minValue=0,maxValue=MASK_MAX}))
        planProtocol:OnData(function(unitTag, data)
            if SC then SC:OnPlanData(unitTag, data) end
        end)
        planProtocol:Finalize({isRelevantInCombat=false, replaceQueuedMessages=false})

        return {handler=handler, protocol=protocol, liveProtocol=liveProtocol, planProtocol=planProtocol}
    end)

    if not ok then
        self.share.available = false
        self.share.error = tostring(handlerOrError)
        return
    end

    self.share.handler = handlerOrError.handler
    self.share.protocol = handlerOrError.protocol
    self.share.liveProtocol = handlerOrError.liveProtocol
    self.share.planProtocol = handlerOrError.planProtocol
    self.share.available = true
    self.share.error = nil
end

function SC:ShareLocalSnapshot(reason)
    if not self.sv or not self.sv.shareData then return false end
    if not self:IsGrouped() then return false end
    if not self.share or not self.share.available or not self.share.protocol then return false end

    local protocol = self.share.protocol
    if protocol.IsEnabled and not protocol:IsEnabled() then return false end

    local now = self.NowMs()
    if now - (self.share.lastSendAt or 0) < 750 then return false end

    local payload = self:BuildSharePayload()
    if not payload then return false end

    local ok, sent = pcall(function() return protocol:Send(payload) end)
    if ok and sent ~= false then
        self.share.lastSendAt = now
        return true
    end
    return false
end

function SC:GetSharingStatus()
    if not self.share or not self.share.available then
        return "LOCAL", self.share and self.share.error or "LibGroupBroadcast unavailable"
    end
    return "LGB", nil
end
