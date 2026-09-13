--[[
    Ąlpha Şquad UI - Support Coverage
    Pre-combat group preparation and voluntary build sharing.
    Author: SeRuM1
]]

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}

local SC = AlphaSquadUI.Modules.SupportCoverage or {}
AlphaSquadUI.Modules.SupportCoverage = SC

SC.name = "SupportCoverage"
SC.displayName = "Support Coverage"
SC.version = (AlphaSquadUI and AlphaSquadUI.version) or "2.7.0"
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
SC.scanDirty = true
SC.refreshPending = false
SC.lastSafetyAt = 0

local VALID_PROFILES = {trial=true, dungeon=true, full=true, progression=true, damage=true, trash=true, boss=true, custom=true}

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
        shareData = true,
        scale = 100,
        opacity = 94,
        width = 410,
        rowHeight = 30,
        x = x,
        y = y,
        positionSaved = false,
        activeProfile = "trial",
        customRequirements = {},
        profileOverrides = {},
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
    if not VALID_PROFILES[self.sv.activeProfile] then self.sv.activeProfile = "trial" end
    if self.EnsureAuditSettings then self:EnsureAuditSettings() end

    self:SanitizePlanningSettings()
    if self.sv.preparationVersion ~= 1 then
        local previous = self.sv.activeProfile
        if previous ~= "trial" and previous ~= "dungeon" then
            if not self.sv.profileOverrides.trial then
                self.sv.profileOverrides.trial = self.sv.profileOverrides[previous] or {}
            end
            self.sv.activeProfile = "trial"
        end
        for _, profileKey in ipairs({"trial", "dungeon"}) do
            local overrides = self.sv.profileOverrides[profileKey] or {}
            self.sv.profileOverrides[profileKey] = overrides
            for effectKey, rule in pairs(self.sv.effectRules or {}) do
                if type(rule) == "table" and rule.enabled == false and overrides[effectKey] == nil then
                    overrides[effectKey] = false
                end
            end
        end
        self.sv.preparationVersion = 1
    end
    -- Pull reports are intentionally retired. Keep unrelated positions/preferences.
    for _, key in ipairs({"history", "historySession", "persistedHistory", "pullHistory", "raidHistory", "lastReport"}) do self.sv[key] = nil end
    self.sv.historyEnabled, self.sv.persistHistory, self.sv.reportAutoOpen = false, false, false
    self.trackingCache = nil
end

function SC:SanitizePlanningSettings()
    -- Only the current named tracking selections participate in preparation.
    -- Legacy role/build preferences are left untouched and are never evaluated.
    if type(self.sv.profileOverrides) ~= "table" then self.sv.profileOverrides = {} end
    if type(self.sv.customRequirements) ~= "table" then self.sv.customRequirements = {} end
    for key, enabled in pairs(self.sv.customRequirements) do
        if not self.Catalog.effects[key] or enabled ~= true then self.sv.customRequirements[key] = nil end
    end
    for profileKey, overrides in pairs(self.sv.profileOverrides) do
        if not VALID_PROFILES[profileKey] or type(overrides) ~= "table" then
            self.sv.profileOverrides[profileKey] = nil
        else
            for key, enabled in pairs(overrides) do
                if not self.Catalog.effects[key] or type(enabled) ~= "boolean" then overrides[key] = nil end
            end
        end
    end
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
    -- Preparation is frozen during combat; dirty build changes are coalesced and
    -- scanned exactly once after combat. No combat event stream is collected.
    if self.inCombat then return end
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
    if self.BuildRoster then self:BuildRoster() end
    if self.EvaluateCoverage then self:EvaluateCoverage(reason) end
    if not self.inCombat and self.share then
        if self.NowMs()-(self.share.lastSendAt or 0)>60000 then self:ShareLocalSnapshot("heartbeat") end
    end
    if self.RefreshHUD then self:RefreshHUD() end
    if self.RefreshSettings then self:RefreshSettings() end
end

function SC:SetEnabled(enabled)
    self.sv.enabled = enabled == true
    if not self.sv.enabled then
        self.inCombat = false
        if self.CloseInspector then self:CloseInspector() end
        if self.CloseMatrix then self:CloseMatrix() end
        if self.ResetExternalSources then self:ResetExternalSources() end
        if self.ResetSharingState then self:ResetSharingState("Module disabled") end
    else
        self.inCombat = self.Try and self.Try(IsUnitInCombat, "player") == true or false
        if self.InitializeSharing then self:InitializeSharing() end
        self.scanDirty = true
    end
    self:SetSafetyUpdateActive(self.sv.enabled)
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
        if self.ShareLocalSnapshot then self:ShareLocalSnapshot("build exchange enabled") end
    elseif self.ResetSharingState then
        self:ResetSharingState("Experimental sharing disabled")
    end
    self:Refresh("build exchange")
