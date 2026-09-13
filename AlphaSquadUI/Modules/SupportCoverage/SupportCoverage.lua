--[[
    Ąlpha Şquad UI - Support Coverage
    Raidlead support planning, capability scanning and live coverage.
    Author: SeRuM1
]]

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}

local SC = AlphaSquadUI.Modules.SupportCoverage or {}
AlphaSquadUI.Modules.SupportCoverage = SC

SC.name = "SupportCoverage"
SC.displayName = "Support Coverage"
SC.version = (AlphaSquadUI and AlphaSquadUI.version) or "2.7.0-support-coverage-test.4"
SC.savedVarsName = "AlphaSquadSupportCoverageSavedVariables"
SC.catalogPatch = "U50"
SC.initialized = false
SC.uiObscured = false
SC.inCombat = false
SC.localSnapshot = nil
SC.roster = SC.roster or {}
SC.byKey = SC.byKey or {}
SC.peerData = SC.peerData or {}
SC.coverage = SC.coverage or {}
SC.liveState = SC.liveState or {}
SC.pull = SC.pull or nil
SC.scanDirty = true
SC.refreshPending = false
SC.lastSafetyAt = 0

local VALID_PROFILES = {full=true, progression=true, damage=true, trash=true, boss=true, custom=true}
local VALID_ROLES = {UNKNOWN=true, MT=true, OT=true, HEAL=true, ["DD PARSE"]=true, ["DD SUPPORT"]=true, ["MT/OT"]=true, H1=true, H2=true}
local MAX_CONTEXT_PROFILES = 12
local MAX_CONTEXT_TEMPLATES = 32
local MAX_CUSTOM_IDS_PER_EFFECT = 16
local MAX_PLAYER_SETTINGS = 64
local MAX_BACKUPS_PER_EFFECT = 12

local EM = EVENT_MANAGER

local function NowMs()
    if GetGameTimeMilliseconds then return GetGameTimeMilliseconds() end
    return 0
end

SC.NowMs = NowMs

local function Clamp(value, minimum, maximum)
    if AlphaSquadUI.Utils and AlphaSquadUI.Utils.Clamp then
        return AlphaSquadUI.Utils.Clamp(value, minimum, maximum)
    end
    value = tonumber(value) or minimum
    if value ~= value or value == math.huge or value == -math.huge then value = minimum end
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

SC.Clamp = Clamp

local function FiniteOr(value, fallback)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return fallback end
    return value
end

function SC:GetDefaultPosition()
    local width = GuiRoot and GuiRoot:GetWidth() or 1920
    local height = GuiRoot and GuiRoot:GetHeight() or 1080
    return math.floor(width * 0.70), math.floor(height * 0.16)
end

function SC:GetDefaults()
    local x, y = self:GetDefaultPosition()
    return {
        enabled = true,
        visible = true,
        locked = false,
        hideInMenus = true,
        problemsOnly = true,
        autoAssign = true,
        shareData = true,
        showUnknown = true,
        showReadyBanner = true,
        optionalSounds = false,
        scale = 100,
        opacity = 94,
        width = 410,
        rowHeight = 30,
        x = x,
        y = y,
        positionSaved = false,
        activeProfile = "full",
        roleOverrides = {},
        assignmentLocks = {},
        duplicateBackups = {},
        manualCapabilities = {},
        customRequirements = {},
        customCatalog = {},
        profileOverrides = {},
        contextProfiles = {},
    }
end

function SC:EnsureSavedVariables()
    local defaults = self:GetDefaults()
    local worldNamespace = GetWorldName and GetWorldName() or nil
    self.sv = ZO_SavedVars:NewAccountWide(self.savedVarsName, 1, worldNamespace, defaults)

    for key, value in pairs(defaults) do
        if self.sv[key] == nil then
            self.sv[key] = value
        elseif type(value) == "boolean" and type(self.sv[key]) ~= "boolean" then
            self.sv[key] = value
        end
    end

    self.sv.scale = Clamp(FiniteOr(self.sv.scale, defaults.scale), 60, 180)
    self.sv.opacity = Clamp(FiniteOr(self.sv.opacity, defaults.opacity), 30, 100)
    self.sv.width = Clamp(FiniteOr(self.sv.width, defaults.width), 300, 680)
    self.sv.rowHeight = Clamp(FiniteOr(self.sv.rowHeight, defaults.rowHeight), 24, 48)
    self.sv.x = Clamp(FiniteOr(self.sv.x, defaults.x), -100000, 100000)
    self.sv.y = Clamp(FiniteOr(self.sv.y, defaults.y), -100000, 100000)
    if not VALID_PROFILES[self.sv.activeProfile] then self.sv.activeProfile = "full" end
    if self.EnsureAuditSettings then self:EnsureAuditSettings() end

    self:SanitizePlanningSettings()
end

local function ValidPlayerKey(value)
    return type(value) == "string" and value ~= "" and #value <= 192
end

