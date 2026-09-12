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
SC.version = (AlphaSquadUI and AlphaSquadUI.version) or "2.7.0-support-coverage-test.1"
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
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

SC.Clamp = Clamp

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
        end
    end

    self.sv.scale = Clamp(self.sv.scale, 60, 180)
    self.sv.opacity = Clamp(self.sv.opacity, 30, 100)
    self.sv.width = Clamp(self.sv.width, 300, 680)
    self.sv.rowHeight = Clamp(self.sv.rowHeight, 24, 48)
    if self.EnsureAuditSettings then self:EnsureAuditSettings() end

    local tableKeys = {
        "roleOverrides", "assignmentLocks", "duplicateBackups", "manualCapabilities",
        "customRequirements", "customCatalog", "profileOverrides", "contextProfiles",
    }
    for _, key in ipairs(tableKeys) do
        if type(self.sv[key]) ~= "table" then self.sv[key] = {} end
    end
end

function SC:IsGrouped()
    return IsUnitGrouped and IsUnitGrouped("player") or ((GetGroupSize and GetGroupSize() or 0) > 0)
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

    if self.scanDirty and self.ScanLocalPlayer then
        self.localSnapshot = self:ScanLocalPlayer()
        self.scanDirty = false
        if self.ShareLocalSnapshot then self:ShareLocalSnapshot("scan") end
    end

    if self.RefreshReadinessFacts then self:RefreshReadinessFacts() end
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
        if self.NowMs()-(self.share.lastSendAt or 0)>10000 then self:ShareLocalSnapshot("heartbeat") end
        if self.QueueBuildDetails then self:QueueBuildDetails(false) end
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
    elseif self.Try and self.Try(IsUnitInCombat, "player") == true then
        self:OnCombatState(true)
    end
    if self.ApplyVisibility then self:ApplyVisibility() end
    self:Refresh("enabled")
end

function SC:SetVisible(visible)
    self.sv.visible = visible == true
    if self.ApplyVisibility then self:ApplyVisibility() end
end

function SC:SetLocked(locked)
    locked = locked == true
    if locked and self.SavePosition then self:SavePosition() end
    self.sv.locked = locked
    if self.UpdateLockState then self:UpdateLockState() end
    if self.RefreshSettings then self:RefreshSettings() end
end

function SC:SetActiveProfile(profileKey)
    if not profileKey or profileKey == "" then return end
    self.sv.activeProfile = profileKey
    self:Refresh("profile")
    if self.SchedulePlanBroadcast then self:SchedulePlanBroadcast() end
end

function SC:GetContextKey()
    if self.GetEncounterMetadata then return self:GetEncounterMetadata().key end
    return "Unknown context"
end

local function ShallowCopy(source)
    local result = {}
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            result[key] = ShallowCopy(value)
        else
            result[key] = value
        end
    end
    return result
end

function SC:SaveContextProfile(name)
    name = tostring(name or self:GetContextKey())
    if name == "" then return nil end
    self.sv.contextProfiles[name] = {
        activeProfile = self.sv.activeProfile,
        checkModes = ShallowCopy(self.sv.checkModes),
        championScope=self.sv.championScope,
        minimumMeasuredPercent=self.sv.minimumMeasuredPercent,
        effectRules = ShallowCopy(self.sv.effectRules),
        buildTemplates = ShallowCopy(self.sv.buildTemplates),
        playerTemplates = ShallowCopy(self.sv.playerTemplates),
        profileOverrides = ShallowCopy(self.sv.profileOverrides),
        assignmentLocks = ShallowCopy(self.sv.assignmentLocks),
        duplicateBackups = ShallowCopy(self.sv.duplicateBackups),
        roleOverrides = ShallowCopy(self.sv.roleOverrides),
        savedAt = self.NowMs(),
    }
    self.lastContextProfile = name
    return name
end

