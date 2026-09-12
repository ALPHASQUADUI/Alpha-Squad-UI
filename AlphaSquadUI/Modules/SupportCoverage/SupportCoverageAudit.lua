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
    if sv.historyEnabled == nil then sv.historyEnabled = true end
    if sv.persistHistory == nil then sv.persistHistory = true end
    if sv.autoContextProfile == nil then sv.autoContextProfile = false end
    if sv.trackPotionBuffs == nil then sv.trackPotionBuffs = true end
    if sv.reportAutoOpen == nil then sv.reportAutoOpen = true end
    if sv.collectAllEffects == nil then sv.collectAllEffects = true end
    if sv.logRawEffects == nil then sv.logRawEffects = false end
    if sv.checkFoodPresence == nil then sv.checkFoodPresence = true end
    if sv.checkMissingGlyphs == nil then sv.checkMissingGlyphs = true end
    if sv.experimentalSharing == nil then sv.experimentalSharing = false end
    if sv.championScope~="ALL" and sv.championScope~="COMBAT" and sv.championScope~="CONDITIONING" and sv.championScope~="WORLD" then sv.championScope="COMBAT" end
    sv.minimumMeasuredPercent=self.Clamp(sv.minimumMeasuredPercent or 80,0,100)
    sv.historyLimit = math.floor(self.Clamp(sv.historyLimit or 20, 5, 50))
    sv.reportAutoCloseSeconds = self.Clamp(sv.reportAutoCloseSeconds or 20, 0, 120)
    sv.foodWarningSeconds = self.Clamp(sv.foodWarningSeconds or 300, 0, 1800)
end

function Audit.Value(snapshot, key)
    if not snapshot then return nil end
    if snapshot.auditValues and snapshot.detailAt and SC.NowMs()-math.max(snapshot.detailAt,snapshot.detailAliveAt or 0) <= 120000 then
        return snapshot.auditValues[key]
    end
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
            for _, entry in ipairs(skills[bar] or {}) do values[#values + 1] = bar .. ":" .. entry.slot .. ":" .. entry.abilityId end
        end
    elseif key == "food" then
        local food = snapshot.food
        if not food or not food.verified then return nil end
        return food.active and tostring(food.abilityId) or "NONE"
    elseif key == "potion" then
        local potion = snapshot.potion
        if not potion or not potion.known then return nil end
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
    local override = playerKey and (self.sv.playerTemplates[tostring(self.sv.activeProfile) .. ":" .. playerKey] or self.sv.playerTemplates[playerKey])
    local key = override or self:GetTemplateKey(player and player.role)
    return self.sv.buildTemplates[key], key
end

function SC:CaptureExpectedBuild(role, snapshot, playerKey)
    snapshot = snapshot or self.localSnapshot
    if not snapshot or self.inCombat then return false, "Capture is available out of combat only." end
    local template = {values={}, createdAt=GetTimeStamp and GetTimeStamp() or 0, source=snapshot.displayName or "player"}
    local count = 0
    for _, key in ipairs(Audit.order) do
        local value = Audit.Value(snapshot, key)
        if value ~= nil then template.values[key] = value; count = count + 1 end
    end
    if count == 0 then return false, "No verified build fields to capture." end
    local key = self:GetTemplateKey(role)
    if playerKey then
        key=key .. ":" .. playerKey
        self.sv.playerTemplates[tostring(self.sv.activeProfile) .. ":" .. playerKey]=key
    end
    self.sv.buildTemplates[key] = template
    if self.RememberLoadout then self:RememberLoadout(snapshot, tostring(role or "UNKNOWN") .. " - " .. tostring(self.sv.activeProfile)) end
    return true, "Expected build saved. Enable only the checks you need."
end

function Audit.CompareValue(key, value, scope)
    if key~="champion" or value==nil then return value end
    local stars={}
    for item in tostring(value):gmatch("[^,]+") do
        local slot,discipline,id,points=item:match("^%s*(%d+):([A-Z]+):(%d+):([%w]+)%s*$")
        if not slot or discipline=="UNKNOWN" or not tonumber(points) then return nil end
        if scope=="ALL" or discipline==scope then stars[#stars+1]=discipline..":"..id..":"..points end
    end
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
            local status, reason = "UNKNOWN", "No expected value configured."
            if expected ~= nil and actual == nil then
                reason = (player and player.asui) and "This client has not shared this field, or its API data is unavailable." or "No ASUI build snapshot. Missing data; no build inference."
            elseif expected ~= nil then
                local actualCompared=Audit.CompareValue(key,actual,self.sv.championScope)
                local expectedCompared=Audit.CompareValue(key,expected,self.sv.championScope)
                if actualCompared==nil or expectedCompared==nil then
                    reason="Required field metadata is unavailable. Recapture the expected build with this version."
                else
                    status = actualCompared == expectedCompared and "PASS" or "MISMATCH"
                    reason = status == "PASS" and "Expected and actual values match." or "Actual build differs from the selected template."
                end
            end
            result.rows[#result.rows + 1] = {key=key, label=Audit.labels[key], mode=mode, status=status, expected=expected, actual=actual, reason=reason}
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
    local targetCount=tonumber(override.targetCount) or tonumber(effect.coverageLimit)
    if targetCount==0 then targetCount=nil end
    return {
        enabled = override.enabled ~= false,
        expectedStacks = math.max(1, tonumber(override.expectedStacks) or tonumber(effect.stacks) or 1),
        targetCount = targetCount,
        uptimeTarget = self.Clamp(override.uptimeTarget or 0, 0, 100),
        targetRole = override.targetRole, -- nil means all eligible recipients; never a hardcoded meta role.
    }
end
