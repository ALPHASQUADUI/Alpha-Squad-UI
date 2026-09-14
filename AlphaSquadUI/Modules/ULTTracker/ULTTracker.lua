--[[
    Ąlpha Şquad UI - ULT Tracker
    Module author: SeRuM1
    Version: 2.6.0

    Generic Ultimate tracker for the player's PRIMARY and BACKUP weapon bars.
    No hard-coded ability IDs are required: the module reads the slotted Ultimate,
    effective ability ID, localized name, texture and Ultimate cost directly from ESO.
]]

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}

local ULT = AlphaSquadUI.Modules.ULTTracker or {}
AlphaSquadUI.Modules.ULTTracker = ULT

ULT.name = "ULTTracker"
ULT.displayName = "ULT Tracker"
ULT.version = (AlphaSquadUI and AlphaSquadUI.version) or "2.8.0"
ULT.addonName = "AlphaSquadUI"
ULT.savedVarsName = "AlphaSquadULTTrackerSavedVariables"

local EM = AlphaSquadUI.Events and AlphaSquadUI.Events.NewScope and AlphaSquadUI.Events.NewScope(function(name,event)
    return event==EVENT_ADD_ON_LOADED or event==EVENT_PLAYER_ACTIVATED or event==EVENT_PLAYER_DEACTIVATED or name=="AlphaSquadUI_SettingsResize"
end) or EVENT_MANAGER
local ULTIMATE_POWER_TYPE = COMBAT_MECHANIC_FLAGS_ULTIMATE or POWERTYPE_ULTIMATE
local ULTIMATE_SLOT_BASE = ACTION_BAR_ULTIMATE_SLOT_INDEX or 7
local ULTIMATE_SLOT = ULTIMATE_SLOT_BASE + 1

ULT.ULTIMATE_SLOT = ULTIMATE_SLOT
ULT.ULTIMATE_POWER_TYPE = ULTIMATE_POWER_TYPE

ULT.bars = ULT.bars or {
    primary = {
        key = "primary",
        label = "MAIN BAR",
        category = HOTBAR_CATEGORY_PRIMARY,
        abilityId = 0,
        name = "",
        icon = "",
        cost = 0,
        ready = false,
        toggled = false,
        activeBar = false,
        recentlyUsedUntil = 0,
    },
    backup = {
        key = "backup",
        label = "BACK BAR",
        category = HOTBAR_CATEGORY_BACKUP,
        abilityId = 0,
        name = "",
        icon = "",
        cost = 0,
        ready = false,
        toggled = false,
        activeBar = false,
        recentlyUsedUntil = 0,
    },
}

ULT.sv = nil
ULT.window = nil
ULT.uiObscured = false
ULT.currentUltimate = 0
ULT.lastSoundAt = 0
ULT.flashRunning = false
ULT.initialized = false

local function NowMs()
    if GetGameTimeMilliseconds then return GetGameTimeMilliseconds() end
    return 0
end

local Clamp = AlphaSquadUI.Utils and AlphaSquadUI.Utils.Clamp
if not Clamp then
    Clamp = function(value, minimum, maximum)
        value = tonumber(value) or minimum
        if value ~= value or value == math.huge or value == -math.huge then value = minimum end
        if value < minimum then return minimum end
        if value > maximum then return maximum end
        return value
    end
end

ULT.Clamp = Clamp

local function FiniteOr(value, fallback)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return fallback end
    return value
end

function ULT:GetDefaultPosition()
    local width = GuiRoot:GetWidth() or 1920
    local height = GuiRoot:GetHeight() or 1080
    return math.floor((width - 610) / 2), math.floor(height * 0.13)
end

function ULT:GetUltimatePower()
    if not GetUnitPower or not ULTIMATE_POWER_TYPE then return 0 end
    local current = GetUnitPower("player", ULTIMATE_POWER_TYPE)
    return math.min(1000000, math.max(0, FiniteOr(current, 0)))
end

function ULT:GetActiveBarCategory()
    if GetActiveHotbarCategory then
        return GetActiveHotbarCategory()
    end
    return nil
end

