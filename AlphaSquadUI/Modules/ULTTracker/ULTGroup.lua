--[[
    Ąlpha Şquad UI - ULT Tracker / Group Tracking
    Author: @SeRuM1

    Group Ultimate data is received through LibGroupCombatStats when available.
    The personal ULT Tracker remains fully functional without that library.
]]

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}

local ULT = AlphaSquadUI.Modules.ULTTracker
if not ULT then return end

ULT.Group = ULT.Group or {}
local Group = ULT.Group

Group.version = (AlphaSquadUI and AlphaSquadUI.version) or "2.9.0"
Group.lgcs = nil
Group.libraryAvailable = false
Group.roster = {}
Group.byKey = {}
Group.byUnitTag = {}
Group.refreshPending = false
Group.previousUltValues = Group.previousUltValues or {}
Group.recentlyUsedUntil = Group.recentlyUsedUntil or {}
Group.initialized = false

local EM = AlphaSquadUI.Events and AlphaSquadUI.Events.NewScope and AlphaSquadUI.Events.NewScope() or EVENT_MANAGER
local MAX_TRACKED_ABILITIES = 24
local MAX_ABILITY_ID = 2147483647
local MAX_ULTIMATE_VALUE = 1000000

local function IsAbilityId(value)
    value = tonumber(value)
    return value and value > 0 and value <= MAX_ABILITY_ID and value % 1 == 0 and value or nil
end

local function FiniteOr(value, fallback)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return fallback end
    return value
end

local function BoundedSharedNumber(value)
    value = FiniteOr(value, nil)
    if not value or value < 0 or value > MAX_ULTIMATE_VALUE then return nil end
    return value
end

local function SharedAbilityId(value)
    value = FiniteOr(value, nil)
    if value == 0 then return 0 end
    return IsAbilityId(value)
end

local function NowMs()
    if GetGameTimeMilliseconds then return GetGameTimeMilliseconds() end
    return 0
end

local function UnitExists(unitTag)
    if not unitTag or unitTag == "" then return false end
    if DoesUnitExist then
        local ok, exists = pcall(DoesUnitExist, unitTag)
        if ok then return exists == true end
    end
    return true
end

local function UnitOnline(unitTag)
    if IsUnitOnline then
        local ok, online = pcall(IsUnitOnline, unitTag)
        if ok then return online == true end
    end
    return true
end

