-- Ąlpha Şquad UI - Support Coverage evaluation engine

local SC = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end

local Catalog = SC.Catalog
local EM = EVENT_MANAGER

local function Normalize(value)
    if AlphaSquadUI.Utils and AlphaSquadUI.Utils.Normalize then
        return AlphaSquadUI.Utils.Normalize(value)
    end
    return string.lower(tostring(value or ""))
end

local function UnitExistsSafe(unitTag)
    if not unitTag then return false end
    if DoesUnitExist then
        local ok, exists = pcall(DoesUnitExist, unitTag)
        if ok then return exists == true end
    end
    return true
end

local function GetUnitTagByIndex(index)
    if GetGroupUnitTagByIndex then
        local ok, unitTag = pcall(GetGroupUnitTagByIndex, index)
        if ok and unitTag and unitTag ~= "" then return unitTag end
    end
    return "group" .. tostring(index)
end

local function MergeManualCapabilities(sc, entry)
    local manual = sc.sv and sc.sv.manualCapabilities and sc.sv.manualCapabilities[entry.key]
    if type(manual) ~= "table" then return end
    entry.capabilities = entry.capabilities or {}
    for effectKey, enabled in pairs(manual) do
        if enabled and Catalog.effects[effectKey] then
            entry.capabilities[effectKey] = entry.capabilities[effectKey] or {sources={}}
            entry.capabilities[effectKey].sources["Manual"] = true
        elseif enabled == false then
            entry.capabilities[effectKey] = nil
        end
    end
end