function ULT:GetEffectiveAbilityId(boundId, category)
    boundId = FiniteOr(boundId, 0)
    if boundId <= 0 or boundId > 2147483647 or boundId % 1 ~= 0 then return 0 end
    if GetEffectiveAbilityIdForAbilityOnHotbar then
        local resolved = FiniteOr(GetEffectiveAbilityIdForAbilityOnHotbar(boundId, category), 0)
        if resolved > 0 and resolved <= 2147483647 and resolved % 1 == 0 then return resolved end
    end
    return boundId
end

function ULT:GetUltimateCost(category, effectiveId)
    local cost = 0

    if GetSlotAbilityCost and ULTIMATE_POWER_TYPE then
        local ok, result = pcall(GetSlotAbilityCost, ULTIMATE_SLOT, ULTIMATE_POWER_TYPE, category)
        if ok then cost = FiniteOr(result, 0) end
    end

    if cost <= 0 and effectiveId and effectiveId > 0 and GetAbilityCost and ULTIMATE_POWER_TYPE then
        local ok, result = pcall(GetAbilityCost, effectiveId, ULTIMATE_POWER_TYPE, nil, "player")
        if ok then cost = FiniteOr(result, 0) end
    end

    if cost <= 0 and effectiveId and effectiveId > 0 and GetAbilityBaseCostInfo then
        local ok, baseCost, mechanic = pcall(GetAbilityBaseCostInfo, effectiveId, nil, "player")
        baseCost = FiniteOr(baseCost, nil)
        if ok and baseCost and (mechanic == nil or mechanic == ULTIMATE_POWER_TYPE) then
            cost = baseCost
        end
    end

    return math.min(1000000, math.max(0, math.floor(FiniteOr(cost, 0) + 0.5)))
end

function ULT:ReadBar(bar)
    local category = bar.category
    local boundId = GetSlotBoundId and GetSlotBoundId(ULTIMATE_SLOT, category) or 0
    boundId = FiniteOr(boundId, 0)

    if boundId <= 0 then
        bar.abilityId = 0
        bar.name = ""
        bar.icon = ""
        bar.cost = 0
        bar.toggled = false
        bar.ready = false
        return
    end

    local effectiveId = self:GetEffectiveAbilityId(boundId, category)
    local name = GetSlotName and GetSlotName(ULTIMATE_SLOT, category) or ""
    local icon = GetSlotTexture and select(1, GetSlotTexture(ULTIMATE_SLOT, category)) or ""

    if (not name or name == "") and GetAbilityName then
        name = GetAbilityName(effectiveId) or ""
    end
    if (not icon or icon == "") and GetAbilityIcon then
        icon = GetAbilityIcon(effectiveId) or ""
    end

    bar.abilityId = effectiveId
    bar.name = name or ""
    bar.icon = icon or ""
    bar.cost = self:GetUltimateCost(category, effectiveId)
    bar.toggled = IsSlotToggled and IsSlotToggled(ULTIMATE_SLOT, category) == true or false
end

function ULT:ShouldTrackBar(key)
    local mode = self.sv and self.sv.trackMode or "both"
    if mode == "main" then return key == "primary" end
    if mode == "back" then return key == "backup" end
    return true
end

function ULT:ComputeBarState(bar, current)
    bar.activeBar = self:GetActiveBarCategory() == bar.category

    if bar.abilityId <= 0 then
        bar.ready = false
        return "empty"
    end

    if bar.toggled then
        bar.ready = false
        return "active"
    end

    if NowMs() < (bar.recentlyUsedUntil or 0) then
        bar.ready = false
        return "used"
    end

    if bar.cost > 0 and current >= bar.cost then
        bar.ready = true
        return "ready"
    end

    bar.ready = false
    return "charging"
end

function ULT:PlayReadySound()
    if not self.sv or not self.sv.readySound or not PlaySound or not SOUNDS then return end
    if self.uiObscured then return end

    local now = NowMs()
    if now - (self.lastSoundAt or 0) < 350 then return end
    self.lastSoundAt = now

    local soundId =
        SOUNDS.ABILITY_ULTIMATE_READY
        or SOUNDS.GENERAL_ALERT_NOTIFICATION
        or SOUNDS.CHAMPION_POINT_GAINED
        or SOUNDS.POSITIVE_CLICK

    if soundId then PlaySound(soundId) end
