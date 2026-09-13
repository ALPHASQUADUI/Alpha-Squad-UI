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

local function SnapshotView(source)
    if not source then return nil end
    local view = {}
    for key, value in pairs(source) do view[key] = value end
    view.capabilities = SC.Audit.Copy(source.capabilities or {})
    return view
end

function SC:BuildRoster()
    if self.PruneExternalSources then self:PruneExternalSources() end
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
                local characterName = self.Try(GetUnitName, unitTag)
                if peer and peer.characterName and peer.characterName ~= "" and characterName and characterName ~= peer.characterName then
                    self.peerData[key] = nil
                    if self.detailReceivers then self.detailReceivers[key] = nil end
                    peer = nil
                end
                entry = peer and SnapshotView(peer) or (self.ScanLimitedUnit and self:ScanLimitedUnit(unitTag))
                if entry then
                    if peer and self.NowMs() - (peer.scannedAt or 0) > 75000 then
                        -- Expired summaries invalidate every private build field.
                        entry.capabilities, entry.equipment, entry.skills, entry.masteries = {}, nil, nil, nil
                        entry.food, entry.potion, entry.poisons, entry.mundus = self:ScanFood(unitTag), nil, nil, nil
                        entry.buildVerified, entry.capabilitiesComplete = false, false
                        entry.dataQuality = "STALE"
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
                if not isSelf and self.MergeExternalCapabilities then self:MergeExternalCapabilities(entry, true) end
                entry.role = entry.role or "UNKNOWN"
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

function SC:GetCapabilityOwners(effectKey)
    local owners = {}
    for _, entry in ipairs(self.roster or {}) do
        if entry.connected ~= false and entry.dead ~= true and entry.capabilities and entry.capabilities[effectKey] then
            owners[#owners + 1] = entry
        end
    end

    table.sort(owners, function(a, b)
        return tostring(a.displayName or "") < tostring(b.displayName or "")
    end)

    return owners
end

function SC:EvaluateCoverage(reason)
    local profileKey = self.sv.activeProfile or "trial"
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

    for _, effectKey in ipairs(requirements) do
        local effect = Catalog.effects[effectKey]
        local owners = self:GetCapabilityOwners(effectKey)
        local assigned = owners[1]

        local unsupportedPeer=false
        if effect.wireV1Unavailable then
            for _,player in ipairs(self.roster) do
                if not self:IsSelf(player.unitTag) and (tonumber(player.protocolVersion) or 0)<2 then unsupportedPeer=true end
            end
        end
        local status
        local unverified = result.capabilityDataIncomplete or result.limitedPlayers > 0 or unsupportedPeer
        local allPersonal = not effect.personal
        if effect.personal then
            allPersonal = #self.roster > 0
            for _, player in ipairs(self.roster) do
                if player.connected ~= false and player.dead ~= true
                    and not (player.capabilities and player.capabilities[effectKey]) then allPersonal = false end
            end
        end
        if #owners > 0 and allPersonal then
            status = "covered"
            result.coveredCount = result.coveredCount + 1
        else
            status = "missing"
            result.missingCount = result.missingCount + 1
            if unverified then result.unknownCount = result.unknownCount + 1 end
            result.ready = false
        end

        local duplicatePlayers = {}
        if #owners > 1 and not effect.personal then
            -- Every source holder is visible. Repeated named buffs do not stack;
            -- limited-target sources may still need multiple users for a trial.
            for _, owner in ipairs(owners) do duplicatePlayers[#duplicatePlayers + 1] = owner.displayName end
            result.duplicates[effectKey] = duplicatePlayers
        end

        result.entries[#result.entries + 1] = {
            key = effectKey,
            effect = effect,
            status = status,
            owners = owners,
            assigned = assigned,
            locked = false,
            sourceOnly = true,
            partialRecipients = effect.coverageLimit and effect.coverageLimit < #self.roster or false,
            duplicatePlayers = duplicatePlayers,
            unverified = status == "missing" and unverified,
        }

        if status == "missing" then
            result.issues[#result.issues + 1] = {
                severity = unverified and "unknown" or (effect.priority == "core" and "error" or "warning"),
                text = effect.label .. (effect.personal and " - check each player" or (unverified and " - no reported source (roster incomplete)" or " - no source")),
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
    result.budgetEvidence = "SOURCE_CAPABILITY_ONLY"
    self.coverage = result

    return result
end