function SC:BuildRoster()
    local roster, byKey = {}, {}
    local groupSize = GetGroupSize and GetGroupSize() or 0

    if groupSize <= 0 then
        local localData = self.localSnapshot or (self.ScanLocalPlayer and self:ScanLocalPlayer())
        if localData then
            localData.unitTag = "player"
            localData.key = localData.displayName
            localData.index = 1
            localData.role = (self.sv.roleOverrides and self.sv.roleOverrides[localData.key]) or localData.role
            MergeManualCapabilities(self, localData)
            roster[1] = localData
            byKey[localData.key] = localData
        end
        self.roster, self.byKey = roster, byKey
        return roster
    end

    local activeKeys = {}

    for index = 1, groupSize do
        local unitTag = GetUnitTagByIndex(index)
        if UnitExistsSafe(unitTag) then
            local key = self:GetPlayerKey(unitTag)
            local isSelf = unitTag == "player"
            if AreUnitsEqual then
                local ok, same = pcall(AreUnitsEqual, unitTag, "player")
                if ok and same then isSelf = true end
            end

            local entry
            if isSelf then
                entry = self.localSnapshot or (self.ScanLocalPlayer and self:ScanLocalPlayer())
                if entry then
                    entry.dataQuality = "ASUI"
                    entry.asui = true
                end
            else
                entry = self.peerData[key]
                if entry then
                    entry.unitTag = unitTag
                    entry.connected = IsUnitOnline and IsUnitOnline(unitTag) or true
                    entry.dead = IsUnitDead and IsUnitDead(unitTag) or false
                elseif self.ScanLimitedUnit then
                    entry = self:ScanLimitedUnit(unitTag)
                end
            end

            if entry then
                entry.key = key
                entry.displayName = key
                entry.unitTag = unitTag
                entry.index = index
                entry.role = (self.sv.roleOverrides and self.sv.roleOverrides[key]) or entry.role or "UNKNOWN"
                MergeManualCapabilities(self, entry)
                roster[#roster + 1] = entry
                byKey[key] = entry
                activeKeys[key] = true
            end
        end
    end

    -- Purge stale peer snapshots so rejoining players cannot inherit old build state.
    for key in pairs(self.peerData) do
        if not activeKeys[key] then self.peerData[key] = nil end
    end

    table.sort(roster, function(a, b)
        return (a.index or 999) < (b.index or 999)
    end)

    self.roster, self.byKey = roster, byKey
    return roster
end

local function RoleScore(effectKey, role)
    role = tostring(role or "")
    local effect = Catalog.effects[effectKey]
    if not effect then return 0 end

    local score = 0
    if role == "DD SUPPORT" then score = score + 35 end
    if role == "HEAL" or role == "H1" or role == "H2" then score = score + 25 end
    if role == "OT" or role == "MT/OT" then score = score + 20 end
    if role == "MT" then score = score + 15 end
    if role == "DD PARSE" then score = score + 5 end

    if effect.category == "penetration" and (role == "MT" or role == "OT" or role == "MT/OT") then score = score + 30 end
    if effect.category == "sustain" and (role == "HEAL" or role == "H1" or role == "H2") then score = score + 20 end
    if effect.category == "defense" and (role == "HEAL" or role == "H1" or role == "H2" or role == "MT" or role == "OT" or role == "MT/OT") then score = score + 20 end

    return score
end

function SC:GetCapabilityOwners(effectKey)
    local owners = {}
    for _, entry in ipairs(self.roster or {}) do
        if entry.capabilities and entry.capabilities[effectKey] then
            owners[#owners + 1] = entry
        end
    end

    table.sort(owners, function(a, b)
        local qa = a.dataQuality == "ASUI" and 100 or 0
        local qb = b.dataQuality == "ASUI" and 100 or 0
        local sa = qa + RoleScore(effectKey, a.role)
        local sb = qb + RoleScore(effectKey, b.role)
        if sa ~= sb then return sa > sb end
        return tostring(a.displayName or "") < tostring(b.displayName or "")
    end)

    return owners
end

function SC:GetAssignedOwner(effectKey, owners)
    owners = owners or self:GetCapabilityOwners(effectKey)
    local locked = self.sv.assignmentLocks and self.sv.assignmentLocks[effectKey]
    if locked and self.byKey[locked] then
        local entry = self.byKey[locked]
        if entry.capabilities and entry.capabilities[effectKey] then
            return entry, true
        end
        return entry, true, "LOCKED_MISSING"
    end

    if self.sv.autoAssign and owners[1] then return owners[1], false end
    return nil, false
end

local function IsBackup(sc, effectKey, playerKey)
    local backups = sc.sv.duplicateBackups and sc.sv.duplicateBackups[effectKey]
    return type(backups) == "table" and backups[playerKey] == true
end

function SC:EvaluateCoverage(reason)
    local profileKey = self.sv.activeProfile or "full"
    local requirements = Catalog:GetRequirements(profileKey, self.sv)
    local result = {
        profileKey = profileKey,
        profileLabel = (Catalog:GetProfile(profileKey) or {}).label or profileKey,
        requiredCount = #requirements,
        coveredCount = 0,
        missingCount = 0,
        unknownCount = 0,
        limitedPlayers = 0,
        asuiPlayers = 0,
        issues = {},
        entries = {},
        duplicates = {},
        penetration = {target=Catalog.bossArmor, covered=0, remaining=Catalog.bossArmor},
        critical = {cap=Catalog.criticalDamageCap, groupBonus=0},
        foodMissing = {},
        glyphMissing = {},
        ready = true,
    }

    for _, player in ipairs(self.roster or {}) do
        if player.dataQuality == "ASUI" then
            result.asuiPlayers = result.asuiPlayers + 1
            local food = player.food
            if food and food.active == false then
                result.foodMissing[#result.foodMissing + 1] = player.displayName
            end
            local missingGlyphs = player.equipment and player.equipment.glyphs
                and tonumber(player.equipment.glyphs.armorMissing) or 0
            if missingGlyphs > 0 then
                result.glyphMissing[#result.glyphMissing + 1] = {
                    player = player.displayName,
                    count = missingGlyphs,
                }
            end
        else
            result.limitedPlayers = result.limitedPlayers + 1
        end
    end

    for _, effectKey in ipairs(requirements) do
        local effect = Catalog.effects[effectKey]
        local owners = self:GetCapabilityOwners(effectKey)
        local assigned, locked, lockProblem = self:GetAssignedOwner(effectKey, owners)

        local status
        if #owners > 0 then
            status = "covered"
            result.coveredCount = result.coveredCount + 1
        elseif result.limitedPlayers > 0 and self.sv.showUnknown then
            status = "unknown"
            result.unknownCount = result.unknownCount + 1
        else
            status = "missing"
            result.missingCount = result.missingCount + 1
            result.ready = false
        end

        local duplicatePlayers = {}
        if #owners > 1 then
            for _, owner in ipairs(owners) do
                if not assigned or owner.key ~= assigned.key then
                    if not IsBackup(self, effectKey, owner.key) then
                        duplicatePlayers[#duplicatePlayers + 1] = owner.displayName
                    end
                end
            end
            if #duplicatePlayers > 0 then
                result.duplicates[effectKey] = duplicatePlayers
            end
        end

        if lockProblem == "LOCKED_MISSING" then
            result.ready = false
            result.issues[#result.issues + 1] = {
                severity = "error",
                text = effect.label .. " locked owner missing capability",
                key = effectKey,
            }
        end

        result.entries[#result.entries + 1] = {
            key = effectKey,
            effect = effect,
            status = status,
            owners = owners,
            assigned = assigned,
            locked = locked,
            duplicatePlayers = duplicatePlayers,
        }

        if status == "missing" then
            result.issues[#result.issues + 1] = {
                severity = effect.priority == "core" and "error" or "warning",
                text = effect.label .. " missing",
                key = effectKey,
            }
        elseif status == "unknown" then
            result.issues[#result.issues + 1] = {
                severity = "unknown",
                text = effect.label .. " unverified",
                key = effectKey,
            }
        end

        if status == "covered" then
            if effect.penetration then
                result.penetration.covered = result.penetration.covered + effect.penetration
            end
            if effect.critDamage then
                result.critical.groupBonus = result.critical.groupBonus + effect.critDamage
            end
        end
    end

    result.penetration.covered = math.min(result.penetration.target, result.penetration.covered)
    result.penetration.remaining = math.max(0, result.penetration.target - result.penetration.covered)

    for _, name in ipairs(result.foodMissing) do
        result.issues[#result.issues + 1] = {
            severity="warning",
            text=name .. " no food",
        }
        result.ready = false
    end

    for _, glyph in ipairs(result.glyphMissing) do
        result.issues[#result.issues + 1] = {
            severity="warning",
            text=string.format("%s missing %d armor glyph%s", glyph.player, glyph.count, glyph.count == 1 and "" or "s"),
        }
        result.ready = false
    end

    -- UNKNOWN data never becomes a false hard failure; the raidlead sees LIMITED instead.
    if result.missingCount == 0 and #result.foodMissing == 0 and #result.glyphMissing == 0 then
        result.ready = true
    end

    self.coverage = result

    if not self.inCombat and self.sv.showReadyBanner and self.ShowReadyBanner then
        self:ShowReadyBanner(result.ready, result.coveredCount, result.requiredCount, result.limitedPlayers)
    end

    return result
end

local function MatchObservedEffect(name, effect, abilityId)
    if SC.sv and SC.sv.customCatalog and effect and SC.sv.customCatalog[effect.key] then
        if SC.sv.customCatalog[effect.key][tostring(tonumber(abilityId) or 0)] then return true end
    end

    local observed = Normalize(name)
    local target = Normalize(effect.label)
    if observed == target then return true end
    if observed:find(target, 1, true) then return true end

    -- ESO sometimes exposes split legacy names for hybridized paired effects.
    if effect.key == "major_brutality_sorcery" then
        return observed:find("major brutality",1,true) or observed:find("major sorcery",1,true)
    elseif effect.key == "minor_brutality_sorcery" then
        return observed:find("minor brutality",1,true) or observed:find("minor sorcery",1,true)
    elseif effect.key == "major_savagery_prophecy" then
        return observed:find("major savagery",1,true) or observed:find("major prophecy",1,true)
    elseif effect.key == "minor_savagery_prophecy" then
        return observed:find("minor savagery",1,true) or observed:find("minor prophecy",1,true)
    end

    return false
end

function SC:ObserveEffectsOnUnit(unitTag)
    local observed = {}
    if not GetNumBuffs or not GetUnitBuffInfo or not unitTag then return observed, false end

    local ok, count = pcall(GetNumBuffs, unitTag)
    if not ok or not tonumber(count) then return observed, false end
    count = tonumber(count) or 0

    for i = 1, count do
        local success, name, _, ending, _, stacks, _, _, _, _, statusEffectType, abilityId =
            pcall(GetUnitBuffInfo, unitTag, i)
        if success and name and name ~= "" then
            for key, effect in pairs(Catalog.effects) do
                if MatchObservedEffect(name, effect, abilityId) then
                    observed[key] = {
                        name = name,
                        abilityId = tonumber(abilityId) or 0,
                        ending = tonumber(ending) or 0,
                        stacks = tonumber(stacks) or 0,
                        statusEffectType = statusEffectType,
                    }
                end
            end
        end
    end

    return observed, true
end

function SC:SampleLiveCoverage()
    if not self.inCombat or not self.sv or not self.sv.enabled then return end
    local coverage = self.coverage
    if not coverage or not coverage.entries then return end

    local groupObserved = {}
    local unitReadable = 0

    for _, player in ipairs(self.roster or {}) do
        local observed, readable = self:ObserveEffectsOnUnit(player.unitTag)
        if readable then unitReadable = unitReadable + 1 end
        for key in pairs(observed) do
            groupObserved[key] = (groupObserved[key] or 0) + 1
        end
    end

    local bossObserved, bossReadable = self:ObserveEffectsOnUnit("reticleover")
    local now = self.NowMs()
    local sampleMs = 1250

    for _, row in ipairs(coverage.entries) do
        local key = row.key
        local effect = row.effect
        local known, live, count = false, false, 0

        if effect.boss and bossReadable then
            known = true
            live = bossObserved[key] ~= nil
            count = live and 1 or 0
        elseif effect.group and unitReadable > 0 then
            known = true
            count = groupObserved[key] or 0
            live = count > 0
        end

        row.liveKnown = known
        row.live = live
        row.liveCount = count
        row.liveTotal = effect.group and unitReadable or (effect.boss and 1 or 0)

        if self.pull and known then
            self.pull.samples = (self.pull.samples or 0) + 1
            self.pull.effectKnownMs = self.pull.effectKnownMs or {}
            self.pull.effectKnownMs[key] = (self.pull.effectKnownMs[key] or 0) + sampleMs
            self.pull.effectUpMs[key] = self.pull.effectUpMs[key] or 0
            self.pull.longestGapMs[key] = self.pull.longestGapMs[key] or 0
            self.pull.gapStartedAt[key] = self.pull.gapStartedAt[key]

            if live then
                self.pull.effectUpMs[key] = self.pull.effectUpMs[key] + sampleMs
                local started = self.pull.gapStartedAt[key]
                if started then
                    self.pull.longestGapMs[key] = math.max(self.pull.longestGapMs[key], now - started)
                    self.pull.gapStartedAt[key] = nil
                end
            elseif not self.pull.gapStartedAt[key] then
                self.pull.gapStartedAt[key] = now
            end
        end
    end

    if self.RefreshHUD then self:RefreshHUD() end
end

function SC:SetLiveUpdateActive(enabled)
    enabled = enabled == true
    if self.liveUpdateActive == enabled then return end
    self.liveUpdateActive = enabled
    local name = "AlphaSquadUI_SupportCoverage_Live"

    if enabled then
        EM:RegisterForUpdate(name, 1250, function()
            if SC then SC:SampleLiveCoverage() end
        end)
    else
        EM:UnregisterForUpdate(name)
    end
end

function SC:FinalizePull()
    if not self.pull then return end
    local now = self.NowMs()
    local pull = self.pull
    pull.endedAt = now
    pull.durationMs = math.max(0, now - (pull.startedAt or now))
    pull.summary = {}

    for key, knownMs in pairs(pull.effectKnownMs or {}) do
        local upMs = pull.effectUpMs[key] or 0
        local started = pull.gapStartedAt[key]
        if started then
            pull.longestGapMs[key] = math.max(pull.longestGapMs[key] or 0, now - started)
        end
        pull.summary[key] = {
            uptime = knownMs > 0 and math.floor((upMs / knownMs) * 1000 + 0.5) / 10 or nil,
            longestGapMs = pull.longestGapMs[key] or 0,
        }
    end

    self.lastPull = pull
    self.pull = nil
    self:SetLiveUpdateActive(false)
end