local function UnitDead(unitTag)
    if IsUnitDead then
        local ok, dead = pcall(IsUnitDead, unitTag)
        if ok then return dead == true end
    end
    return false
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
        enabled = true,
        locked = true,
        hideInMenus = true,
        scale = 100,
        hudWidth = 312,
        hudOrientation = "vertical",
        rowHeight = 36,
        opacity = 92,
        x = math.floor(rootW * 0.03),
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
        if ULT.sv.group[key] == nil or (type(value) == "boolean" and type(ULT.sv.group[key]) ~= "boolean") then
            ULT.sv.group[key] = value
        end
    end

    -- Cleanup migration from the retired per-player FRONT/BACK prototype.
    -- The current raidlead workflow stores only selected Ultimate ability IDs.
    ULT.sv.group.assignments = nil
    -- One user-facing switch owns group tracking and visibility. Preserve a
    -- previously hidden/off panel once, without retaining redundant preferences.
    if ULT.sv.group.singleSwitchVersion~=1 then
        if ULT.sv.group.visible==false then ULT.sv.group.enabled=false end
        ULT.sv.group.singleSwitchVersion=1
    end
    ULT.sv.group.visible=nil
    ULT.sv.group.includeSelf=nil
    ULT.sv.group.readySound=nil

    if type(ULT.sv.group.trackedAbilities) ~= "table" then
        ULT.sv.group.trackedAbilities = {}
    end
    local tracked, seen = {}, {}
    for abilityId, enabled in pairs(ULT.sv.group.trackedAbilities) do
        local numericId = IsAbilityId(abilityId)
        if enabled == true and numericId and not seen[numericId] then
            tracked[#tracked + 1] = numericId
            seen[numericId] = true
        end
    end
    table.sort(tracked)
    ULT.sv.group.trackedAbilities = {}
    for index = 1, math.min(MAX_TRACKED_ABILITIES, #tracked) do
        ULT.sv.group.trackedAbilities[tostring(tracked[index])] = true
    end

    -- Persistent per-account HUD geometry. Existing users keep their saved values.
    ULT.sv.group.scale = ULT.Clamp(FiniteOr(ULT.sv.group.scale, defaults.scale), 60, 180)
    if ULT.sv.group.hudOrientation~="horizontal" and ULT.sv.group.hudOrientation~="vertical" then ULT.sv.group.hudOrientation="vertical" end
    ULT.sv.group.hudWidth = ULT.Clamp(FiniteOr(ULT.sv.group.hudWidth, defaults.hudWidth), 240, 1800)
    if ULT.sv.group.hudHeight~=nil then
        ULT.sv.group.hudHeight=ULT.Clamp(FiniteOr(ULT.sv.group.hudHeight,90),52,1200)
    end
    ULT.sv.group.rowHeight = ULT.Clamp(FiniteOr(ULT.sv.group.rowHeight, defaults.rowHeight), 28, 56)
    ULT.sv.group.opacity = ULT.Clamp(FiniteOr(ULT.sv.group.opacity, defaults.opacity), 30, 100)
    ULT.sv.group.x = ULT.Clamp(FiniteOr(ULT.sv.group.x, defaults.x), -100000, 100000)
    ULT.sv.group.y = ULT.Clamp(FiniteOr(ULT.sv.group.y, defaults.y), -100000, 100000)
    self.sv = ULT.sv.group
end

function Group:IsAbilityTracked(abilityId)
    if not self.sv or type(self.sv.trackedAbilities) ~= "table" then return false end
    abilityId = tonumber(abilityId) or 0
    return abilityId > 0 and self.sv.trackedAbilities[tostring(abilityId)] == true
end

function Group:SetAbilityTracked(abilityId, tracked)
    if not self.sv then return end
    abilityId = IsAbilityId(abilityId)
    if not abilityId then return false end

    local key = tostring(abilityId)
    if tracked then
        if not self.sv.trackedAbilities[key] and self:GetTrackedAbilityCount() >= MAX_TRACKED_ABILITIES then return false end
        self.sv.trackedAbilities[key] = true
    else
        self.sv.trackedAbilities[key] = nil
    end

    self:Refresh("tracked ability changed")
    return true
end

function Group:GetAvailableAbilities()
    local abilitiesById = {}

    for abilityId, enabled in pairs(self.sv and self.sv.trackedAbilities or {}) do
        abilityId = tonumber(abilityId) or 0
        if enabled == true and abilityId > 0 then
            local name, icon = self:GetAbilityMeta(abilityId)
            abilitiesById[abilityId] = {id=abilityId, name=name, icon=icon, users=0, tracked=true}
        end
    end

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
                        tracked = self:IsAbilityTracked(abilityId),
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
        if a.tracked ~= b.tracked then return a.tracked == true end
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

local abilityMeta,abilityMetaCount={},0
function Group:GetAbilityMeta(abilityId)
    abilityId=IsAbilityId(abilityId)
    if not abilityId then return "No Ultimate", "", 0 end
    local cached=abilityMeta[abilityId]
    if cached then return cached.name,cached.icon,abilityId end
    local name,icon="",""
    if GetAbilityName then
        local ok,value=pcall(GetAbilityName,abilityId)
        if ok and type(value)=="string" then name=value end
    end
    if GetAbilityIcon then
        local ok,value=pcall(GetAbilityIcon,abilityId)
        if ok and type(value)=="string" then icon=value end
    end
    if name=="" then name="Unknown Ultimate" end
    name=zo_strformat("<<C:1>>",name)
    -- At most two slots per player plus saved filters; never grow with peer IDs.
    if abilityMetaCount>=128 then abilityMeta={};abilityMetaCount=0 end
    abilityMeta[abilityId]={name=name,icon=icon};abilityMetaCount=abilityMetaCount+1
    return name,icon,abilityId
end

function Group:InitializeSharing()
    self.libraryAvailable = false
    self.lgcs = nil

    if not LibGroupCombatStats or not LibGroupCombatStats.RegisterAddon then
        return false
    end

    local ok, result = pcall(function()
        return LibGroupCombatStats.RegisterAddon("AlphaSquadUIULTTracker", AlphaSquadUI.Sharing and {} or {"ULT"})
    end)

    if not ok or not result then
        return false
    end

    self.lgcs = result
    self.libraryAvailable = true
    if AlphaSquadUI.Sharing then AlphaSquadUI.Sharing.StartUltimateSender() end

    if result.RegisterForEvent then
        if LibGroupCombatStats.EVENT_GROUP_ULT_UPDATE then
            result:RegisterForEvent(LibGroupCombatStats.EVENT_GROUP_ULT_UPDATE, function(unitTag, data)
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

    if ok and type(ult) == "table" then return ult end
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

local function IsLocalPlayer(unitTag)
    if unitTag=="player" then return true end
    if AreUnitsEqual then
        local ok,same=pcall(AreUnitsEqual,unitTag,"player")
        if ok and same then return true end
    end
    local own=GetDisplayNameSafe("player")
    return own~="" and GetDisplayNameSafe(unitTag)==own
end

function Group:BuildRoster()
    local roster = {}
    local byKey = {}
    local byUnitTag = {}
    local groupSize = FiniteOr(GetGroupSize and GetGroupSize(), 0)
    groupSize = math.max(0, math.min(12, math.floor(groupSize)))

    if groupSize <= 0 then
        self.roster = roster
        self.byKey = byKey
        self.byUnitTag = byUnitTag
        self.previousUltValues = {}
        self.recentlyUsedUntil = {}
        return roster
    end

    for index = 1, groupSize do
        local unitTag = self:GetUnitTagByIndex(index)

        if unitTag and UnitExists(unitTag) and not IsLocalPlayer(unitTag) then
            local displayName = GetDisplayNameSafe(unitTag)
            local characterName = GetCharacterName(unitTag)
            local stableKey = displayName ~= "" and displayName or characterName
            if stableKey == "" then stableKey = unitTag end

            local ult = self:GetUltForUnit(unitTag)
            local ultValue = ult and BoundedSharedNumber(ult.ultValue) or nil
            local ult1ID = ult and SharedAbilityId(ult.ult1ID) or nil
            local ult2ID = ult and SharedAbilityId(ult.ult2ID) or nil
            local ult1Cost = ult and BoundedSharedNumber(ult.ult1Cost) or nil
            local ult2Cost = ult and BoundedSharedNumber(ult.ult2Cost) or nil

            local entry = {
                index = index,
                unitTag = unitTag,
                key = stableKey,
                displayName = displayName,
                characterName = characterName,
                isPlayer = false,
                shared = ultValue ~= nil,
                ultValue = ultValue or 0,
                ult1ID = ult1ID or 0,
                ult2ID = ult2ID or 0,
                ult1Cost = ult1Cost or 0,
                ult2Cost = ult2Cost or 0,
                lastUpdated = ult and FiniteOr(ult._lastUpdated, nil) or nil,
                connected = UnitOnline(unitTag),
                dead = UnitDead(unitTag),
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
    for key in pairs(self.previousUltValues) do
        if not byKey[key] or byKey[key].shared ~= true then self.previousUltValues[key] = nil end
    end
    for key in pairs(self.recentlyUsedUntil) do
        if not byKey[key] or byKey[key].shared ~= true then self.recentlyUsedUntil[key] = nil end
    end
    return roster
end

function Group:UpdateEntryFromUltData(unitTag, data)
    if type(unitTag)~="string" or unitTag=="" or IsLocalPlayer(unitTag) or type(data) ~= "table" then return false end

    local ultValue = BoundedSharedNumber(data.ultValue)
    if not ultValue then return false end

    local ult1ID = data.ult1ID ~= nil and SharedAbilityId(data.ult1ID) or nil
    local ult2ID = data.ult2ID ~= nil and SharedAbilityId(data.ult2ID) or nil
    local ult1Cost = data.ult1Cost ~= nil and BoundedSharedNumber(data.ult1Cost) or nil
    local ult2Cost = data.ult2Cost ~= nil and BoundedSharedNumber(data.ult2Cost) or nil
    if (data.ult1ID ~= nil and ult1ID == nil)
        or (data.ult2ID ~= nil and ult2ID == nil)
        or (data.ult1Cost ~= nil and ult1Cost == nil)
        or (data.ult2Cost ~= nil and ult2Cost == nil)
    then
        return false
    end

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

    -- A slot identity change cannot borrow the previous Ultimate's cost.
    if ult1ID~=nil and ult1ID~=entry.ult1ID and ult1Cost==nil then ult1Cost=0 end
    if ult2ID~=nil and ult2ID~=entry.ult2ID and ult2Cost==nil then ult2Cost=0 end
    entry.shared = true
    entry.ultValue = ultValue
    entry.ult1ID = ult1ID ~= nil and ult1ID or entry.ult1ID or 0
    entry.ult2ID = ult2ID ~= nil and ult2ID or entry.ult2ID or 0
    entry.ult1Cost = ult1Cost ~= nil and ult1Cost or entry.ult1Cost or 0
    entry.ult2Cost = ult2Cost ~= nil and ult2Cost or entry.ult2Cost or 0
    entry.lastUpdated = FiniteOr(data._lastUpdated, entry.lastUpdated)
    if IsUnitOnline then
        local ok,online=pcall(IsUnitOnline,unitTag)
        if ok then entry.connected=online==true end
    end
    if IsUnitDead then
        local ok,dead=pcall(IsUnitDead,unitTag)
        if ok then entry.dead=dead==true end
    end

    return true
end

function Group:BuildUltimate(entry, slot)
    if not entry then return nil end

    local isMain = slot == "main"
    local id = SharedAbilityId(isMain and entry.ult1ID or entry.ult2ID) or 0
    local cost = BoundedSharedNumber(isMain and entry.ult1Cost or entry.ult2Cost) or 0
    local value = BoundedSharedNumber(entry.ultValue) or 0
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
    if back and self:IsAbilityTracked(back.id) then
        if front and back.id==front.id then
            -- The same morph can have different costs on the two weapon bars.
            -- Keep one row, using the cheapest reported usable bar.
            if back.cost>0 and (front.cost<=0 or back.cost<front.cost) then matches[1]=back end
        else table.insert(matches,back) end
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
            percent = math.min(99, math.max(0, math.floor(((value / cost) * 100) + 0.5)))
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
        if not entry.isPlayer and entry.shared then
            entry.unavailable = entry.connected == false or entry.dead == true
            entry.matchingUltimates = self:GetMatchingUltimates(entry)

            if #entry.matchingUltimates > 0 then
                entry.anyReady = false
                for _, ultimate in ipairs(entry.matchingUltimates) do
                    if ultimate.ready and not entry.unavailable then
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

        -- Dead or disconnected players remain visible for context, but cannot be
        -- treated as actionable readiness.
        if a.unavailable ~= b.unavailable then return a.unavailable == false end

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

function Group:GetEmptyMessage()
    if #(self.roster or {})==0 then return "No teammates in this group" end
    if not self.libraryAvailable then return "Group data unavailable • See Libraries" end
    if self:GetTrackedAbilityCount()==0 then return "Choose Ultimates in Configure Group" end
    local shared=self:GetSharingCount()
    if shared==0 then return "No teammates sharing Ultimates" end
    return "No matching Ultimates shared"
end

function Group:GetSharingCount()
    local shared = 0
    for _, entry in ipairs(self.roster or {}) do
        if entry.shared then shared = shared + 1 end
    end
    return shared, #(self.roster or {})
end

function Group:CheckResourceTransitions()
    if not ULT.sv or not ULT.sv.enabled or not self.sv or not self.sv.enabled then return end

    local now = NowMs()

    for _, entry in ipairs(self.roster or {}) do
        if entry.shared then
            local value = tonumber(entry.ultValue) or 0
            local previousValue = self.previousUltValues[entry.key]
            local usable = entry.connected ~= false and entry.dead ~= true

            if usable and previousValue ~= nil and value < previousValue then
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

        end
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
    if ULT.loading or not self.sv then return end

    local configVisible = self.configWindow and not self.configWindow:IsHidden() or false
    local settings = AlphaSquadUI and AlphaSquadUI.Settings
    local mainSettingsVisible = settings and settings.mainWindow and not settings.mainWindow:IsHidden() or false

    if (not self.sv.enabled or not ULT.sv or not ULT.sv.enabled) and not configVisible and not mainSettingsVisible then
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
    if ULT.loading or not self.initialized or not self.sv then return end
    local tracking=self.sv.enabled and ULT.sv and ULT.sv.enabled
    local settings=AlphaSquadUI.Settings
    local inspecting=(self.configWindow and not self.configWindow:IsHidden())
        or (settings and settings.mainWindow and not settings.mainWindow:IsHidden())
    if not tracking and not inspecting then
        if self.ApplyVisibility then self:ApplyVisibility() end
        return
    end

    if rebuildRoster ~= false then
        self:BuildRoster()
    end

    if self.sv.enabled and ULT.sv and ULT.sv.enabled then
        self:CheckResourceTransitions()
        self:RefreshHUD()
    elseif self.ApplyVisibility then
        self:ApplyVisibility()
    end

    self:RefreshConfig()
    self:RefreshIntegratedSettings()
end

function Group:OnGroupUltUpdate(unitTag, data)
    if ULT.loading or type(unitTag)~="string" or unitTag=="" or IsLocalPlayer(unitTag) then return end
    if (not ULT.sv or not ULT.sv.enabled or not self.sv or not self.sv.enabled) and not (self.configWindow and not self.configWindow:IsHidden()) then return end
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
        if Group then Group:ScheduleRefresh(true) end
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

    -- The low-frequency fallback is registered dynamically by SetSafetyUpdateActive.
end

function Group:SetSafetyUpdateActive(enabled)
    enabled = enabled == true and not ULT.loading and not (AlphaSquadUI.Layout and AlphaSquadUI.Layout.IsMoving(self))
    if self.safetyUpdateActive == enabled then return end
    self.safetyUpdateActive = enabled
    local name = "AlphaSquadUI_ULTGroup_Safety"
    if enabled then
        EM:RegisterForUpdate(name, 2000, function()
            if Group and Group.initialized and ULT.sv and ULT.sv.enabled
                and Group.sv and Group.sv.enabled and not ULT.uiObscured then
                Group:Refresh("group safety", true)
            end
        end)
    else
        EM:UnregisterForUpdate(name)
    end
end

function Group:SetTrackingEventsActive()
    local active=not ULT.loading and ULT.sv and ULT.sv.enabled and self.sv and self.sv.enabled
    if EM.SetActive then EM:SetActive(active==true) end
end

function Group:SetEnabled(enabled)
    if not self.sv then return end
    self.sv.enabled = enabled == true
    self:SetTrackingEventsActive()
    self:SetSafetyUpdateActive(self.sv.enabled and ULT.sv and ULT.sv.enabled and not ULT.uiObscured)
    self:Refresh("enabled", true)
    self:ApplyVisibility()
end

-- Preserve old slash-command compatibility through the one tracking switch.
function Group:SetVisible(visible) self:SetEnabled(visible) end

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
    self.sv.locked = true
    if not self.sv.positionSaved then
        local defaults = self:GetDefaults()
        self.sv.x, self.sv.y = defaults.x, defaults.y
    end

    self:InitializeSharing()

    if self.CreateHUD then self:CreateHUD() end
    if self.CreateConfigWindow then self:CreateConfigWindow() end

    self:RegisterRosterEvents()
    self:SetTrackingEventsActive()
    self.initialized = true
    self:SetSafetyUpdateActive(self.sv.enabled and ULT.sv and ULT.sv.enabled and not ULT.uiObscured)

    zo_callLater(function()
        if Group then Group:Refresh("initial", true) end
    end, 600)
end

function ULT:InitializeGroup()
    Group:Initialize()
end