local function TrimSortedKeys(values, maximum)
    local keys = {}
    for key in pairs(values or {}) do keys[#keys + 1] = key end
    table.sort(keys)
    for index = maximum + 1, #keys do values[keys[index]] = nil end
end

function SC:SanitizePlanningSettings()
    if not self.sv then return end

    local tableKeys = {
        "roleOverrides", "assignmentLocks", "duplicateBackups", "manualCapabilities",
        "customRequirements", "customCatalog", "profileOverrides", "contextProfiles",
    }
    for _, key in ipairs(tableKeys) do
        if type(self.sv[key]) ~= "table" then self.sv[key] = {} end
    end

    for playerKey, role in pairs(self.sv.roleOverrides) do
        if not ValidPlayerKey(playerKey) or not VALID_ROLES[role] then self.sv.roleOverrides[playerKey] = nil end
    end
    TrimSortedKeys(self.sv.roleOverrides, MAX_PLAYER_SETTINGS)
    for effectKey, playerKey in pairs(self.sv.assignmentLocks) do
        if not self.Catalog.effects[effectKey] or not ValidPlayerKey(playerKey) then self.sv.assignmentLocks[effectKey] = nil end
    end
    for effectKey, players in pairs(self.sv.duplicateBackups) do
        if not self.Catalog.effects[effectKey] or type(players) ~= "table" then
            self.sv.duplicateBackups[effectKey] = nil
        else
            for playerKey, enabled in pairs(players) do
                if not ValidPlayerKey(playerKey) or enabled ~= true then players[playerKey] = nil end
            end
            TrimSortedKeys(players, MAX_BACKUPS_PER_EFFECT)
        end
    end
    for playerKey, capabilities in pairs(self.sv.manualCapabilities) do
        if not ValidPlayerKey(playerKey) or type(capabilities) ~= "table" then
            self.sv.manualCapabilities[playerKey] = nil
        else
            for effectKey, enabled in pairs(capabilities) do
                if not self.Catalog.effects[effectKey] or type(enabled) ~= "boolean" then capabilities[effectKey] = nil end
            end
        end
    end
    TrimSortedKeys(self.sv.manualCapabilities, MAX_PLAYER_SETTINGS)
    for effectKey, enabled in pairs(self.sv.customRequirements) do
        if not self.Catalog.effects[effectKey] or enabled ~= true then self.sv.customRequirements[effectKey] = nil end
    end
    for profileKey, overrides in pairs(self.sv.profileOverrides) do
        if not VALID_PROFILES[profileKey] or type(overrides) ~= "table" then
            self.sv.profileOverrides[profileKey] = nil
        else
            for effectKey, enabled in pairs(overrides) do
                if not self.Catalog.effects[effectKey] or type(enabled) ~= "boolean" then overrides[effectKey] = nil end
            end
        end
    end

    local customIds = {}
    for effectKey in pairs(self.sv.customCatalog) do customIds[#customIds + 1] = effectKey end
    table.sort(customIds)
    local claimed = {}
    for _, effectKey in ipairs(customIds) do
        local ids = self.sv.customCatalog[effectKey]
        if not self.Catalog.effects[effectKey] or type(ids) ~= "table" then
            self.sv.customCatalog[effectKey] = nil
        else
            local valid = {}
            for rawId, enabled in pairs(ids) do
                local id = tonumber(rawId)
                if enabled == true and id and id > 0 and id <= 2147483647 and id % 1 == 0 and not claimed[id] then
                    valid[#valid + 1] = id
                end
            end
            table.sort(valid)
            self.sv.customCatalog[effectKey] = {}
            for index = 1, math.min(MAX_CUSTOM_IDS_PER_EFFECT, #valid) do
                local id = valid[index]
                claimed[id] = effectKey
                self.sv.customCatalog[effectKey][tostring(id)] = true
            end
        end
    end

    local contexts = {}
    for name, profile in pairs(self.sv.contextProfiles) do
        if type(name) == "string" and name ~= "" and #name <= 96 and type(profile) == "table" then
            profile.savedAt = self.Clamp(profile.savedAt or 0, 0, 4294967295)
            contexts[#contexts + 1] = {name=name, savedAt=profile.savedAt}
        else
            self.sv.contextProfiles[name] = nil
        end
    end
    table.sort(contexts, function(a, b)
        if a.savedAt ~= b.savedAt then return a.savedAt > b.savedAt end
        return a.name < b.name
    end)
    for index = MAX_CONTEXT_PROFILES + 1, #contexts do self.sv.contextProfiles[contexts[index].name] = nil end
end

function SC:IsGrouped()
    if IsUnitGrouped then
        local ok, grouped = pcall(IsUnitGrouped, "player")
        if ok and grouped == true then return true end
    end
    return FiniteOr(GetGroupSize and GetGroupSize(), 0) > 0
end

function SC:GetPlayerKey(unitTag)
    local displayName = GetUnitDisplayName and GetUnitDisplayName(unitTag) or ""
    if displayName and displayName ~= "" then return displayName end
    local characterName = GetUnitName and GetUnitName(unitTag) or ""
    if characterName and characterName ~= "" then return characterName end
    return tostring(unitTag or "unknown")
end

function SC:MarkScanDirty(reason)
    self.scanDirty = true
    if not self.sv or not self.sv.enabled then return end
    self:ScheduleRefresh(reason or "dirty", 80)
end

function SC:ScheduleRefresh(reason, delay)
    if not self.initialized then return end
    if not self.sv or not self.sv.enabled then
        if self.CheckGroupSession then self:CheckGroupSession() end
        return
    end
    if self.refreshPending then return end
    self.refreshPending = true
    zo_callLater(function()
        if not SC then return end
        SC.refreshPending = false
        SC:Refresh(reason or "scheduled")
    end, tonumber(delay) or 50)
end

function SC:Refresh(reason)
    if not self.initialized or not self.sv then return end
    if self.CheckGroupSession then self:CheckGroupSession() end
    if not self.sv.enabled then return end
    -- EVENT_PLAYER_COMBAT_STATE may have fired while the player was solo. If a
    -- group forms during that same combat, the roster event's refresh must start
    -- collection instead of waiting for a combat-state transition that will not
    -- happen again.
    if not self.inCombat and self:IsGrouped() and self.Try
        and self.Try(IsUnitInCombat,"player") == true then
        self:OnCombatState(true)
        if self.inCombat then return end
    end

    local shareReason
    if self.scanDirty and self.ScanLocalPlayer then
        self.localSnapshot = self:ScanLocalPlayer()
        self.scanDirty = false
        shareReason = "scan"
    end

    local readinessChanged = self.RefreshReadinessFacts and self:RefreshReadinessFacts()
    if readinessChanged then shareReason = shareReason or "readiness changed" end
    if shareReason and self.inCombat then
        self.buildSharePending = true
    elseif not self.inCombat and (shareReason or self.buildSharePending) and self.ShareLocalSnapshot then
        local sent=self:ShareLocalSnapshot(shareReason or "deferred build/readiness")
        local retryable=self.sv.experimentalSharing==true and self.sv.shareData==true and self:IsGrouped()
            and self.share and self.share.available==true and self.share.protocol~=nil
        if retryable and self.share.protocol.IsEnabled then
            local ok,enabled=pcall(self.share.protocol.IsEnabled,self.share.protocol)
            retryable=ok and enabled==true
        end
        self.buildSharePending=retryable==true and sent~=true
    end
    if self.sv.autoContextProfile and not self.inCombat then
        local context=self:GetContextKey()
        if context~=self.lastAutoContext then
            self.lastAutoContext=context
            if self.sv.contextProfiles[context] then self:LoadContextProfile(context); return end
        end
    end
    if self.buildPlan then self.buildPlan.stale=true end
    if self.BuildRoster then self:BuildRoster() end
    if self.EvaluateCoverage then self:EvaluateCoverage(reason) end
    if self.MaybeBroadcastPlan then self:MaybeBroadcastPlan() end
    if not self.inCombat and self.share then
        if self.NowMs()-(self.share.lastSendAt or 0)>60000 then self:ShareLocalSnapshot("heartbeat") end
        if self.QueueBuildDetails then
            local sent=self:QueueBuildDetails(self.detailSharePending==true)
            if sent then self.detailSharePending=false end
        end
    end
    if self.RefreshHUD then self:RefreshHUD() end
    if self.RefreshSettings then self:RefreshSettings() end
end

function SC:SetEnabled(enabled)
    self.sv.enabled = enabled == true
    if not self.sv.enabled then
        self.combatEndGeneration = (self.combatEndGeneration or 0) + 1
        if self.pull then self:FinalizePull() end
        self.inCombat = false
        if self.SetLiveUpdateActive then self:SetLiveUpdateActive(false) end
        if self.reportWindow then self.reportWindow:SetHidden(true) end
        if self.ResetSharingState then self:ResetSharingState("Module disabled") end
    elseif self.Try and self.Try(IsUnitInCombat, "player") == true then
        self:OnCombatState(true)
    elseif self.InitializeSharing then
        self:InitializeSharing()
    end
    self:SetSafetyUpdateActive(self.sv.enabled and not self.uiObscured)
    if self.ApplyVisibility then self:ApplyVisibility() end
    if self.sv.enabled then self:Refresh("enabled") end
end

function SC:SetShareData(enabled)
    self.sv.shareData = enabled == true
    if self.sv.shareData then
        if self.InitializeSharing then self:InitializeSharing() end
        if self.ShareLocalSnapshot then self:ShareLocalSnapshot("sharing enabled") end
    elseif self.ResetSharingState then
        self:ResetSharingState("Sharing disabled")
    end
    self:Refresh("sharing")
end

function SC:SetExperimentalSharing(enabled)
    self.sv.experimentalSharing = enabled == true
    if self.sv.experimentalSharing then
        if self.InitializeSharing then self:InitializeSharing() end
        if self.ShareLocalSnapshot then self:ShareLocalSnapshot("test sharing enabled") end
    elseif self.ResetSharingState then
        self:ResetSharingState("Experimental sharing disabled")
    end
    self:Refresh("experimental sharing")
end

function SC:ResetSharingState(reason)
    self.peerData, self.remotePlan, self.detailReceivers = {}, nil, {}
    self.lastPlanSignature = nil
    self.buildSharePending = false
    self.detailSharePending = false
    if self.share then
        self.share.detailTransfer = nil
        self.share.lastDetailText = nil
        self.share.lastDetailAt = -60000
        self.share.lastSendAt = -60000
        self.share.lastBuildFingerprint = nil
        self.share.lastLiveSendAt = -60000
        self.share.lastPlanAttemptAt = -60000
        self.share.lastPlanSentAt = -300000
        self.share.lastPotionAt = -60000
        self.share.lastPotionText = nil
        self.share.lastPullIdentityAt = -60000
        self.share.lastPullIdentityText = nil
        self.share.planPending = false
        self.share.lastResetReason = reason
    end
end

function SC:SetVisible(visible)
    self.sv.visible = visible == true
    if self.ApplyVisibility then self:ApplyVisibility() end
    if self.sv.visible and self.sv.enabled then self:Refresh("visibility changed") end
end

function SC:SetLocked(locked)
    locked = locked == true
    if locked and self.SavePosition then self:SavePosition() end
    self.sv.locked = locked
    if self.UpdateLockState then self:UpdateLockState() end
    if self.RefreshSettings then self:RefreshSettings() end
end

function SC:SetActiveProfile(profileKey)
    if not VALID_PROFILES[profileKey] or not self.Catalog:GetProfile(profileKey) then return false end
    self.sv.activeProfile = profileKey
    self:Refresh("profile")
    if self.SchedulePlanBroadcast then self:SchedulePlanBroadcast() end
    return true
end

function SC:GetContextKey()
    if self.GetEncounterMetadata then return self:GetEncounterMetadata().key end
    return "Unknown context"
end

local function ShallowCopy(source)
    if type(source) ~= "table" then return {} end
    local result = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            result[key] = ShallowCopy(value)
        else
            result[key] = value
        end
    end
    return result
end

local function HasPrefix(value, prefix)
    return type(value) == "string" and value:sub(1, #prefix) == prefix
end

-- Contexts restore only the selected profile's expected builds. Keeping every
-- profile in every context duplicated SavedVariables and allowed an old boss
-- context to erase templates captured later for damage, trash, or progression.
local function CopyContextTemplates(profileKey, buildTemplates, playerTemplates)
    local prefix = tostring(profileKey) .. ":"
    local copied, mappings, included = {}, {}, {}

    local roleKeys = {}
    for role in pairs(VALID_ROLES) do
        local key = prefix .. role
        if type(buildTemplates[key]) == "table" then roleKeys[#roleKeys + 1] = key end
    end
    table.sort(roleKeys)
    local count = 0
    for _, key in ipairs(roleKeys) do
        if count >= MAX_CONTEXT_TEMPLATES then break end
        copied[key], included[key] = ShallowCopy(buildTemplates[key]), true
        count = count + 1
    end

    local candidates = {}
    for playerKey, templateKey in pairs(playerTemplates) do
        local template = buildTemplates[templateKey]
        if HasPrefix(playerKey, prefix) and HasPrefix(templateKey, prefix) and type(template) == "table" then
            candidates[#candidates + 1] = {
                playerKey = playerKey,
                templateKey = templateKey,
                createdAt = FiniteOr(template.createdAt, 0),
            }
        end
    end
    table.sort(candidates, function(a, b)
        if a.createdAt ~= b.createdAt then return a.createdAt > b.createdAt end
        return a.playerKey < b.playerKey
    end)
    for _, entry in ipairs(candidates) do
        if included[entry.templateKey] or count < MAX_CONTEXT_TEMPLATES then
            if not included[entry.templateKey] then
                copied[entry.templateKey] = ShallowCopy(buildTemplates[entry.templateKey])
                included[entry.templateKey] = true
                count = count + 1
            end
            mappings[entry.playerKey] = entry.templateKey
        end
    end
    return copied, mappings
end

local function ReplaceProfileTemplates(sv, profileKey, buildTemplates, playerTemplates)
    local prefix = tostring(profileKey) .. ":"
    for key in pairs(sv.buildTemplates) do
        if HasPrefix(key, prefix) then sv.buildTemplates[key] = nil end
    end
    for playerKey in pairs(sv.playerTemplates) do
        if HasPrefix(playerKey, prefix) then sv.playerTemplates[playerKey] = nil end
    end
    for key, template in pairs(buildTemplates or {}) do
        if HasPrefix(key, prefix) and type(template) == "table" then
            sv.buildTemplates[key] = ShallowCopy(template)
        end
    end
    for playerKey, templateKey in pairs(playerTemplates or {}) do
        if HasPrefix(playerKey, prefix) and HasPrefix(templateKey, prefix)
            and type(sv.buildTemplates[templateKey]) == "table" then
            sv.playerTemplates[playerKey] = templateKey
        end
    end
end

function SC:SaveContextProfile(name)
    name = tostring(name or self:GetContextKey()):match("^%s*(.-)%s*$"):sub(1, 96)
    if name == "" then return nil end
    if self.EnsureAuditSettings then self:EnsureAuditSettings() end
    self:SanitizePlanningSettings()
    local profileKey = self.sv.activeProfile
    local buildTemplates, playerTemplates = CopyContextTemplates(
        profileKey, self.sv.buildTemplates, self.sv.playerTemplates)
    local profileOverrides = {}
    if type(self.sv.profileOverrides[profileKey]) == "table" then
        profileOverrides[profileKey] = ShallowCopy(self.sv.profileOverrides[profileKey])
    end
    self.sv.contextProfiles[name] = {
        activeProfile = profileKey,
        checkModes = ShallowCopy(self.sv.checkModes),
        championScope=self.sv.championScope,
        minimumMeasuredPercent=self.sv.minimumMeasuredPercent,
        effectRules = ShallowCopy(self.sv.effectRules),
        buildTemplates = buildTemplates,
        playerTemplates = playerTemplates,
        profileOverrides = profileOverrides,
        assignmentLocks = ShallowCopy(self.sv.assignmentLocks),
        duplicateBackups = ShallowCopy(self.sv.duplicateBackups),
        roleOverrides = ShallowCopy(self.sv.roleOverrides),
        savedAt = (self.Try and self.Try(GetTimeStamp)) or 0,
    }
    local names = {}
    for key, profile in pairs(self.sv.contextProfiles) do
        if type(key) == "string" and type(profile) == "table" then names[#names + 1] = key
        else self.sv.contextProfiles[key] = nil end
    end
    table.sort(names, function(a, b)
        local aTime = self.Clamp(self.sv.contextProfiles[a].savedAt or 0,0,4294967295)
        local bTime = self.Clamp(self.sv.contextProfiles[b].savedAt or 0,0,4294967295)
        if aTime ~= bTime then return aTime < bTime end
        return a < b
    end)
    local stored = #names
    for _, oldest in ipairs(names) do
        if stored <= MAX_CONTEXT_PROFILES then break end
        if oldest ~= name then
            self.sv.contextProfiles[oldest] = nil
            stored = stored - 1
        end
    end
    self.lastContextProfile = name
    return name
end

function SC:LoadContextProfile(name)
    name = tostring(name or self:GetContextKey()):match("^%s*(.-)%s*$"):sub(1, 96)
    local profile = self.sv.contextProfiles[name]
    if type(profile) ~= "table" then return false end

    local profileKey = VALID_PROFILES[profile.activeProfile] and profile.activeProfile or self.sv.activeProfile
    self.sv.activeProfile = profileKey
    self.sv.championScope=profile.championScope or self.sv.championScope
    self.sv.minimumMeasuredPercent=profile.minimumMeasuredPercent or self.sv.minimumMeasuredPercent
    for _,key in ipairs({"checkModes","effectRules"}) do
        if type(profile[key])=="table" then self.sv[key]=ShallowCopy(profile[key]) end
    end
    if type(profile.buildTemplates) == "table" then
        ReplaceProfileTemplates(self.sv, profileKey, profile.buildTemplates,
            type(profile.playerTemplates) == "table" and profile.playerTemplates or {})
    end
    self.sv.profileOverrides[profileKey] = type(profile.profileOverrides) == "table"
        and ShallowCopy(profile.profileOverrides[profileKey] or {}) or {}
    self.sv.assignmentLocks = ShallowCopy(profile.assignmentLocks or {})
    self.sv.duplicateBackups = ShallowCopy(profile.duplicateBackups or {})
    self.sv.roleOverrides = ShallowCopy(profile.roleOverrides or {})
    if self.EnsureAuditSettings then self:EnsureAuditSettings() end
    self:SanitizePlanningSettings()
    self.lastContextProfile = name
    self:Refresh("context profile")
    if self.SchedulePlanBroadcast then self:SchedulePlanBroadcast() end
    return true
end

function SC:AddCustomEffectId(effectKey, abilityId)
    effectKey = tostring(effectKey or "")
    abilityId = tonumber(abilityId)
    if not abilityId or abilityId <= 0 or abilityId > 2147483647 or abilityId % 1 ~= 0 then return false end
    if not self.Catalog or not self.Catalog.effects[effectKey] then return false end

    abilityId = math.floor(abilityId)
    if self.effectIdIndex and self.effectIdIndex[abilityId] and self.effectIdIndex[abilityId] ~= effectKey then return false end
    for otherKey, ids in pairs(self.sv.customCatalog) do
        if otherKey ~= effectKey and type(ids) == "table" and ids[tostring(abilityId)] == true then return false end
    end
    self.sv.customCatalog[effectKey] = self.sv.customCatalog[effectKey] or {}
    local count = 0
    for _ in pairs(self.sv.customCatalog[effectKey]) do count = count + 1 end
    if not self.sv.customCatalog[effectKey][tostring(abilityId)] and count >= MAX_CUSTOM_IDS_PER_EFFECT then return false end
    self.sv.customCatalog[effectKey][tostring(abilityId)] = true
    if self.RebuildEffectIndex then self:RebuildEffectIndex() end
    return true
end

function SC:OnCombatState(inCombat)
    if not self.sv or not self.sv.enabled then return end
    self.combatEndGeneration = (self.combatEndGeneration or 0) + 1
    local generation = self.combatEndGeneration
    if inCombat then
        if self.inCombat then return end
        -- Support pull analytics are group-only; solo combat must not start the
        -- live sampling update or create history that will later be discarded.
        if not self:IsGrouped() then return end
        self.inCombat = true
        self:StartPull()
        self:HideReadyBanner()
        self:SetLiveUpdateActive(true)
        self:Refresh("combat start")
        self:SampleLiveCoverage()
        return
    end
    if not self.inCombat then return end
    local function FinishWhenQuiet()
        if generation ~= SC.combatEndGeneration or not SC.inCombat then return end
        local fighting = SC.Try(IsUnitInCombat, "player") == true
        local groupSize=tonumber(SC.Try(GetGroupSize)) or 0
        if groupSize~=groupSize or groupSize==math.huge or groupSize==-math.huge then groupSize=0 end
        for index = 1, math.min(12, math.max(0, math.floor(groupSize))) do
            local tag = SC.Try(GetGroupUnitTagByIndex, index) or ("group" .. index)
            if SC:IsOnline(tag) ~= false and SC.Try(IsUnitInCombat, tag) == true then fighting = true end
        end
        if fighting then zo_callLater(FinishWhenQuiet, 1500); return end
        SC.inCombat = false
        SC:FinalizePull()
        SC:Refresh("combat end")
    end
    zo_callLater(FinishWhenQuiet, 1500)
end

function SC:RegisterEvents()
    local prefix = "AlphaSquadUI_SupportCoverage"

    local function Dirty()
        if SC then SC:MarkScanDirty("equipment or build") end
    end

    if EVENT_INVENTORY_SINGLE_SLOT_UPDATE then
        EM:RegisterForEvent(prefix .. "_Inventory", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(_, bagId)
            if bagId == BAG_WORN then Dirty() end
        end)
    end

    if EVENT_ACTION_SLOT_UPDATED then
        EM:RegisterForEvent(prefix .. "_ActionSlot", EVENT_ACTION_SLOT_UPDATED, function()
            zo_callLater(Dirty, 50)
        end)
    end

    if EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED then
        EM:RegisterForEvent(prefix .. "_AllBars", EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED, function()
            zo_callLater(Dirty, 50)
        end)
    end

    if EVENT_ACTIVE_WEAPON_PAIR_CHANGED then
        EM:RegisterForEvent(prefix .. "_WeaponPair", EVENT_ACTIVE_WEAPON_PAIR_CHANGED, function()
            zo_callLater(Dirty, 50)
        end)
    end

    if EVENT_PLAYER_ACTIVATED then
        EM:RegisterForEvent(prefix .. "_Activated", EVENT_PLAYER_ACTIVATED, function()
            zo_callLater(function()
                if SC then
                    SC.groupSessionReady = true
                    SC:CheckGroupSession()
                    SC:RefreshUIObscured()
                    SC:MarkScanDirty("activated")
                    if SC.Try(IsUnitInCombat, "player") == true then SC:OnCombatState(true) end
                end
            end, 350)
        end)
    end

    if EVENT_GROUP_MEMBER_JOINED then
        EM:RegisterForEvent(prefix .. "_Joined", EVENT_GROUP_MEMBER_JOINED, function()
            if SC.sv.enabled and SC.sv.shareData and SC.sv.experimentalSharing then
                -- A new peer has not seen the otherwise deduplicated summary or
                -- signature frame. Queue one pair after the roster has settled.
                SC.buildSharePending = true
                SC.detailSharePending = true
            end
            SC:ScheduleRefresh("group joined", 150)
        end)
    end
    if EVENT_GROUP_MEMBER_LEFT then
        EM:RegisterForEvent(prefix .. "_Left", EVENT_GROUP_MEMBER_LEFT, function()
            SC:ScheduleRefresh("group left", 100)
        end)
    end
    if EVENT_GROUP_UPDATE then
        EM:RegisterForEvent(prefix .. "_Group", EVENT_GROUP_UPDATE, function()
            SC:ScheduleRefresh("group update", 100)
        end)
    end
    if EVENT_GROUP_MEMBER_CONNECTED_STATUS then
        EM:RegisterForEvent(prefix .. "_Connected", EVENT_GROUP_MEMBER_CONNECTED_STATUS, function(_, _, isOnline)
            if isOnline == true and SC.sv.enabled and SC.sv.shareData and SC.sv.experimentalSharing then
                SC.buildSharePending = true
                SC.detailSharePending = true
            end
            SC:ScheduleRefresh("group connected", 100)
        end)
    end

    if EVENT_PLAYER_COMBAT_STATE then
        EM:RegisterForEvent(prefix .. "_Combat", EVENT_PLAYER_COMBAT_STATE, function(_, inCombat)
            SC:OnCombatState(inCombat)
        end)
    end

    if EVENT_EFFECT_CHANGED then
        local effectEvent = prefix .. "_LocalEffects"
        EM:RegisterForEvent(effectEvent, EVENT_EFFECT_CHANGED, function(_, _, _, _, unitTag)
            if unitTag == "player" then SC:ScheduleObservation() end
        end)
        if REGISTER_FILTER_UNIT_TAG then EM:AddFilterForEvent(effectEvent, EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, "player") end
    end
    if EVENT_INVENTORY_ITEM_USED then
        EM:RegisterForEvent(prefix .. "_ConsumableUsed", EVENT_INVENTORY_ITEM_USED, function(_, soundCategory)
            if SC.sv.enabled then SC:OnConsumableUsed(soundCategory) end
        end)
    end
    -- Only committed build changes invalidate the heavier scanner.
    for _, definition in ipairs({
        {"Champion", EVENT_CHAMPION_PURCHASE_RESULT}, {"SkillPoints", EVENT_SKILL_POINTS_CHANGED},
        {"SkillLines", EVENT_SKILL_LINE_ADDED}, {"SkillsFull", EVENT_SKILLS_FULL_UPDATE},
        {"SkillBuild", EVENT_SKILL_BUILD_SELECTION_UPDATED}, {"SkillRespec", EVENT_SKILL_RESPEC_RESULT},
        {"ArmoryChampion", EVENT_ARMORY_BUILD_CHAMPION_SLOTS_MODIFIED},
    }) do
        if definition[2] then EM:RegisterForEvent(prefix .. "_" .. definition[1], definition[2], Dirty) end
    end
    if EVENT_ACTIVE_QUICKSLOT_CHANGED then
        EM:RegisterForEvent(prefix .. "_Quickslot", EVENT_ACTIVE_QUICKSLOT_CHANGED, function()
            if SC.sv.enabled then SC:ScheduleRefresh("quickslot changed", 80) end
        end)
    end

    if EVENT_SCREEN_RESIZED then
        EM:RegisterForEvent(prefix .. "_Screen", EVENT_SCREEN_RESIZED, function()
            zo_callLater(function()
                if SC and SC.ApplyAppearance then
                    SC:ApplyAppearance()
                    SC:ClampToScreen(true)
                    SC:RefreshHUD()
                    if SC.ResizeInspector then SC:ResizeInspector() end
                end
            end, 50)
        end)
    end

    -- Slow recovery sync. Heavy scans only run when scanDirty is set.
    -- The slow recovery sync is registered dynamically while this module is active.
end

function SC:SetSafetyUpdateActive(enabled)
    enabled = enabled == true
    if self.safetyUpdateActive == enabled then return end
    self.safetyUpdateActive = enabled
    local name = "AlphaSquadUI_SupportCoverage_Safety"
    if enabled then
        EM:RegisterForUpdate(name, 2500, function()
            if not SC or not SC.sv or not SC.sv.enabled then return end
            SC:CheckGroupSession()
            local overlayVisible = SC.inspectorWindow and not SC.inspectorWindow:IsHidden()
                or SC.reportWindow and not SC.reportWindow:IsHidden()
                or SC.matrixWindow and not SC.matrixWindow:IsHidden()
            if SC.uiObscured and not (SC.settingsPageVisible or overlayVisible) then return end
            SC:Refresh("safety")
        end)
    else
        EM:UnregisterForUpdate(name)
    end
end

local function SceneVisible(scene)
    if not scene or not scene.GetState then return false end
    local state = scene:GetState()
    return state == SCENE_SHOWING or state == SCENE_SHOWN
end

function SC:RefreshUIObscured()
    self.uiObscured = not (SceneVisible(HUD_SCENE) or SceneVisible(HUD_UI_SCENE))
    self:SetSafetyUpdateActive(self.sv and self.sv.enabled and (not self.uiObscured or self.settingsPageVisible))
    if self.ApplyVisibility then self:ApplyVisibility() end
end

function SC:RegisterSceneCallbacks()
    local function Changed()
        zo_callLater(function() if SC then SC:RefreshUIObscured() end end, 0)
    end
    if HUD_SCENE and HUD_SCENE.RegisterCallback then HUD_SCENE:RegisterCallback("StateChange", Changed) end
    if HUD_UI_SCENE and HUD_UI_SCENE.RegisterCallback then HUD_UI_SCENE:RegisterCallback("StateChange", Changed) end
end

function SC:RegisterSlashCommands()
    SLASH_COMMANDS["/assupport"] = function(argument)
        local arg = tostring(argument or ""):match("^%s*(.-)%s*$") or ""
        local lower = string.lower(arg)

        if lower == "" or lower == "settings" then
            local settings = AlphaSquadUI and AlphaSquadUI.Settings
            if settings and settings.OpenPage then settings.OpenPage("supportcoverage") end
            if SC.ApplyVisibility then SC:ApplyVisibility() end
        elseif lower == "show" then
            SC:SetVisible(true)
        elseif lower == "hide" then
            SC:SetVisible(false)
        elseif lower == "lock" then
            SC:SetLocked(true)
        elseif lower == "unlock" then
            SC:SetLocked(false)
        elseif lower == "move" then
            SC:SetEnabled(true)
            SC:SetVisible(true)
            SC:SetLocked(false)
        elseif lower == "enable" or lower == "on" then
            SC:SetEnabled(true)
        elseif lower == "disable" or lower == "off" then
            SC:SetEnabled(false)
        elseif lower == "reset" then
            if SC.ResetPosition then SC:ResetPosition() end
        elseif lower == "scan" then
            SC:MarkScanDirty("manual")
        elseif lower == "status" then
            local c = SC.coverage or {}
            d(string.format("|cE66A19[ĄS SUPPORT]|r %s • %d/%d requirements • %d limited",
                tostring(SC.sv.activeProfile or "full"),
                tonumber(c.coveredCount) or 0,
                tonumber(c.requiredCount) or 0,
                tonumber(c.limitedPlayers) or 0))
        elseif lower == "history" then
            SC:OpenInspector("HISTORY")
        elseif lower == "report" then
            local pulls = SC:GetHistoryPulls()
            if pulls[#pulls] then SC:OpenPullReport(pulls[#pulls]) else SC:OpenInspector("HISTORY") end
        elseif lower == "reset history" then
            SC:ResetHistory("Manual reset")
        elseif lower == "audit" or lower == "checks" then
            SC:OpenInspector("CHECKS")
        elseif lower == "build" then
            SC:OpenInspector("BUILD")
        elseif lower == "expected" then
            SC:OpenInspector("EXPECTED")
        elseif lower:match("^capture%s+") then
            local role = string.upper(arg:sub(9))
            local allowed = {MT=true, OT=true, H1=true, H2=true, ["DD PARSE"]=true, ["DD SUPPORT"]=true}
            if allowed[role] then
                local _, message = SC:CaptureExpectedBuild(role)
                d("|cE66A19[AS SUPPORT]|r " .. message)
            end
        elseif lower == "matrix" then
            if SC.OpenMatrix then SC:OpenMatrix() end
        elseif lower == "saveprofile" then
            local name = SC:SaveContextProfile()
            d("|cE66A19[ĄS SUPPORT]|r Saved profile: " .. tostring(name))
        elseif lower == "loadprofile" then
            local ok = SC:LoadContextProfile()
            d("|cE66A19[ĄS SUPPORT]|r Context profile " .. (ok and "loaded." or "not found."))
        elseif lower:match("^custom%s+") then
            local effectKey, id = lower:match("^custom%s+([%w_]+)%s+(%d+)$")
            local ok = SC:AddCustomEffectId(effectKey, id)
            d("|cE66A19[ĄS SUPPORT]|r Custom effect ID " .. (ok and "saved." or "invalid."))
        else
            d("|cE66A19[ĄS SUPPORT]|r /assupport • matrix • show/hide • lock/unlock • scan • status • saveprofile/loadprofile • custom <key> <id> • reset")
        end
    end
end

function SC:Initialize()
    if self.initialized then return end
    self:EnsureSavedVariables()
    self:EnsureHistorySession()
    self:RebuildEffectIndex()
    self.initialized = true

    if self.CreateHUD then self:CreateHUD() end
    if self.InitializeSharing then self:InitializeSharing() end
    self:RegisterSceneCallbacks()
    self:RegisterSlashCommands()
    self:RegisterEvents()
    self:SetSafetyUpdateActive(self.sv.enabled and not self.uiObscured)
    self:RefreshUIObscured()

    zo_callLater(function()
        if SC then
            SC:MarkScanDirty("initial")
        end
    end, 500)
end

local function OnAddonLoaded(_, addonName)
    if addonName ~= "AlphaSquadUI" then return end
    EM:UnregisterForEvent("AlphaSquadUI_SupportCoverage_Loaded", EVENT_ADD_ON_LOADED)
    SC:Initialize()
end

EM:RegisterForEvent("AlphaSquadUI_SupportCoverage_Loaded", EVENT_ADD_ON_LOADED, OnAddonLoaded)
