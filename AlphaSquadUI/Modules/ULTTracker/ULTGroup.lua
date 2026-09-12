--[[
    Ąlpha Şquad UI - ULT Tracker / Group Tracking
    Author: SeRuM1

    Group Ultimate data is received through LibGroupCombatStats when available.
    The personal ULT Tracker remains fully functional without that library.
]]

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}

local ULT = AlphaSquadUI.Modules.ULTTracker
if not ULT then return end

ULT.Group = ULT.Group or {}
local Group = ULT.Group

Group.version = "0.1.0"
Group.lgcs = nil
Group.libraryAvailable = false
Group.roster = {}
Group.byKey = {}
Group.byUnitTag = {}
Group.refreshPending = false
Group.readyState = {}
Group.lastReadySoundAt = 0
Group.previousUltValues = Group.previousUltValues or {}
Group.recentlyUsedUntil = Group.recentlyUsedUntil or {}
Group.initialized = false

local EM = EVENT_MANAGER

local function NowMs()
    if GetGameTimeMilliseconds then return GetGameTimeMilliseconds() end
    return 0
end

local function SafeText(value)
    return tostring(value or "")
end

local function UnitExists(unitTag)
    if not unitTag or unitTag == "" then return false end
    if DoesUnitExist then return DoesUnitExist(unitTag) end
    return true
end

local function GetCharacterName(unitTag)
    if GetUnitName then
        local name = GetUnitName(unitTag)
        if name and name ~= "" then return zo_strformat("<<C:1>>", name) end
    end
    return unitTag or "Unknown"
end

local function GetDisplayNameSafe(unitTag)
    if GetUnitDisplayName then
        local name = GetUnitDisplayName(unitTag)
        if name and name ~= "" then return name end
    end
    return ""
end

function Group:GetDefaults()
    local rootW = GuiRoot and GuiRoot:GetWidth() or 1920
    local rootH = GuiRoot and GuiRoot:GetHeight() or 1080
    return {
        enabled = false,
        visible = true,
        locked = false,
        includeSelf = false,
        readySound = false,
        hideInMenus = true,
        scale = 100,
        hudWidth = 312,
        rowHeight = 36,
        opacity = 92,
        x = math.floor(rootW * 0.70),
        y = math.floor(rootH * 0.16),
        positionSaved = false,
        trackedAbilities = {},
    }
end

function Group:EnsureSavedVariables()
    if not ULT.sv then return end

    if type(ULT.sv.group) ~= "table" then
        ULT.sv.group = {}
    end

    local defaults = self:GetDefaults()
    for key, value in pairs(defaults) do
        if ULT.sv.group[key] == nil then
            ULT.sv.group[key] = value
        end
    end

    -- Cleanup migration from the retired per-player FRONT/BACK prototype.
    -- The current raidlead workflow stores only selected Ultimate ability IDs.
    ULT.sv.group.assignments = nil

    if type(ULT.sv.group.trackedAbilities) ~= "table" then
        ULT.sv.group.trackedAbilities = {}
    end

    -- Persistent per-account HUD geometry. Existing users keep their saved values.
    ULT.sv.group.scale = ULT.Clamp(ULT.sv.group.scale or 100, 60, 180)
    ULT.sv.group.hudWidth = ULT.Clamp(ULT.sv.group.hudWidth or 312, 240, 520)
    ULT.sv.group.rowHeight = ULT.Clamp(ULT.sv.group.rowHeight or 36, 28, 56)
    ULT.sv.group.opacity = ULT.Clamp(ULT.sv.group.opacity or 92, 30, 100)
    self.sv = ULT.sv.group
end

function Group:IsAbilityTracked(abilityId)
    if not self.sv or type(self.sv.trackedAbilities) ~= "table" then return false end
    abilityId = tonumber(abilityId) or 0
    return abilityId > 0 and self.sv.trackedAbilities[tostring(abilityId)] == true
end

function Group:SetAbilityTracked(abilityId, tracked)
    if not self.sv then return end
    abilityId = tonumber(abilityId) or 0
    if abilityId <= 0 then return end

    local key = tostring(abilityId)
    if tracked then
        self.sv.trackedAbilities[key] = true
    else
        self.sv.trackedAbilities[key] = nil
    end

    self:Refresh("tracked ability changed")
