-- Optional expected-versus-actual checks. Templates describe intent, never a mandatory meta.
local SC = AlphaSquadUI.Modules.SupportCoverage
local Audit = {}
SC.Audit = Audit

Audit.order = {"sets", "weapons", "traits", "enchants", "armor", "champion", "masteries", "skills", "food", "potion", "poisons", "mundus"}
Audit.labels = {
    sets="Set pieces by weapon bar", weapons="Weapon types", traits="Equipment traits",
    enchants="Equipment enchantments", armor="Armor weights", champion="Champion slottables (four per discipline)",
    masteries="Class Mastery selections", skills="Slotted skills", food="Food / drink",
    potion="Potion selection and combat evidence", poisons="Poisons (optional, not a meta requirement)", mundus="Mundus boon",
}

local VALID_AUDIT_KEYS = {}
for _, key in ipairs(Audit.order) do VALID_AUDIT_KEYS[key] = true end
local VALID_HASH_KEYS = {}
for key in pairs(VALID_AUDIT_KEYS) do VALID_HASH_KEYS[key] = true end
for _, scope in ipairs({"all","combat","conditioning","world"}) do VALID_HASH_KEYS["champion_" .. scope] = true end
local VALID_TEMPLATE_ROLES = {UNKNOWN=true,MT=true,OT=true,HEAL=true,H1=true,H2=true,
    ["MT/OT"]=true,["DD PARSE"]=true,["DD SUPPORT"]=true}
local MAX_BUILD_TEMPLATES = 128
local MAX_PLAYER_TEMPLATES = 256
local MAX_LOADOUT_OWNERS = 36
local MAX_SAVED_LOADOUTS = 4

local function FiniteNumber(value, minimum, maximum, fallback)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return fallback end
    return math.max(minimum, math.min(maximum, value))
end

local function Text(value, fallback, maximum)
    if type(value) ~= "string" then return fallback end
    return value:sub(1, maximum)
end

local function LatestLoadoutAt(choices)
    local latest = 0
    for _, candidate in ipairs(choices or {}) do latest = math.max(latest, tonumber(candidate.savedAt) or 0) end
    return latest
end

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = Copy(child) end
    return result
end
Audit.Copy = Copy

local function Sorted(values)
    table.sort(values)
    return table.concat(values, ", ")
end