end

function ULT:SetFlashUpdate(enabled)
    enabled = enabled == true
    if self.flashRunning == enabled then return end
    self.flashRunning = enabled

    local updateName = "AlphaSquadUI_ULTTracker_Flash"
    if enabled then
        EM:RegisterForUpdate(updateName, 80, function()
            if ULT and ULT.UpdateReadyPulse then ULT:UpdateReadyPulse() end
        end)
    else
        EM:UnregisterForUpdate(updateName)
        if self.ResetPulseVisuals then self:ResetPulseVisuals() end
    end
end

function ULT:Refresh(reason, observedUltimate)
    if self.loading then return end
    if not self.initialized or not self.sv then return end
    if not self.sv.enabled then
        self:SetFlashUpdate(false)
        return
    end

    local currentUltimate = FiniteOr(observedUltimate, nil)
    if currentUltimate == nil then currentUltimate = self:GetUltimatePower() end
    self.currentUltimate = math.min(1000000, math.max(0, currentUltimate))

    local previousPrimaryReady = self.bars.primary.ready
    local previousBackupReady = self.bars.backup.ready

    self:ReadBar(self.bars.primary)
    self:ReadBar(self.bars.backup)

    local primaryState = self:ComputeBarState(self.bars.primary, self.currentUltimate)
    local backupState = self:ComputeBarState(self.bars.backup, self.currentUltimate)

    self.bars.primary.state = primaryState
    self.bars.backup.state = backupState

    local primaryReadyTransition =
        self:ShouldTrackBar("primary") and self.bars.primary.ready and not previousPrimaryReady
    local backupReadyTransition =
        self:ShouldTrackBar("backup") and self.bars.backup.ready and not previousBackupReady

    if primaryReadyTransition or backupReadyTransition then
        self:PlayReadySound()
    end

    local anyReady =
        (self:ShouldTrackBar("primary") and self.bars.primary.ready)
        or (self:ShouldTrackBar("backup") and self.bars.backup.ready)

    local hudVisible = self.sv.visible and not self.uiObscured
    if hudVisible and self.window and self.window.IsHidden then
        hudVisible = not self.window:IsHidden()
    end
    self:SetFlashUpdate(anyReady and self.sv.readyFlash and hudVisible)

    if self.RefreshHUD then self:RefreshHUD() end
    if self.RefreshSettings then self:RefreshSettings() end
end

function ULT:OnUltimateUsed(slotNum)
    if slotNum ~= ULTIMATE_SLOT or not self.sv or not self.sv.enabled then return end

    local activeCategory = self:GetActiveBarCategory()
    local now = NowMs()

    if activeCategory == HOTBAR_CATEGORY_PRIMARY then
        self.bars.primary.ready = false
        self.bars.primary.recentlyUsedUntil = now + 1200
    elseif activeCategory == HOTBAR_CATEGORY_BACKUP then
        self.bars.backup.ready = false
        self.bars.backup.recentlyUsedUntil = now + 1200
    end

    if self.RefreshHUD then self:RefreshHUD() end

    zo_callLater(function() if ULT then ULT:Refresh("ultimate used") end end, 50)
    zo_callLater(function() if ULT then ULT:Refresh("ultimate used settle") end end, 300)
    zo_callLater(function() if ULT then ULT:Refresh("ultimate used final") end end, 1250)
end

function ULT:SetEnabled(enabled)
    if EM.SetActive then EM:SetActive(enabled==true and not self.loading) end
    self.sv.enabled = enabled == true
    if self.Group and self.Group.SetTrackingEventsActive then self.Group:SetTrackingEventsActive() end
    if not self.sv.enabled then self:SetFlashUpdate(false) end
    self:SetSafetyUpdateActive(self.sv.enabled and not self.uiObscured)
    if self.Group and self.Group.SetSafetyUpdateActive then
        self.Group:SetSafetyUpdateActive(self.sv.enabled and self.Group.sv and self.Group.sv.enabled and not self.uiObscured)
    end
    if self.ApplyVisibility then self:ApplyVisibility() end
    if self.Group and self.Group.ApplyVisibility then self.Group:ApplyVisibility() end
    if self.sv.enabled then self:Refresh("enable changed") end