end

function SC:ResetSharingState(reason)
    if self.ResetBuildDetailState then self:ResetBuildDetailState() end
    self.peerData = {}
    self.buildSharePending = false
    if self.share then
        self.share.lastSendAt = -60000
        self.share.lastBuildFingerprint = nil
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
    self.trackingCache = nil
    self:Refresh("profile")
    return true
end

function SC:SetEffectTracking(key, enabled)
    if not self.Catalog.effects[key] then return false end
    local profile = self.sv.activeProfile
    self.sv.profileOverrides[profile] = self.sv.profileOverrides[profile] or {}
    self.sv.profileOverrides[profile][key] = enabled == true
    self.trackingCache = nil
    self:Refresh("tracking changed")
    return true
end

function SC:IsEffectTracked(key)
    local cache = self.trackingCache
    if not cache or cache.saved ~= self.sv or cache.profile ~= self.sv.activeProfile then
        cache = {saved=self.sv, profile=self.sv.activeProfile, keys={}}
        for _, effectKey in ipairs(self.Catalog:GetRequirements(self.sv.activeProfile, self.sv)) do cache.keys[effectKey] = true end
        self.trackingCache = cache
    end
    return cache.keys[key] == true
end

function SC:CheckGroupSession()
    local grouped = self:IsGrouped()
    if self.wasGrouped == true and not grouped then
        self:ResetSharingState("Group disbanded")
        if self.ResetExternalSources then self:ResetExternalSources() end
        if self.CloseInspector then self:CloseInspector() end
    end
    self.wasGrouped = grouped
end

function SC:OnCombatState(inCombat)
    if not self.sv or not self.sv.enabled then return end
    local wasInCombat = self.inCombat
    self.inCombat = inCombat == true
    if self.inCombat then
        if self.CloseInspector then self:CloseInspector() end
        if self.CloseMatrix then self:CloseMatrix() end
        if self.HideReadyBanner then self:HideReadyBanner() end
        if self.CancelBuildDetailTransfer then self:CancelBuildDetailTransfer() end
    elseif wasInCombat then
        self:ScheduleRefresh("combat ended", 150)
    end
    if self.ApplyVisibility then self:ApplyVisibility() end
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
            Dirty()
        end)
    end

    if EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED then
        EM:RegisterForEvent(prefix .. "_AllBars", EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED, function()
            Dirty()
        end)
    end

    if EVENT_ACTIVE_WEAPON_PAIR_CHANGED then
        EM:RegisterForEvent(prefix .. "_WeaponPair", EVENT_ACTIVE_WEAPON_PAIR_CHANGED, function()
            SC:ScheduleRefresh("active bar changed", 100)
        end)
    end

    if EVENT_PLAYER_ACTIVATED then
        EM:RegisterForEvent(prefix .. "_Activated", EVENT_PLAYER_ACTIVATED, function()
            if SC.ResetExternalSources then SC:ResetExternalSources() end
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
            if unitTag == "player" and SC.sv.enabled and not SC.inCombat then SC:ScheduleRefresh("consumable or boon", 500) end
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
        {"WerewolfForm", EVENT_WEREWOLF_STATE_CHANGED},
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
        EM:RegisterForUpdate(name, 5000, function()
            if not SC or not SC.sv or not SC.sv.enabled then return end
            SC:CheckGroupSession()
            if SC.inCombat then return end
            local overlayVisible = SC.inspectorWindow and not SC.inspectorWindow:IsHidden()
                or SC.matrixWindow and not SC.matrixWindow:IsHidden()
            if (SC.uiObscured or not SC.sv.visible) and not SC:IsGrouped() and not (SC.settingsPageVisible or overlayVisible) then return end
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
    self:SetSafetyUpdateActive(self.sv and self.sv.enabled)
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
        elseif lower == "build" or lower == "builds" then
            SC:OpenInspector("BUILD")
        elseif lower == "food" or lower == "checks" then
            SC:OpenFoodCheck()
        elseif lower == "matrix" then
            if SC.OpenMatrix then SC:OpenMatrix() end
        elseif lower == "trial" or lower == "dungeon" then
            SC:SetActiveProfile(lower)
        else
            d("|cE66A19[ĄS SUPPORT]|r /assupport • builds • food • matrix • trial/dungeon • show/hide • lock/unlock • scan • status • reset")
        end
    end
end

function SC:Initialize()
    if self.initialized then return end
    self:EnsureSavedVariables()
    self.initialized = true
    self.inCombat = self.Try and self.Try(IsUnitInCombat, "player") == true or false

    if self.CreateHUD then self:CreateHUD() end
    if self.InitializeSharing then self:InitializeSharing() end
    if self.InitializeExternalSources then self:InitializeExternalSources() end
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