function SC:EnsureAuditSettings()
    local sv = self.sv
    sv.checkModes = type(sv.checkModes) == "table" and sv.checkModes or {}
    for _, key in ipairs(Audit.order) do
        local mode = sv.checkModes[key]
        if mode ~= "OFF" and mode ~= "WARN" and mode ~= "REQUIRED" then sv.checkModes[key] = "OFF" end
    end
    sv.loadoutLibrary = type(sv.loadoutLibrary)=="table" and sv.loadoutLibrary or {}
    sv.buildTemplates = type(sv.buildTemplates) == "table" and sv.buildTemplates or {}
    sv.playerTemplates = type(sv.playerTemplates) == "table" and sv.playerTemplates or {}
    sv.effectRules = type(sv.effectRules) == "table" and sv.effectRules or {}
    for key, default in pairs({historyEnabled=true,persistHistory=true,autoContextProfile=false,trackPotionBuffs=true,
        reportAutoOpen=true,collectAllEffects=false,logRawEffects=false,checkFoodPresence=true,
        checkMissingGlyphs=true,experimentalSharing=false}) do
        if type(sv[key]) ~= "boolean" then sv[key] = default end
    end
    if sv.championScope~="ALL" and sv.championScope~="COMBAT" and sv.championScope~="CONDITIONING" and sv.championScope~="WORLD" then sv.championScope="COMBAT" end
    sv.minimumMeasuredPercent=FiniteNumber(sv.minimumMeasuredPercent,0,100,80)
    sv.historyLimit = math.floor(FiniteNumber(sv.historyLimit,5,50,20))
    sv.reportAutoCloseSeconds = FiniteNumber(sv.reportAutoCloseSeconds,0,120,20)
    sv.foodWarningSeconds = FiniteNumber(sv.foodWarningSeconds,0,1800,300)

    local templateOrder = {}
    for key, template in pairs(sv.buildTemplates) do
        if type(key) ~= "string" or key == "" or #key > 240 or type(template) ~= "table" then
            sv.buildTemplates[key] = nil
        else
            template.values = type(template.values) == "table" and template.values or {}
            template.hashes = type(template.hashes) == "table" and template.hashes or {}
            for field, value in pairs(template.values) do
                if not VALID_AUDIT_KEYS[field] or type(value) ~= "string" or #value > 8192 then template.values[field] = nil end
            end
            for field, value in pairs(template.hashes) do
                value = FiniteNumber(value, 0, 16777214, nil)
                if not VALID_HASH_KEYS[field] or not value or value % 1 ~= 0 then template.hashes[field] = nil
                else template.hashes[field] = math.floor(value) end
            end
            template.createdAt = FiniteNumber(template.createdAt, 0, 4294967295, 0)
            template.source = Text(template.source, "player", 192)
            templateOrder[#templateOrder + 1] = {key=key, createdAt=template.createdAt}
        end
    end
    table.sort(templateOrder, function(a,b)
        if a.createdAt ~= b.createdAt then return a.createdAt > b.createdAt end
        return a.key < b.key
    end)
    for index=MAX_BUILD_TEMPLATES+1,#templateOrder do sv.buildTemplates[templateOrder[index].key] = nil end

    local playerTemplateKeys = {}
    for playerKey, templateKey in pairs(sv.playerTemplates) do
        if type(playerKey) ~= "string" or playerKey == "" or #playerKey > 240 or type(templateKey) ~= "string" or templateKey == ""
            or type(sv.buildTemplates[templateKey]) ~= "table" then sv.playerTemplates[playerKey] = nil end
        if sv.playerTemplates[playerKey] ~= nil then playerTemplateKeys[#playerTemplateKeys+1] = playerKey end
    end
    table.sort(playerTemplateKeys)
    for index=MAX_PLAYER_TEMPLATES+1,#playerTemplateKeys do sv.playerTemplates[playerTemplateKeys[index]] = nil end

    for effectKey, value in pairs(sv.effectRules) do
        if not self.Catalog.effects[effectKey] or type(value) ~= "table" then
            sv.effectRules[effectKey] = nil
        else
            value.enabled = type(value.enabled) == "boolean" and value.enabled or nil
            value.expectedStacks = value.expectedStacks and math.floor(self.Clamp(value.expectedStacks,1,100)) or nil
            value.targetCount = value.targetCount and math.floor(self.Clamp(value.targetCount,0,12)) or nil
            value.uptimeTarget = value.uptimeTarget and self.Clamp(value.uptimeTarget,0,100) or nil
            if value.targetRole ~= nil and not VALID_TEMPLATE_ROLES[value.targetRole] then value.targetRole = nil end
            for field in pairs(value) do
                if field ~= "enabled" and field ~= "expectedStacks" and field ~= "targetCount"
                    and field ~= "uptimeTarget" and field ~= "targetRole" then value[field] = nil end
            end
        end
    end

    local ownerOrder = {}
    for owner, choices in pairs(sv.loadoutLibrary) do
        if type(owner) ~= "string" or owner == "" or #owner > 192 or type(choices) ~= "table" then
            sv.loadoutLibrary[owner] = nil
        else
            local candidates = {}
            -- Keep four saved alternatives; the planner adds the current build as
            -- its fifth and final candidate.
            for _, candidate in pairs(choices) do
                if type(candidate) == "table" and type(candidate.signature) == "string" and #candidate.signature <= 8192 then
                    local capabilities = {}
                    for effectKey, enabled in pairs(type(candidate.capabilities)=="table" and candidate.capabilities or {}) do
                        if enabled == true and self.Catalog.effects[effectKey] then capabilities[effectKey] = true end
                    end
                    candidates[#candidates+1] = {
                        label=Text(candidate.label,"Saved loadout",180), signature=candidate.signature,
                        character=Text(candidate.character,"",192), classId=math.floor(FiniteNumber(candidate.classId,0,255,0)),
                        role=VALID_TEMPLATE_ROLES[candidate.role] and candidate.role or "UNKNOWN", capabilities=capabilities,
                        savedAt=FiniteNumber(candidate.savedAt,0,4294967295,0), evidence="RECORDED_BUILD",
                    }
                end
            end
            table.sort(candidates,function(a,b)
                if a.savedAt~=b.savedAt then return a.savedAt>b.savedAt end
                return a.signature<b.signature
            end)
            local newest, seenSignatures = {}, {}
            for _, candidate in ipairs(candidates) do
                if not seenSignatures[candidate.signature] then
                    newest[#newest+1]=candidate
                    seenSignatures[candidate.signature]=true
                    if #newest>=MAX_SAVED_LOADOUTS then break end
                end
            end
            local clean={}
            for index=#newest,1,-1 do clean[#clean+1]=newest[index] end
            sv.loadoutLibrary[owner] = clean
            ownerOrder[#ownerOrder+1] = {owner=owner, savedAt=LatestLoadoutAt(clean)}
        end
    end
    table.sort(ownerOrder,function(a,b)
        if a.savedAt~=b.savedAt then return a.savedAt>b.savedAt end
        return a.owner<b.owner
    end)
    for index=MAX_LOADOUT_OWNERS+1,#ownerOrder do sv.loadoutLibrary[ownerOrder[index].owner]=nil end
end

function Audit.Value(snapshot, key)
    if not snapshot then return nil end
    local eq, skills = snapshot.equipment, snapshot.skills
    local values = {}
    if key == "sets" then
        if not eq or eq.complete ~= true then return nil end
        for _, set in ipairs(eq.setList or {}) do
            if not set.id or set.id <= 0 or set.mainCount == nil or set.backCount == nil then return nil end
            values[#values + 1] = string.format("%d:%d/%d", set.id, set.mainCount, set.backCount)
        end
    elseif key == "weapons" or key == "traits" or key == "enchants" or key == "armor" then
        if not eq or not eq.items or eq.complete ~= true then return nil end
        local property = ({weapons="weaponType", traits="trait", enchants="enchantId", armor="armorType"})[key]
        for _, item in ipairs(eq.items) do
            local relevant = key == "traits" or key == "enchants" or (key == "weapons" and item.isWeapon) or (key == "armor" and item.isArmor)
            if relevant then
                if item[property] == nil then return nil end
                values[#values + 1] = tostring(item.slot) .. ":" .. tostring(item[property])
            end
        end
    elseif key == "champion" then
        if not skills or not skills.championKnown then return nil end
        for _, star in ipairs(skills.champion or {}) do
            values[#values + 1] = table.concat({tostring(star.slot),star.discipline or "UNKNOWN",tostring(star.id),tostring(star.points or "UNKNOWN")},":")
        end
    elseif key == "masteries" then
        if not snapshot.masteries or snapshot.masteries.known ~= true then return nil end
        if snapshot.masteries.eligible == nil then return nil end
        values[#values + 1] = snapshot.masteries.eligible and "ELIGIBLE" or "INACTIVE"
        for _, entry in ipairs(snapshot.masteries.selected or {}) do values[#values + 1] = tostring(entry.id) .. ":" .. tostring(entry.rank) end
    elseif key == "skills" then
        if not skills or not skills.known then return nil end
        for _, bar in ipairs({"primary", "backup"}) do
            for _, entry in ipairs(skills[bar] or {}) do
                -- Effective chained/override IDs may change in combat. The bound
                -- ID is the committed loadout identity used by build templates.
                values[#values + 1] = bar .. ":" .. tostring(entry.slot) .. ":"
                    .. tostring(entry.boundAbilityId or entry.abilityId)
            end
        end
    elseif key == "food" then
        local food = snapshot.food
        if not food or not food.verified then return nil end
        return food.active and tostring(food.abilityId) or "NONE"
    elseif key == "potion" then
        local potion = snapshot.potion
        if not potion then return nil end
        if not potion.known then return potion.selectionKnown and "NONE" or nil end
        -- A complete item link distinguishes crafted potions sharing the same base item ID.
        return potion.link or (potion.itemId and tostring(potion.itemId))
    elseif key == "poisons" then
        if not snapshot.poisons or not snapshot.poisons.known then return nil end
        for _, item in ipairs(snapshot.poisons.items or {}) do values[#values + 1] = item.slot .. ":" .. (item.link or "NONE") end
    elseif key == "mundus" then
        if not snapshot.mundus or not snapshot.mundus.known then return nil end
        for _, id in ipairs(snapshot.mundus.ids or {}) do values[#values + 1] = tostring(id) end
    else
        return nil
    end
    return Sorted(values)
end

function SC:GetTemplateKey(role)
    return tostring(self.sv.activeProfile or "full") .. ":" .. tostring(role or "UNKNOWN")
end

function SC:GetExpectedTemplate(player)
    local playerKey = player and (player.key or player.displayName)
    local scopedKey = playerKey and tostring(self.sv.activeProfile) .. ":" .. playerKey
    local override = playerKey and (self.sv.playerTemplates[scopedKey] or self.sv.playerTemplates[playerKey])
    if override and type(self.sv.buildTemplates[override]) ~= "table" then
        if scopedKey then self.sv.playerTemplates[scopedKey] = nil end
        if playerKey and self.sv.playerTemplates[playerKey] == override then self.sv.playerTemplates[playerKey] = nil end
        override = nil
    end
    local key = override or self:GetTemplateKey(player and player.role)
    return self.sv.buildTemplates[key], key
end

function SC:CaptureExpectedBuild(role, snapshot, playerKey)
    snapshot = snapshot or self.localSnapshot
    if not snapshot or self.inCombat then return false, "Capture is available out of combat only." end
    local template = {values={}, hashes={}, createdAt=GetTimeStamp and GetTimeStamp() or 0, source=snapshot.displayName or "player"}
    local count = 0
    for _, key in ipairs(Audit.order) do
        local value = Audit.Value(snapshot, key)
        if value ~= nil then template.values[key] = value; count = count + 1 end
    end
    local signatureMatches=not snapshot.buildDetailFingerprint or not snapshot.detailBuildFingerprint
        or snapshot.buildDetailFingerprint==snapshot.detailBuildFingerprint
    if signatureMatches and snapshot.auditHashes and snapshot.detailAt
        and self.NowMs()-math.max(snapshot.detailAt,snapshot.detailAliveAt or 0)<=120000 then
        template.hashes = Copy(snapshot.auditHashes)
        for _, key in ipairs(Audit.order) do
            local hashKey = key == "champion" and "champion_" .. string.lower(self.sv.championScope or "COMBAT") or key
            if template.values[key] == nil and template.hashes[hashKey] ~= nil then count = count + 1 end
        end
    end
    if count == 0 then return false, "No verified build fields to capture." end
    local key = self:GetTemplateKey(role)
    if playerKey then
        key=key .. ":" .. playerKey
        self.sv.playerTemplates[tostring(self.sv.activeProfile) .. ":" .. playerKey]=key
    end
    self.sv.buildTemplates[key] = template
    if self.RememberLoadout then self:RememberLoadout(snapshot, tostring(role or "UNKNOWN") .. " - " .. tostring(self.sv.activeProfile)) end
    self:EnsureAuditSettings()
    return true, "Expected build saved. Enable only the checks you need."
end

function Audit.CompareValue(key, value, scope)
    if key~="champion" or value==nil then return value end
    local stars,counts,slots={},{},{}
    for item in tostring(value):gmatch("[^,]+") do
        local slot,discipline,id,points=item:match("^%s*(%d+):([A-Z]+):(%d+):([%w]+)%s*$")
        if not slot or slots[slot] or discipline=="UNKNOWN" or not tonumber(points) then return nil end
        slots[slot]=true
        if scope=="ALL" or discipline==scope then
            stars[#stars+1]=discipline..":"..id..":"..points
            counts[discipline]=(counts[discipline] or 0)+1
        end
    end
    if scope=="ALL" then
        if #stars~=12 or counts.COMBAT~=4 or counts.CONDITIONING~=4 or counts.WORLD~=4 then return nil end
    elseif #stars~=4 or counts[scope]~=4 then return nil end
    return Sorted(stars)
end

function SC:EvaluateBuildAudit(player)
    local result = {rows={}, failed=0, unknown=0, requiredFailures=0, requiredUnknown=0}
    local template = self:GetExpectedTemplate(player)
    for _, key in ipairs(Audit.order) do
        local mode = self.sv.checkModes[key] or "OFF"
        if mode ~= "OFF" then
            local actual = Audit.Value(player, key)
            local expected = template and template.values and template.values[key]
            local hashKey = key == "champion" and "champion_" .. string.lower(self.sv.championScope or "COMBAT") or key
            local actualHash
            local signatureMatches=not player or not player.buildDetailFingerprint or not player.detailBuildFingerprint
                or player.buildDetailFingerprint==player.detailBuildFingerprint
            if player and signatureMatches and player.auditHashes and player.detailAt
                and self.NowMs()-math.max(player.detailAt,player.detailAliveAt or 0)<=120000 then
                actualHash = player.auditHashes[hashKey]
            end
            local expectedHash = template and template.hashes and template.hashes[hashKey]
            local status, reason = "UNKNOWN", "No expected value configured."
            if expected == nil and expectedHash == nil then
                -- Keep the default reason.
            elseif actual == nil and actualHash == nil then
                reason = (player and player.asui) and "This client has not shared this field, or its API data is unavailable." or "No ASUI build snapshot. Missing data; no build inference."
            else
                local actualCompared=Audit.CompareValue(key,actual,self.sv.championScope)
                local expectedCompared=Audit.CompareValue(key,expected,self.sv.championScope)
                if actualCompared~=nil and expectedCompared~=nil then
                    status = actualCompared == expectedCompared and "PASS" or "MISMATCH"
                    reason = status == "PASS" and "Expected and actual values match." or "Actual build differs from the selected template."
                else
                    if actualHash == nil and actualCompared ~= nil and self.Details then actualHash=self.Details.Hash(actualCompared) end
                    if expectedHash == nil and expectedCompared ~= nil and self.Details then expectedHash=self.Details.Hash(expectedCompared) end
                end
                if status=="UNKNOWN" and (actualHash==nil or expectedHash==nil) then
                    reason="Required field metadata is unavailable. Recapture the expected build with this version."
                elseif status=="UNKNOWN" then
                    status = actualHash == expectedHash and "PASS" or "MISMATCH"
                    reason = status == "PASS" and "Expected and actual signatures match." or "Actual build differs from the selected template."
                end
            end
            result.rows[#result.rows + 1] = {key=key, label=Audit.labels[key], mode=mode, status=status,
                expected=expected or (expectedHash and "SHARED SIGNATURE"), actual=actual or (actualHash and "SHARED SIGNATURE"), reason=reason}
            if status == "UNKNOWN" then
                result.unknown = result.unknown + 1
                if mode == "REQUIRED" then result.requiredUnknown = result.requiredUnknown + 1 end
            end
            if status == "MISMATCH" then
                result.failed = result.failed + 1
                if mode == "REQUIRED" then result.requiredFailures = result.requiredFailures + 1 end
            end
        end
    end
    return result
end

function SC:GetEffectRule(key)
    local effect = self.Catalog.effects[key] or {}
    local override = self.sv.effectRules[key]
    if type(override)~="table" then override={} end
    local targetCount=FiniteNumber(override.targetCount,0,12,nil)
        or FiniteNumber(effect.coverageLimit,0,12,nil)
    if targetCount==0 then targetCount=nil end
    return {
        enabled = override.enabled ~= false,
        expectedStacks = FiniteNumber(override.expectedStacks,1,100,nil)
            or FiniteNumber(effect.stacks,1,100,1),
        targetCount = targetCount,
        uptimeTarget = FiniteNumber(override.uptimeTarget,0,100,0),
        targetRole = override.targetRole, -- nil means all eligible recipients; never a hardcoded meta role.
    }
end