end

function ULT:SetVisible(visible)
    self.sv.visible = visible == true
    if self.ApplyVisibility then self:ApplyVisibility() end
    if self.sv.enabled and self.sv.visible then self:Refresh("visibility changed") end
end

function ULT:SetLocked(locked)
    locked = locked == true
    if locked and self.SavePosition then self:SavePosition() end
    self.sv.locked = locked
    if self.UpdateLockState then self:UpdateLockState() end
    if self.RefreshSettings then self:RefreshSettings() end
end

function ULT:SetTrackMode(mode)
    if mode ~= "main" and mode ~= "back" and mode ~= "both" then return end
    self.sv.trackMode = mode
    if self.ApplyLayout then self:ApplyLayout() end
    self:Refresh("track mode")
end

local function SceneVisible(scene)
    if not scene or not scene.GetState then return false end
    local state = scene:GetState()
    return state == SCENE_SHOWING or state == SCENE_SHOWN
end

function ULT:RefreshUIObscured()
    self.uiObscured = self.loading or not (SceneVisible(HUD_SCENE) or SceneVisible(HUD_UI_SCENE))
    if self.Group and self.Group.SetTrackingEventsActive then self.Group:SetTrackingEventsActive() end
    if self.uiObscured then self:SetFlashUpdate(false) end
    self:SetSafetyUpdateActive(self.sv and self.sv.enabled and not self.uiObscured)
    if self.Group and self.Group.SetSafetyUpdateActive then
        self.Group:SetSafetyUpdateActive(self.sv and self.sv.enabled and self.Group.sv and self.Group.sv.enabled and not self.uiObscured)
    end
    if self.ApplyVisibility then self:ApplyVisibility() end
    if self.Group and self.Group.ApplyVisibility then self.Group:ApplyVisibility() end
    if not self.uiObscured then self:Refresh("hud visible") end
end

function ULT:SetSafetyUpdateActive(enabled)
    enabled = enabled == true and not self.loading
    if self.safetyUpdateActive == enabled then return end
    self.safetyUpdateActive = enabled
    local name = "AlphaSquadUI_ULTTracker_Safety"
    if enabled then
        EM:RegisterForUpdate(name, 1500, function()
            if ULT and ULT.sv and ULT.sv.enabled and not ULT.uiObscured then
                ULT:Refresh("safety")
            end
        end)
    else
        EM:UnregisterForUpdate(name)
    end
end

function ULT:RegisterSceneCallbacks()
    local function StateChanged()
        zo_callLater(function()
            if ULT then ULT:RefreshUIObscured() end
        end, 0)
    end
    if HUD_SCENE and HUD_SCENE.RegisterCallback then
        HUD_SCENE:RegisterCallback("StateChange", StateChanged)
    end
    if HUD_UI_SCENE and HUD_UI_SCENE.RegisterCallback then
        HUD_UI_SCENE:RegisterCallback("StateChange", StateChanged)
    end
end

