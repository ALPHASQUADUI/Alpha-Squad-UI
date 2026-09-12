-- Ąlpha Şquad UI - Support Coverage compact group sharing
-- Uses a provisional test protocol ID on this development branch. It must be
-- formally reserved in LibGroupBroadcast_IDs before a public release.

local SC = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end

local Catalog = SC.Catalog
local LGB_PROTOCOL_ID = 510
local LGB_PROTOCOL_NAME = "AlphaSquadSupportCoverage"
local MASK_BITS = 24
local MASK_MAX = 16777215 -- 2^24 - 1

SC.share = SC.share or {
    available = false,
    protocol = nil,
    handler = nil,
    lastSendAt = 0,
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
        dataQuality = "ASUI",
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

        local protocol = handler:DeclareProtocol(LGB_PROTOCOL_ID, LGB_PROTOCOL_NAME)
        protocol:AddField(LGB.CreateNumericField("version", {minValue=0,maxValue=7}))
        protocol:AddField(LGB.CreateNumericField("role", {minValue=0,maxValue=7}))
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

        return {handler=handler, protocol=protocol}
    end)

    if not ok then
        self.share.available = false
        self.share.error = tostring(handlerOrError)
        return
    end

    self.share.handler = handlerOrError.handler
    self.share.protocol = handlerOrError.protocol
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