end

function Group:GetAvailableAbilities()
    local abilitiesById = {}

    for _, entry in ipairs(self.roster or {}) do
        if entry.shared then
            for _, abilityId in ipairs({entry.ult1ID, entry.ult2ID}) do
                abilityId = tonumber(abilityId) or 0
                if abilityId > 0 and not abilitiesById[abilityId] then
                    local name, icon = self:GetAbilityMeta(abilityId)
                    abilitiesById[abilityId] = {
                        id = abilityId,
                        name = name,
                        icon = icon,
                        users = 0,
                    }
                end
            end
        end
    end

    for _, entry in ipairs(self.roster or {}) do
        if entry.shared then
            local seen = {}
            for _, abilityId in ipairs({entry.ult1ID, entry.ult2ID}) do
                abilityId = tonumber(abilityId) or 0
                if abilityId > 0 and not seen[abilityId] and abilitiesById[abilityId] then
                    abilitiesById[abilityId].users = abilitiesById[abilityId].users + 1
                    seen[abilityId] = true
                end
            end
        end
    end

    local result = {}
    for _, ability in pairs(abilitiesById) do
        table.insert(result, ability)
    end

    table.sort(result, function(a, b)
        local an = string.lower(a.name or "")
        local bn = string.lower(b.name or "")
        if an == bn then return (a.id or 0) < (b.id or 0) end
        return an < bn
    end)

    return result
end

function Group:GetTrackedAbilityCount()
    local count = 0
    if not self.sv or type(self.sv.trackedAbilities) ~= "table" then return 0 end
    for _, enabled in pairs(self.sv.trackedAbilities) do
        if enabled == true then count = count + 1 end
    end
    return count
end

function Group:GetAbilityMeta(abilityId)
    abilityId = tonumber(abilityId) or 0
    if abilityId <= 0 then return "No Ultimate", "", 0 end

    local name = GetAbilityName and GetAbilityName(abilityId) or ""
    local icon = GetAbilityIcon and GetAbilityIcon(abilityId) or ""
    if not name or name == "" then name = "Ultimate " .. tostring(abilityId) end

    return zo_strformat("<<C:1>>", name), icon or "", abilityId
end

function Group:InitializeSharing()
    self.libraryAvailable = false
    self.lgcs = nil

    if not LibGroupCombatStats or not LibGroupCombatStats.RegisterAddon then
        return false
    end

    local ok, result = pcall(function()
        return LibGroupCombatStats.RegisterAddon("AlphaSquadUIULTTracker", {"ULT"})
    end)

    if not ok or not result then
        return false
    end

    self.lgcs = result
    self.libraryAvailable = true

    if result.RegisterForEvent then
        if LibGroupCombatStats.EVENT_GROUP_ULT_UPDATE then
            result:RegisterForEvent(LibGroupCombatStats.EVENT_GROUP_ULT_UPDATE, function(unitTag, data)
                Group:OnGroupUltUpdate(unitTag, data)
            end)
        end

        -- Keep Include Self equally responsive without waiting for the safety sync.
        if LibGroupCombatStats.EVENT_PLAYER_ULT_UPDATE then
            result:RegisterForEvent(LibGroupCombatStats.EVENT_PLAYER_ULT_UPDATE, function(unitTag, data)
                Group:OnGroupUltUpdate(unitTag, data)
            end)
        end
    end

    return true
end

function Group:GetUltForUnit(unitTag)
    if not self.lgcs or not self.lgcs.GetUnitULT then return nil end

    local ok, ult = pcall(function()
        return self.lgcs:GetUnitULT(unitTag)
    end)

    if ok then return ult end
    return nil
end

function Group:GetUnitTagByIndex(index)
    if GetGroupUnitTagByIndex then
        local tag = GetGroupUnitTagByIndex(index)
        if tag and tag ~= "" then return tag end
    end

    local fallback = "group" .. tostring(index)
    if UnitExists(fallback) then return fallback end
    return nil
end