function ULT:RegisterEvents()
    local prefix = "AlphaSquadUI_ULTTracker"

    if EVENT_POWER_UPDATE then
        local name = prefix .. "_Power"
        EM:RegisterForEvent(name, EVENT_POWER_UPDATE, function(_, unitTag, _, powerType, powerValue)
            if unitTag ~= "player" then return end
            if ULTIMATE_POWER_TYPE and powerType ~= ULTIMATE_POWER_TYPE then return end
            ULT:Refresh("power", powerValue)
        end)
        if REGISTER_FILTER_UNIT_TAG and REGISTER_FILTER_POWER_TYPE and ULTIMATE_POWER_TYPE then
            EM:AddFilterForEvent(name, EVENT_POWER_UPDATE,
                REGISTER_FILTER_UNIT_TAG, "player",
                REGISTER_FILTER_POWER_TYPE, ULTIMATE_POWER_TYPE)
        end
    end

    if EVENT_ACTION_SLOT_ABILITY_USED then
        EM:RegisterForEvent(prefix .. "_Used", EVENT_ACTION_SLOT_ABILITY_USED, function(_, slotNum)
            ULT:OnUltimateUsed(slotNum)
        end)
    end

    if EVENT_HOTBAR_SLOT_UPDATED then
        EM:RegisterForEvent(prefix .. "_HotbarSlot", EVENT_HOTBAR_SLOT_UPDATED, function(...)
            zo_callLater(function() if ULT then ULT:Refresh("hotbar slot") end end, 25)
        end)
    end

    if EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED then
        EM:RegisterForEvent(prefix .. "_AllBars", EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED, function()
            zo_callLater(function() if ULT then ULT:Refresh("all hotbars") end end, 25)
        end)
    end

    if EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED then
        EM:RegisterForEvent(prefix .. "_ActiveBar", EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED, function()
            zo_callLater(function() if ULT then ULT:Refresh("active bar") end end, 25)
        end)
    end

    if EVENT_ACTION_SLOT_STATE_UPDATED then
        EM:RegisterForEvent(prefix .. "_SlotState", EVENT_ACTION_SLOT_STATE_UPDATED, function(_, slotNum)
            if slotNum == ULTIMATE_SLOT then
                zo_callLater(function() if ULT then ULT:Refresh("slot state") end end, 25)
            end
        end)
    end

    EM:RegisterForEvent(prefix .. "_Activated", EVENT_PLAYER_ACTIVATED, function()
        ULT.loading=false
        if EM.SetActive then EM:SetActive(ULT.sv.enabled==true) end
        zo_callLater(function()
            if ULT then
                ULT:RefreshUIObscured()
                ULT:Refresh("player activated")
            end
        end, 300)
    end)

    if EVENT_PLAYER_DEACTIVATED then
        EM:RegisterForEvent(prefix.."_Deactivated",EVENT_PLAYER_DEACTIVATED,function()
            ULT.loading=true;ULT:RefreshUIObscured()
            if EM.SetActive then EM:SetActive(false) end
            if ULT.Group and ULT.Group.SetReadyPulseActive then ULT.Group:SetReadyPulseActive(false) end
        end)
    end
    if EVENT_SCREEN_RESIZED then
        EM:RegisterForEvent(prefix .. "_ScreenResized", EVENT_SCREEN_RESIZED, function()
            zo_callLater(function()
                if ULT and ULT.window then
                    ULT:ApplyLayout()
                    ULT:ApplyAppearance()
                    ULT:ClampToScreen(true)
                    ULT:RefreshHUD()
                end
                if ULT and ULT.Group and ULT.Group.window then
                    ULT.Group:ApplyAppearance()
                    ULT.Group:ClampToScreen(true)
                    ULT.Group:RefreshHUD()
                    if ULT.Group.ApplyConfigWindowScale then ULT.Group:ApplyConfigWindowScale() end
                end
            end, 50)
        end)
    end

    -- The slow fallback is registered only while the visible feature is active.
end

