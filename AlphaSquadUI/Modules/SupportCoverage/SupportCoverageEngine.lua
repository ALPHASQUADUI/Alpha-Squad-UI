-- Ąlpha Şquad UI - Support Coverage evaluation engine

local SC = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
if not SC then return end

local Catalog = SC.Catalog
local EM = EVENT_MANAGER

local function ScoreValue(value)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge then return 0 end
    return math.max(0,math.min(31,value))
end

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

local function SnapshotView(source)
    if not source then return nil end
    local view = {}
    for key, value in pairs(source) do view[key] = value end
    view.capabilities = SC.Audit.Copy(source.capabilities or {})
    return view
end

function SC:BuildRoster()
    local roster, byKey = {}, {}
    local groupSize = tonumber(GetGroupSize and GetGroupSize())
    if not groupSize or groupSize~=groupSize or groupSize==math.huge or groupSize==-math.huge then groupSize=0 end
    groupSize = math.max(0, math.min(12, math.floor(groupSize)))

    if groupSize <= 0 then
        local localData = SnapshotView(self.localSnapshot or (self.ScanLocalPlayer and self:ScanLocalPlayer()))
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
                entry = SnapshotView(self.localSnapshot or (self.ScanLocalPlayer and self:ScanLocalPlayer()))
                if entry then
                    entry.dataQuality = "ASUI"
                    entry.asui = true
                end
            else
                local peer = self.peerData[key]
                entry = peer and SnapshotView(peer) or (self.ScanLimitedUnit and self:ScanLimitedUnit(unitTag))
                if entry then
                    if peer and self.NowMs() - (peer.scannedAt or 0) > 75000 then
                        -- Keep fresh live/detail evidence but never keep old build capabilities green.
                        entry.capabilities, entry.equipment = {}, nil
                        entry.food, entry.potion = nil, nil
                        entry.buildVerified = false
                        local liveFresh=peer.liveUpdatedAt and self.NowMs()-(peer.liveUpdatedAt or 0)<=5500
                        entry.dataQuality = liveFresh and "ASUI LIVE" or "STALE"
                    end
                    entry.unitTag = unitTag
                    entry.connected = self:IsOnline(unitTag)
                    entry.dead = self.Try(IsUnitDead, unitTag) == true
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
        if not activeKeys[key] then
            self.peerData[key] = nil
            if self.detailReceivers then self.detailReceivers[key] = nil end
        end
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
        if entry.connected ~= false and entry.dead ~= true and entry.capabilities and entry.capabilities[effectKey] then
            owners[#owners + 1] = entry
        end
    end

    table.sort(owners, function(a, b)
        local qa = (a.dataQuality == "ASUI" or a.buildVerified == true) and 100 or 0
        local qb = (b.dataQuality == "ASUI" or b.buildVerified == true) and 100 or 0
        local sa = qa + RoleScore(effectKey, a.role) + ScoreValue(a.supportScore)
        local sb = qb + RoleScore(effectKey, b.role) + ScoreValue(b.supportScore)
        if sa ~= sb then return sa > sb end
        return tostring(a.displayName or "") < tostring(b.displayName or "")
    end)

    return owners
end

function SC:GetAssignedOwner(effectKey, owners)
    owners = owners or self:GetCapabilityOwners(effectKey)
    local locked = self.sv.assignmentLocks and self.sv.assignmentLocks[effectKey]
    if locked and not self.byKey[locked] then return nil, true, "LOCKED_MISSING" end
    if locked and self.byKey[locked] then
        local entry = self.byKey[locked]
        if entry.connected ~= false and entry.dead ~= true and entry.capabilities and entry.capabilities[effectKey] then
            return entry, true
        end
        return entry, true, "LOCKED_MISSING"
    end

    self.assignmentLoad = self.assignmentLoad or {}
    if self.sv.autoAssign and owners[1] then
        -- Spread duties across observed capable owners; never fabricate equipment swaps.
        local chosen, bestScore
        for _, owner in ipairs(owners) do
            local score = RoleScore(effectKey, owner.role) - 12 * ((self.assignmentLoad or {})[owner.key] or 0)
            if owner.connected ~= false and (not bestScore or score > bestScore) then chosen, bestScore = owner, score end
        end
        if chosen then
            self.assignmentLoad[chosen.key] = (self.assignmentLoad[chosen.key] or 0) + 1
            return chosen, false
        end
    end
    return nil, false
end

local function IsBackup(sc, effectKey, playerKey)
    local backups = sc.sv.duplicateBackups and sc.sv.duplicateBackups[effectKey]
    return type(backups) == "table" and backups[playerKey] == true
end

function SC:EvaluateCoverage(reason)
    self.assignmentLoad = {}
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
        foodExpiring = {},
        glyphMissing = {},
        readinessUnknownCount = 0,
        ready = true,
        capabilityDataIncomplete = false,
    }

    for _, player in ipairs(self.roster or {}) do
        if player.connected ~= false and player.capabilitiesComplete ~= true then result.capabilityDataIncomplete = true end
        local buildKnown = player.dataQuality == "ASUI" or player.buildVerified == true
        if buildKnown then
            result.asuiPlayers = result.asuiPlayers + 1
        else
            result.limitedPlayers = result.limitedPlayers + 1
        end
        if player.connected == false then
            result.ready = false
            result.issues[#result.issues + 1] = {severity="error", text=player.displayName .. " - offline"}
        elseif player.dead == true then
            result.ready = false
            result.issues[#result.issues + 1] = {severity="warning", text=player.displayName .. " - dead"}
        else
            local food = player.food
            if self.sv.checkFoodPresence then
                if not food or food.verified ~= true then
                    result.readinessUnknownCount = result.readinessUnknownCount + 1
                    result.issues[#result.issues + 1] = {severity="unknown", text=player.displayName .. " - food unverified"}
                elseif food.active == false then
                    result.foodMissing[#result.foodMissing + 1] = player.displayName
                elseif tonumber(food.timeEnds) and tonumber(food.timeEnds) > 0 and (self.sv.foodWarningSeconds or 0) > 0 then
                    local remaining = tonumber(food.timeEnds) - self.NowMs()/1000
                    if remaining > 0 and remaining <= self.sv.foodWarningSeconds then
                        result.foodExpiring[#result.foodExpiring + 1] = {player=player.displayName, seconds=remaining}
                    end
                end
            end
            if self.sv.checkMissingGlyphs then
                local glyphs = player.equipment and player.equipment.glyphs
                if not glyphs or glyphs.verified ~= true then
                    result.readinessUnknownCount = result.readinessUnknownCount + 1
                    result.issues[#result.issues + 1] = {severity="unknown", text=player.displayName .. " - armor glyphs unverified"}
                else
                    local missingGlyphs = tonumber(glyphs.armorMissing) or 0
                    if missingGlyphs > 0 then
                        result.glyphMissing[#result.glyphMissing + 1] = {player=player.displayName, count=missingGlyphs}
                    end
                end
            end
        end
    end

    for _, player in ipairs(self.roster or {}) do
        player.audit = self:EvaluateBuildAudit(player)
        for _, check in ipairs(player.audit.rows) do
            if check.status == "MISMATCH" then
                result.issues[#result.issues + 1] = {severity=check.mode == "REQUIRED" and "error" or "warning", text=player.displayName .. " - " .. check.label .. " mismatch"}
            elseif check.status == "UNKNOWN" then
                result.issues[#result.issues + 1] = {severity="unknown", text=player.displayName .. " - " .. check.label .. " unverified"}
            end
        end
        if player.audit.requiredFailures > 0 or player.audit.requiredUnknown > 0 then result.ready = false end
    end

    for _, effectKey in ipairs(requirements) do
        local effect = Catalog.effects[effectKey]
        local owners = self:GetCapabilityOwners(effectKey)
        local assigned, locked, lockProblem = self:GetAssignedOwner(effectKey, owners)

        local unsupportedPeer=false
        if effect.wireV1Unavailable then
            for _,player in ipairs(self.roster) do
                if not self:IsSelf(player.unitTag) and (tonumber(player.protocolVersion) or 0)<2 then unsupportedPeer=true end
            end
        end
        local status
        local unverified = result.capabilityDataIncomplete or result.limitedPlayers > 0 or unsupportedPeer
        if #owners > 0 then
            status = "covered"
            result.coveredCount = result.coveredCount + 1
        else
            status = "missing"
            result.missingCount = result.missingCount + 1
            if unverified then result.unknownCount = result.unknownCount + 1 end
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
            unverified = status == "missing" and unverified,
        }

        if status == "missing" then
            result.issues[#result.issues + 1] = {
                severity = unverified and "unknown" or (effect.priority == "core" and "error" or "warning"),
                text = effect.label .. (unverified and " - no reported source (roster incomplete)" or " - no source"),
                key = effectKey,
                unverified = unverified,
            }
        end

        if status == "covered" then
            if effect.penetration then
                result.penetration.covered = result.penetration.covered + effect.penetration
            end
            -- Personal buffs may be useful build checks, but they are not group critical-damage coverage.
            if effect.critDamage and not effect.personal then
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

    for _, food in ipairs(result.foodExpiring) do
        result.issues[#result.issues + 1] = {
            severity="warning",
            text=string.format("%s food expires in %d minute%s", food.player,
                math.max(1, math.ceil(food.seconds/60)), food.seconds > 60 and "s" or ""),
        }
    end

    -- UNKNOWN data never becomes a false hard failure; the raidlead sees LIMITED instead.
    if result.unknownCount > 0 or result.readinessUnknownCount > 0 then result.ready = false end
    -- Never overwrite errors from locked owners or REQUIRED build checks.
    for _, issue in ipairs(result.issues) do
        if issue.severity == "error" then result.ready = false end
    end

    local severity = {error=1, warning=2, unknown=3}
    table.sort(result.issues, function(a, b)
        local sa, sb = severity[a.severity] or 4, severity[b.severity] or 4
        if sa ~= sb then return sa < sb end
        return a.text < b.text
    end)
    result.budgetEvidence = "PLANNED_ONLY"
    self.coverage = result

    if not self.inCombat and self.sv.showReadyBanner and self.ShowReadyBanner then
        local limited=result.limitedPlayers+((result.unknownCount>0 or result.readinessUnknownCount>0) and 1 or 0)
        self:ShowReadyBanner(result.ready, result.coveredCount, result.requiredCount, limited)
    end

    return result
end