function Group:BuildRoster()
    local roster = {}
    local byKey = {}
    local byUnitTag = {}
    local groupSize = GetGroupSize and GetGroupSize() or 0

    if groupSize <= 0 then
        self.roster = roster
        self.byKey = byKey
        self.byUnitTag = byUnitTag
        return roster
    end

    for index = 1, groupSize do
        local unitTag = self:GetUnitTagByIndex(index)

        if unitTag and UnitExists(unitTag) then
            local displayName = GetDisplayNameSafe(unitTag)
            local characterName = GetCharacterName(unitTag)
            local stableKey = displayName ~= "" and displayName or characterName
            if stableKey == "" then stableKey = unitTag end

            local ult = self:GetUltForUnit(unitTag)

            local isPlayer = unitTag == "player"
            if AreUnitsEqual then
                local ok, same = pcall(AreUnitsEqual, unitTag, "player")
                if ok and same then isPlayer = true end
            end

            local entry = {
                index = index,
                unitTag = unitTag,
                key = stableKey,
                displayName = displayName,
                characterName = characterName,
                isPlayer = isPlayer,
                shared = ult ~= nil and ult.ultValue ~= nil,
                ultValue = ult and tonumber(ult.ultValue) or 0,
                ult1ID = ult and tonumber(ult.ult1ID) or 0,
                ult2ID = ult and tonumber(ult.ult2ID) or 0,
                ult1Cost = ult and tonumber(ult.ult1Cost) or 0,
                ult2Cost = ult and tonumber(ult.ult2Cost) or 0,
                lastUpdated = ult and ult._lastUpdated or nil,
            }

            table.insert(roster, entry)
            byKey[entry.key] = entry
            byUnitTag[unitTag] = entry
        end
    end

    table.sort(roster, function(a, b)
        return (a.index or 999) < (b.index or 999)
    end)

    self.roster = roster
    self.byKey = byKey
    self.byUnitTag = byUnitTag
    return roster
end

function Group:UpdateEntryFromUltData(unitTag, data)
    if not unitTag or not data then return false end

    local entry = self.byUnitTag and self.byUnitTag[unitTag] or nil
    if not entry and AreUnitsEqual then
        for tag, candidate in pairs(self.byUnitTag or {}) do
            local ok, same = pcall(AreUnitsEqual, tag, unitTag)
            if ok and same then
                entry = candidate
                break
            end
        end
    end

    if not entry then return false end

    entry.shared = data.ultValue ~= nil
    entry.ultValue = tonumber(data.ultValue) or entry.ultValue or 0
    entry.ult1ID = tonumber(data.ult1ID) or entry.ult1ID or 0
    entry.ult2ID = tonumber(data.ult2ID) or entry.ult2ID or 0
    entry.ult1Cost = tonumber(data.ult1Cost) or entry.ult1Cost or 0
    entry.ult2Cost = tonumber(data.ult2Cost) or entry.ult2Cost or 0
    entry.lastUpdated = data._lastUpdated or entry.lastUpdated

    return true
end

function Group:BuildUltimate(entry, slot)
    if not entry then return nil end

    local isMain = slot == "main"
    local id = tonumber(isMain and entry.ult1ID or entry.ult2ID) or 0
    local cost = tonumber(isMain and entry.ult1Cost or entry.ult2Cost) or 0
    local value = tonumber(entry.ultValue) or 0
    local name, icon = self:GetAbilityMeta(id)

    return {
        slot = isMain and "main" or "back",
        id = id,
        cost = cost,
        value = value,
        name = name,
        icon = icon,
        ready = id > 0 and cost > 0 and value >= cost,
    }
end

function Group:GetMatchingUltimates(entry)
    local matches = {}
    if not entry or not entry.shared then return matches end

    local front = self:BuildUltimate(entry, "main")
    local back = self:BuildUltimate(entry, "back")

    if front and self:IsAbilityTracked(front.id) then
        table.insert(matches, front)
    end
    if back and self:IsAbilityTracked(back.id) and back.id ~= (front and front.id or 0) then
        table.insert(matches, back)
    end

    return matches
end