function ULT:RegisterSlashCommands()
    SLASH_COMMANDS["/asult"] = function(argument)
        local arg = tostring(argument or ""):match("^%s*(.-)%s*$") or ""
        local lower = string.lower(arg)

        if lower == "" or lower == "settings" or lower == "options" then
            if ULT.ToggleSettings then ULT:ToggleSettings() end
        elseif lower == "lock" then
            ULT:SetLocked(true)
        elseif lower == "unlock" then
            ULT:SetLocked(false)
        elseif lower == "move" then
            ULT:SetEnabled(true)
            ULT:SetVisible(true)
            ULT:SetLocked(false)
        elseif lower == "show" then
            ULT:SetVisible(true)
        elseif lower == "hide" then
            ULT:SetVisible(false)
        elseif lower == "enable" or lower == "on" then
            ULT:SetEnabled(true)
        elseif lower == "disable" or lower == "off" then
            ULT:SetEnabled(false)
        elseif lower == "main" or lower == "mode main" then
            ULT:SetTrackMode("main")
        elseif lower == "back" or lower == "mode back" then
            ULT:SetTrackMode("back")
        elseif lower == "both" or lower == "mode both" then
            ULT:SetTrackMode("both")
        elseif lower == "reset" then
            if ULT.ResetPosition then ULT:ResetPosition() end
        elseif lower == "group" or lower == "group config" or lower == "group settings" then
            if ULT.Group and ULT.Group.ToggleConfig then ULT.Group:ToggleConfig() end
        elseif lower == "group show" then
            ULT:SetEnabled(true)
            if ULT.Group then ULT.Group:SetEnabled(true); ULT.Group:SetVisible(true) end
        elseif lower == "group hide" then
            if ULT.Group then ULT.Group:SetVisible(false) end
        elseif lower == "group lock" then
            if ULT.Group then ULT.Group:SetLocked(true) end
        elseif lower == "group unlock" then
            if ULT.Group then ULT.Group:SetLocked(false) end
        elseif lower == "group move" then
            ULT:SetEnabled(true)
            if ULT.Group then
                ULT.Group:SetEnabled(true)
                ULT.Group:SetVisible(true)
                ULT.Group:SetLocked(false)
            end
        elseif lower == "group reset" then
            if ULT.Group and ULT.Group.ResetPosition then ULT.Group:ResetPosition() end
        elseif lower == "status" then
            local p, b = ULT.bars.primary, ULT.bars.backup
            d(string.format("|cE66A19[ĄS ULT]|r ULT %d | MAIN: %s (%d) %s | BACK: %s (%d) %s",
                ULT.currentUltimate or 0,
                p.name ~= "" and p.name or "EMPTY", p.cost or 0, p.state or "",
                b.name ~= "" and b.name or "EMPTY", b.cost or 0, b.state or ""))
        else
            d("|cE66A19[ĄS ULT]|r /asult • main • back • both • group • group show/hide • group lock/unlock • reset • status")
        end
    end
end

function ULT:Initialize()
    if self.initialized then return end

    local defaultX, defaultY = self:GetDefaultPosition()
    local defaults = {
        enabled = true,
        visible = true,
        locked = false,
        trackMode = "both",
        readySound = true,
        readyFlash = true,
        hideInMenus = true,
        scale = 100,
        opacity = 92,
        x = defaultX,
        y = defaultY,
        positionSaved = false,
    }

    local worldNamespace = GetWorldName and GetWorldName() or nil
    self.sv = AlphaSquadUI.Preferences and AlphaSquadUI.Preferences.Open("ULTTracker", self.savedVarsName, worldNamespace, defaults)
        or ZO_SavedVars:NewAccountWide(self.savedVarsName, 1, worldNamespace, defaults)

    for key, value in pairs(defaults) do
        if self.sv[key] == nil or (type(value) == "boolean" and type(self.sv[key]) ~= "boolean") then
            self.sv[key] = value
        end
    end
    self.sv.scale = Clamp(FiniteOr(self.sv.scale, defaults.scale), 70, 150)
    self.sv.opacity = Clamp(FiniteOr(self.sv.opacity, defaults.opacity), 30, 100)
    self.sv.x = Clamp(FiniteOr(self.sv.x, defaults.x), -100000, 100000)
    self.sv.y = Clamp(FiniteOr(self.sv.y, defaults.y), -100000, 100000)
    if self.sv.trackMode ~= "main" and self.sv.trackMode ~= "back" and self.sv.trackMode ~= "both" then
        self.sv.trackMode = "both"
    end

    if self.CreateHUD then self:CreateHUD() end
    -- ULT settings are provided exclusively by the shared Ąlpha Şquad settings shell.
    if self.InitializeGroup then self:InitializeGroup() end

    self:RegisterSceneCallbacks()
    self:RegisterEvents()
    if EM.SetActive then EM:SetActive(self.sv.enabled) end
    self:RegisterSlashCommands()

    self.initialized = true
    self:SetSafetyUpdateActive(self.sv.enabled and not self.uiObscured)

    zo_callLater(function()
        if ULT then
            ULT:RefreshUIObscured()
            ULT:Refresh("initial")
        end
    end, 450)
end

local function OnAddonLoaded(_, addonName)
    if addonName ~= ULT.addonName then return end
    EM:UnregisterForEvent("AlphaSquadUI_ULTTracker_Loaded", EVENT_ADD_ON_LOADED)
    ULT:Initialize()
end

EM:RegisterForEvent("AlphaSquadUI_ULTTracker_Loaded", EVENT_ADD_ON_LOADED, OnAddonLoaded)