function SC:LoadContextProfile(name)
    name = tostring(name or self:GetContextKey())
    local profile = self.sv.contextProfiles[name]
    if type(profile) ~= "table" then return false end

    self.sv.activeProfile = profile.activeProfile or self.sv.activeProfile
    self.sv.championScope=profile.championScope or self.sv.championScope
    self.sv.minimumMeasuredPercent=profile.minimumMeasuredPercent or self.sv.minimumMeasuredPercent
    for _,key in ipairs({"checkModes","effectRules","buildTemplates","playerTemplates"}) do
        if type(profile[key])=="table" then self.sv[key]=ShallowCopy(profile[key]) end
    end
    self.sv.profileOverrides = ShallowCopy(profile.profileOverrides or {})
    self.sv.assignmentLocks = ShallowCopy(profile.assignmentLocks or {})
    self.sv.duplicateBackups = ShallowCopy(profile.duplicateBackups or {})
    self.sv.roleOverrides = ShallowCopy(profile.roleOverrides or {})
    self.lastContextProfile = name
    self:Refresh("context profile")
    if self.SchedulePlanBroadcast then self:SchedulePlanBroadcast() end
    return true
end

function SC:AddCustomEffectId(effectKey, abilityId)
    effectKey = tostring(effectKey or "")
    abilityId = tonumber(abilityId)
    if not abilityId or abilityId <= 0 then return false end
    if not self.Catalog or not self.Catalog.effects[effectKey] then return false end

    self.sv.customCatalog[effectKey] = self.sv.customCatalog[effectKey] or {}
    self.sv.customCatalog[effectKey][tostring(math.floor(abilityId))] = true
    if self.RebuildEffectIndex then self:RebuildEffectIndex() end
    return true
end

function SC:OnCombatState(inCombat)
    if not self.sv or not self.sv.enabled then return end
    self.combatEndGeneration = (self.combatEndGeneration or 0) + 1
    local generation = self.combatEndGeneration
    if inCombat then
        if self.inCombat then return end
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
        for index = 1, math.min(12, GetGroupSize and GetGroupSize() or 0) do
            local tag = SC.Try(GetGroupUnitTagByIndex, index) or ("group" .. index)
            if SC.Try(IsUnitInCombat, tag) == true then fighting = true end
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
                    SC:CheckGroupSession()
                    if SC.Try(IsUnitInCombat, "player") == true then SC:OnCombatState(true) end
                end
            end, 350)
        end)
    end

    if EVENT_GROUP_MEMBER_JOINED then
        EM:RegisterForEvent(prefix .. "_Joined", EVENT_GROUP_MEMBER_JOINED, function()
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
        EM:RegisterForEvent(prefix .. "_Connected", EVENT_GROUP_MEMBER_CONNECTED_STATUS, function()
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
        {"SkillLines", EVENT_SKILL_LINE_ADDED}, {"Quickslot", EVENT_CURRENT_QUICKSLOT_CHANGED},
    }) do
        if definition[2] then EM:RegisterForEvent(prefix .. "_" .. definition[1], definition[2], Dirty) end
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
    EM:RegisterForUpdate(prefix .. "_Safety", 2500, function()
        if not SC or not SC.sv then return end
        SC:CheckGroupSession()
        if not SC.sv.enabled then return end
        if SC.uiObscured and not (SC.settingsPageVisible or false) then return end
        SC:Refresh("safety")
    end)
end

local function SceneVisible(scene)
    if not scene or not scene.GetState then return false end
    local state = scene:GetState()
    return state == SCENE_SHOWING or state == SCENE_SHOWN
end

function SC:RefreshUIObscured()
    self.uiObscured = not (SceneVisible(HUD_SCENE) or SceneVisible(HUD_UI_SCENE))
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
        elseif lower == "show" then
            SC:SetVisible(true)
        elseif lower == "hide" then
            SC:SetVisible(false)
        elseif lower == "lock" then
            SC:SetLocked(true)
        elseif lower == "unlock" or lower == "move" then
            SC:SetLocked(false)
            SC:SetVisible(true)
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
        elseif lower:match("^mundus%s+%d+$") then
            local id = lower:match("^mundus%s+(%d+)$")
            SC.sv.mundusAbilityIds = SC.sv.mundusAbilityIds or {}
            SC.sv.mundusAbilityIds[id] = true
            SC:MarkScanDirty("Mundus identity")
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