function Group:GetBestMatchingUltimate(entry)
    local matches = entry and (entry.matchingUltimates or self:GetMatchingUltimates(entry)) or {}
    local best = nil
    local bestPercent = -1

    for _, ultimate in ipairs(matches) do
        local cost = tonumber(ultimate.cost) or 0
        local value = tonumber(ultimate.value) or tonumber(entry and entry.ultValue) or 0
        local percent = 0

        if cost > 0 then
            percent = math.min(100, math.max(0, math.floor(((value / cost) * 100) + 0.5)))
        end

        if ultimate.ready then
            percent = 100
        end

        if not best
            or (ultimate.ready == true and best.ready ~= true)
            or (ultimate.ready == best.ready and percent > bestPercent)
        then
            best = ultimate
            bestPercent = percent
        end
    end

    return best, math.max(0, bestPercent)
end

function Group:GetTrackedEntries()
    local result = {}

    for _, entry in ipairs(self.roster or {}) do
        local include = true

        if entry.isPlayer and self.sv and not self.sv.includeSelf then
            include = false
        end

        if include and entry.shared then
            entry.matchingUltimates = self:GetMatchingUltimates(entry)

            if #entry.matchingUltimates > 0 then
                entry.anyReady = false
                for _, ultimate in ipairs(entry.matchingUltimates) do
                    if ultimate.ready then
                        entry.anyReady = true
                        break
                    end
                end

                entry.recentlyUsed = NowMs() < (self.recentlyUsedUntil[entry.key] or 0)
                entry.bestUltimate, entry.chargePercent = self:GetBestMatchingUltimate(entry)
                table.insert(result, entry)
            end
        end
    end

    table.sort(result, function(a, b)
        -- READY always at the top for raidlead visibility.
        if a.anyReady ~= b.anyReady then return a.anyReady == true end

        -- Recently spent Ultimates are deliberately pushed to the bottom.
        if a.recentlyUsed ~= b.recentlyUsed then return a.recentlyUsed == false end

        -- Among charging players, show the closest-to-ready players first.
        local aPercent = tonumber(a.chargePercent) or 0
        local bPercent = tonumber(b.chargePercent) or 0
        if aPercent ~= bPercent then return aPercent > bPercent end

        return string.lower(a.displayName or a.key or "") < string.lower(b.displayName or b.key or "")
    end)

    return result
end

function Group:GetSharingCount()
    local shared = 0
    for _, entry in ipairs(self.roster or {}) do
        if entry.shared then shared = shared + 1 end
    end
    return shared, #(self.roster or {})
end

function Group:PlayReadySound()
    if not self.sv or not self.sv.readySound or not PlaySound or not SOUNDS then return end
    if ULT.uiObscured then return end

    local now = NowMs()
    if now - (self.lastReadySoundAt or 0) < 700 then return end
    self.lastReadySoundAt = now

    local soundId =
        SOUNDS.ABILITY_ULTIMATE_READY
        or SOUNDS.GENERAL_ALERT_NOTIFICATION
        or SOUNDS.POSITIVE_CLICK

    if soundId then PlaySound(soundId) end
end

function Group:CheckReadyTransitions()
    if not self.sv or not self.sv.enabled then return end

    local activeKeys = {}
    local now = NowMs()

    for _, entry in ipairs(self.roster or {}) do
        if entry.shared then
            local value = tonumber(entry.ultValue) or 0
            local previousValue = self.previousUltValues[entry.key]

            if previousValue ~= nil and value < previousValue then
                local matches = self:GetMatchingUltimates(entry)
                local wasReadyForTracked = false

                for _, ultimate in ipairs(matches) do
                    local cost = tonumber(ultimate.cost) or 0
                    if cost > 0 and previousValue >= cost then
                        wasReadyForTracked = true
                        break
                    end
                end

                if wasReadyForTracked and (previousValue - value) >= 20 then
                    self.recentlyUsedUntil[entry.key] = now + 6000
                end
            end

            self.previousUltValues[entry.key] = value

            for _, ultimate in ipairs(self:GetMatchingUltimates(entry)) do
                local stateKey = tostring(entry.key) .. ":" .. tostring(ultimate.id)
                activeKeys[stateKey] = true

                local readyNow = ultimate.ready == true
                local previousReady = self.readyState[stateKey] == true

                if readyNow and not previousReady then
                    self:PlayReadySound()
                end

                self.readyState[stateKey] = readyNow
            end
        end
    end

    for key in pairs(self.readyState) do
        if not activeKeys[key] then self.readyState[key] = nil end
    end
end

function Group:RefreshIntegratedSettings()
    local settings = AlphaSquadUI and AlphaSquadUI.Settings
    local mainWindow = settings and settings.mainWindow
    if not mainWindow or mainWindow:IsHidden() then return end

    local refresh = settings and settings.RefreshMain
    if refresh then refresh() end
end

function Group:ScheduleRefresh(rebuildRoster)
    if not self.sv then return end

    local configVisible = self.configWindow and not self.configWindow:IsHidden() or false
    local settings = AlphaSquadUI and AlphaSquadUI.Settings
    local mainSettingsVisible = settings and settings.mainWindow and not settings.mainWindow:IsHidden() or false

    if not self.sv.enabled and not configVisible and not mainSettingsVisible then
        return
    end

    if rebuildRoster then
        self.pendingRosterRebuild = true
    end

    if self.refreshPending then return end
    self.refreshPending = true

    zo_callLater(function()
        local needsRoster = Group.pendingRosterRebuild == true
        Group.pendingRosterRebuild = false
        Group.refreshPending = false
        Group:Refresh("scheduled", needsRoster)
    end, 40)
end

function Group:Refresh(reason, rebuildRoster)
    if not self.initialized or not self.sv then return end

    if rebuildRoster ~= false then
        self:BuildRoster()
    end

    if self.sv.enabled then
        self:CheckReadyTransitions()
        self:RefreshHUD()
    elseif self.ApplyVisibility then
        self:ApplyVisibility()
    end

    self:RefreshConfig()
    self:RefreshIntegratedSettings()
end

function Group:OnGroupUltUpdate(unitTag, data)
    if self:UpdateEntryFromUltData(unitTag, data) then
        self:ScheduleRefresh(false)
    else
        -- Unit tags can change when the roster is rebuilt; recover safely.
        self:ScheduleRefresh(true)
    end
end

function Group:RegisterRosterEvents()
    local prefix = "AlphaSquadUI_ULTGroup"

    local function RosterChanged()
        zo_callLater(function()
            if Group then Group:Refresh("group roster", true) end
        end, 100)
    end

    if EVENT_GROUP_MEMBER_JOINED then
        EM:RegisterForEvent(prefix .. "_Joined", EVENT_GROUP_MEMBER_JOINED, RosterChanged)
    end
    if EVENT_GROUP_MEMBER_LEFT then
        EM:RegisterForEvent(prefix .. "_Left", EVENT_GROUP_MEMBER_LEFT, RosterChanged)
    end
    if EVENT_GROUP_UPDATE then
        EM:RegisterForEvent(prefix .. "_Update", EVENT_GROUP_UPDATE, RosterChanged)
    end
    if EVENT_GROUP_MEMBER_CONNECTED_STATUS then
        EM:RegisterForEvent(prefix .. "_Connected", EVENT_GROUP_MEMBER_CONNECTED_STATUS, RosterChanged)
    end

    -- Low-frequency fallback only while the feature is enabled.
    EM:RegisterForUpdate(prefix .. "_Safety", 2000, function()
        if Group
            and Group.initialized
            and Group.sv
            and Group.sv.enabled
            and not ULT.uiObscured
        then
            Group:Refresh("group safety", true)
        end
    end)
end

function Group:SetEnabled(enabled)
    if not self.sv then return end
    self.sv.enabled = enabled == true
    self:Refresh("enabled", true)
    self:ApplyVisibility()
end

function Group:SetVisible(visible)
    if not self.sv then return end
    self.sv.visible = visible == true
    self:ApplyVisibility()
    self:RefreshIntegratedSettings()
end

function Group:SetLocked(locked)
    if not self.sv then return end
    locked = locked == true
    if locked and self.SavePosition then self:SavePosition() end
    self.sv.locked = locked
    self:UpdateLockState()
    self:RefreshIntegratedSettings()
end

function Group:Initialize()
    if self.initialized then return end
    self:EnsureSavedVariables()

    self:InitializeSharing()

    if self.CreateHUD then self:CreateHUD() end
    if self.CreateConfigWindow then self:CreateConfigWindow() end

    self:RegisterRosterEvents()
    self.initialized = true

    zo_callLater(function()
        if Group then Group:Refresh("initial", true) end
    end, 600)
end

function ULT:InitializeGroup()
    Group:Initialize()
end
