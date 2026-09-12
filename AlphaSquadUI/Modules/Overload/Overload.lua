--[[
    Ąlpha Şquad - Overload Tracker
    Author: SeRuM1
    Version: 2.5.0

    Tracks all Sorcerer Overload variants (Overload, Energy Overload, Power Overload),
    provides a movable/lockable HUD, an emergency reserve alarm starting at 160 Ultimate,
    an auto-stop cutoff at 130, plus a gentle Overload-ready reminder at 400+ Ultimate while Overload is OFF. Includes chat controls and built-in settings. Core addon is standalone; LibAddonMenu-2.0 is optional.

    Important API limitation:
    ESO marks action-slot activation functions (OnSlotDown/OnSlotUp/OnSlotDownAndUp)
    as private, so this addon never attempts to simulate an Ultimate key press.
    Reserve cutoff uses the public CancelBuff API only when ESO marks the active
    Overload effect as click-off capable; otherwise it warns the player immediately.

    AI-assisted development disclosure: implementation was assisted by OpenAI ChatGPT.
]]

local ADDON_NAME = "AlphaSquadUI"
local DISPLAY_NAME = "Ąlpha Şquad UI - Overload"
local SETTINGS_MENU_NAME = "|cE66A19Ą|cEA7628l|cEE8237p|cF18E47h|cF49A58a |cF6A968Ş|cF8B77Aq|cFAC58Cu|cFCD49Ea|cFFF3D0d|r"
local VERSION = "2.5.0"

AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Modules = AlphaSquadUI.Modules or {}
AlphaSquadUI.Modules.Overload = AlphaSquadUI.Modules.Overload or {}
local SITE_URL = "https://alphasquadeso.com/"
-- ESO's ACTION_BAR_ULTIMATE_SLOT_INDEX is the zero-offset/base index used by the UI.
-- The actual action-slot number passed to GetSlot* / OnSlot* for the player ultimate is +1
-- (normally slot 8). Using the base constant directly scans the fifth normal skill slot.
local ULTIMATE_SLOT_BASE = ACTION_BAR_ULTIMATE_SLOT_INDEX or 7
local ULTIMATE_SLOT = ULTIMATE_SLOT_BASE + 1
local ULTIMATE_POWER_TYPE = COMBAT_MECHANIC_FLAGS_ULTIMATE or POWERTYPE_ULTIMATE

local VARIANTS = {
    base = {
        key = "base",
        title = "OVERLOAD",
        icon = "/esoui/art/icons/ability_sorcerer_overload.dds",
    },
    energy = {
        key = "energy",
        title = "ENERGY OVERLOAD",
        icon = "/esoui/art/icons/ability_sorcerer_energy_overload.dds",
        abilityId = 30381,
    },
    power = {
        key = "power",
        title = "POWER OVERLOAD",
        icon = "/esoui/art/icons/ability_sorcerer_power_overload.dds",
        abilityId = 30366,
    },
}

local AOT = {
    sv = nil,
    window = nil,
    settingsWindow = nil,
    settingsRefreshers = {},
    isOverloadActive = false,
    currentVariant = VARIANTS.base,
    lastSlottedVariant = VARIANTS.base,
    overloadEffectConfirmed = false,
    slotToggleConfirmed = false,
    debugEnabled = false,
    reserveWarning = false,
    reservePreWarning = false,
    reserveAlertLevel = "none",
    reserveAttempted = false,
    lastCriticalSoundAt = 0,
    emergencyFlashRunning = false,
    readyReminderActive = false,
    readyReminderFlashRunning = false,
    lastReadySoundAt = 0,
    readyTestUntil = 0,
    autoDormant = false,
    expectedToggleState = nil,
    expectedToggleUntil = 0,
    localizedPowerName = nil,
    localizedEnergyName = nil,
    uiObscured = false,
    settingsOpenedFromGameMenu = false,
    settingsFragment = nil,
    directSettingsPanelId = nil,
    settingsPages = {},
    settingsNavButtons = {},
    activeSettingsPage = "overload",
}

local COLORS = {
    bg = {0.018, 0.025, 0.045, 0.96},
    panel = {0.028, 0.040, 0.070, 0.98},
    cyan = {0.20, 0.82, 1.00, 1.00},
    cyanDim = {0.10, 0.35, 0.48, 0.85},
    white = {0.94, 0.97, 1.00, 1.00},
    muted = {0.55, 0.64, 0.74, 1.00},
    green = {0.26, 1.00, 0.56, 1.00},
    red = {1.00, 0.29, 0.34, 1.00},
    gold = {0.95, 0.78, 0.32, 1.00},
    orange = {1.00, 0.58, 0.16, 1.00},
}

local function SetColor(control, color)
    control:SetColor(color[1], color[2], color[3], color[4])
end

local function Clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function Normalize(value)
    if not value then return "" end
    return string.lower(tostring(value)):gsub("\\", "/")
end

local function Chat(message)
    d(string.format("|c35D9FF[ĄS Overload]|r %s", tostring(message)))
end

function AOT:OpenWebsite()
    if RequestOpenUnsafeURL then
        RequestOpenUnsafeURL(SITE_URL)
    else
        Chat("Visit the Ąlpha Şquad website: " .. SITE_URL)
    end
end

local function CreateSolid(parent, name, color, left, top, right, bottom)
    local texture = WINDOW_MANAGER:CreateControl(name, parent, CT_TEXTURE)
    texture:SetColor(color[1], color[2], color[3], color[4])
    if left and top and right and bottom then
        texture:SetAnchor(TOPLEFT, parent, TOPLEFT, left, top)
        texture:SetAnchor(BOTTOMRIGHT, parent, BOTTOMRIGHT, right, bottom)
    else
        texture:SetAnchorFill(parent)
    end
    return texture
end

local function CreateLabel(parent, name, font, text, color)
    local label = WINDOW_MANAGER:CreateControl(name, parent, CT_LABEL)
    label:SetFont(font)
    label:SetText(text or "")
    label:SetColor(color[1], color[2], color[3], color[4])
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    return label
end

local function GetMs()
    if GetGameTimeMilliseconds then
        return GetGameTimeMilliseconds()
    end
    return 0
end

function AOT:Debug(message)
    if self.debugEnabled then
        Chat("DEBUG: " .. tostring(message))
    end
end

function AOT:GetDefaultPosition()
    local width = GuiRoot:GetWidth() or 1920
    local height = GuiRoot:GetHeight() or 1080
    return math.floor((width - 330) / 2), math.floor(height * 0.22)
end

function AOT:ResetPosition()
    local x, y = self:GetDefaultPosition()
    self.sv.x = x
    self.sv.y = y
    self.sv.positionSaved = true
    if self.window then
        self.window:ClearAnchors()
        self.window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, x, y)
    end
    self:RefreshSettingsWindow()
end

function AOT:SavePosition()
    if not self.window or not self.sv then return end
    local left = self.window:GetLeft()
    local top = self.window:GetTop()
    if left and top then
        self.sv.x = math.floor(left + 0.5)
        self.sv.y = math.floor(top + 0.5)
    end
end

function AOT:ApplyPosition()
    if not self.window or not self.sv then return end
    self.window:ClearAnchors()
    self.window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.sv.x, self.sv.y)
end

function AOT:UpdateLockState()
    if not self.window or not self.sv then return end

    local movable = not self.sv.locked
    self.window:SetMovable(movable)
    -- Keep the top-level mouse-enabled even while locked so the optional
    -- threshold click-to-stop surface can work. There is no moving handler
    -- when locked, so the HUD still cannot be dragged.
    self.window:SetMouseEnabled(true)

    if self.window.dragSurface then
        self.window.dragSurface:SetMouseEnabled(movable)
    end

    if self.window.moveHint then
        self.window.moveHint:SetHidden(not movable)
    end

    self:UpdateReserveVisual()
end

function AOT:SetLocked(locked)
    locked = locked == true

    if locked then
        self:SavePosition()
        self.sv.positionSaved = true
    end

    self.sv.locked = locked
    self:ApplyVisualSettings()
    self:RefreshSettingsWindow()
end

function AOT:IsPvPContext()
    local inCampaign = IsInCampaign and IsInCampaign() or false
    local inBattleground = IsActiveWorldBattleground and IsActiveWorldBattleground() or false
    local inAvAWorld = IsPlayerInAvAWorld and IsPlayerInAvAWorld() or false
    return inCampaign or inBattleground or inAvAWorld
end

function AOT:IsPvPSuppressed()
    return self.sv and self.sv.disableInPvP == true and self:IsPvPContext()
end

local function SceneIsVisible(scene)
    if not scene or not scene.GetState then return false end
    local state = scene:GetState()
    return state == SCENE_SHOWING or state == SCENE_SHOWN
end

function AOT:RefreshUIObscuredState()
    -- The tracker belongs to gameplay HUD only. Inventory, Champion, Settings,
    -- Crown Store and other full UI scenes hide it automatically.
    local hudVisible = SceneIsVisible(HUD_SCENE) or SceneIsVisible(HUD_UI_SCENE)
    self.uiObscured = not hudVisible
    if self.uiObscured then
        self:SetEmergencyFlashUpdate(false)
        self:SetReadyReminderFlashUpdate(false)
        self.readyReminderActive = false
        self.reserveAlertLevel = "none"
    end
    self:ApplyVisualSettings()
end

function AOT:ApplyBackgroundOpacity()
    if not self.window or not self.sv then return end
    local alpha = Clamp(self.sv.opacity or 95, 30, 100) / 100
    if self.window.bg then self.window.bg:SetAlpha(alpha) end
    -- Keep decorative glow subtle while respecting the background-opacity setting.
    if self.window.glow and self.reserveAlertLevel == "none" and not self.readyReminderActive then
        self.window.glow:SetAlpha(math.max(0.25, alpha))
    end
end

function AOT:ApplyVisualSettings()
    if not self.window or not self.sv then return end
    self.window:SetScale(self.sv.scale / 100)
    -- Opacity affects the background only. Text, icon, borders and status remain
    -- fully readable regardless of the configured background opacity.
    self.window:SetAlpha(1)
    self:ApplyBackgroundOpacity()

    -- Runtime suppression never overwrites the user's own Show/Enable choices.
    -- No slotted Overload, non-HUD game menus, or optional PvP suppression make
    -- the tracker invisible/silent until the context becomes valid again.
    local settingsVisible = self.settingsWindow and not self.settingsWindow:IsHidden() or false
    local hidden = (not self.sv.addonEnabled)
        or (not self.sv.visible)
        or self.autoDormant
        or self.uiObscured
        or settingsVisible
        or self:IsPvPSuppressed()
    self.window:SetHidden(hidden)
    self:UpdateLockState()
end

function AOT:SetAutoDormant(dormant)
    dormant = dormant == true
    if self.autoDormant == dormant then
        if dormant and self.window then
            self.window:SetHidden(true)
        end
        return
    end

    self.autoDormant = dormant

    if dormant then
        -- No Overload is equipped: become completely silent and visually inactive.
        -- Keep only the lightweight slot polling/events alive so we can wake up
        -- automatically when Overload is equipped again (including via subclassing).
        self.isOverloadActive = false
        self.overloadEffectConfirmed = false
        self.slotToggleConfirmed = false
        self.expectedToggleState = nil
        self.expectedToggleUntil = 0
        self.reserveWarning = false
        self.reservePreWarning = false
        self.reserveAlertLevel = "none"
        self.reserveAttempted = false
        self.readyReminderActive = false
        self.readyTestUntil = 0
        self.lastReadySoundAt = 0
        self.lastCriticalSoundAt = 0

        self:SetEmergencyFlashUpdate(false)
        self:SetReadyReminderFlashUpdate(false)

        if self.window then
            self.window:SetHidden(true)
            if self.window.reserveLabel then self.window.reserveLabel:SetHidden(true) end
            if self.window.cancelSurface then
                self.window.cancelSurface:SetMouseEnabled(false)
            end
        end
    else
        -- Overload has been equipped again. Restore the user's saved HUD preference
        -- without producing a chat message.
        self:ApplyVisualSettings()
    end

    self:RefreshSettingsWindow()
end

function AOT:SetAddonEnabled(enabled)
    self.sv.addonEnabled = enabled == true
    self:ApplyVisualSettings()

    if self.sv.addonEnabled then
        self:RefreshOverloadState("addon enabled")
    else
        self:SetOverloadState(false, self.currentVariant)
    end

    self:RefreshSettingsWindow()
end

function AOT:SetTrackerVisible(visible)
    self.sv.visible = visible == true
    self:ApplyVisualSettings()
    self:RefreshSettingsWindow()
end

function AOT:ToggleTrackerVisibility()
    self:SetTrackerVisible(not self.sv.visible)
    Chat(self.sv.visible and "Tracker shown." or "Tracker hidden.")
end

function AOT:GetVariantFromSignature(abilityId, name, icon)
    if abilityId == VARIANTS.power.abilityId then return VARIANTS.power end
    if abilityId == VARIANTS.energy.abilityId then return VARIANTS.energy end

    local normalizedName = Normalize(name)
    local normalizedIcon = Normalize(icon)

    if normalizedIcon:find("ability_sorcerer_power_overload", 1, true) then
        return VARIANTS.power
    end
    if normalizedIcon:find("ability_sorcerer_energy_overload", 1, true) then
        return VARIANTS.energy
    end
    if normalizedIcon:find("ability_sorcerer_overload", 1, true) then
        return VARIANTS.base
    end

    if self.localizedPowerName and normalizedName == Normalize(self.localizedPowerName) then
        return VARIANTS.power
    end
    if self.localizedEnergyName and normalizedName == Normalize(self.localizedEnergyName) then
        return VARIANTS.energy
    end

    if normalizedName == "power overload" then return VARIANTS.power end
    if normalizedName == "energy overload" then return VARIANTS.energy end
    if normalizedName == "overload" then return VARIANTS.base end

    -- Last-resort text matching for internal effect names. Power/Energy checks
    -- happen first so a generic Overload match cannot overwrite the morph.
    if normalizedName:find("power overload", 1, true) then return VARIANTS.power end
    if normalizedName:find("energy overload", 1, true) then return VARIANTS.energy end
    if normalizedName:find("overload", 1, true) then return VARIANTS.base end

    if abilityId and abilityId > 0 then
        local abilityName = GetAbilityName and GetAbilityName(abilityId) or nil
        local abilityIcon = GetAbilityIcon and GetAbilityIcon(abilityId) or nil
        if abilityName ~= name or abilityIcon ~= icon then
            return self:GetVariantFromSignature(nil, abilityName, abilityIcon)
        end
    end

    return nil
end

function AOT:GetVariantFromSlot(category)
    if category == nil or not GetSlotBoundId then return nil end

    -- Strict weapon-bar presence check. Dormancy must be based only on what is
    -- actually assigned to the player's real Primary/Backup Ultimate slot, never
    -- on a temporary/active/Overload hotbar that can outlive the visible loadout.
    if category ~= HOTBAR_CATEGORY_PRIMARY and category ~= HOTBAR_CATEGORY_BACKUP then
        return nil
    end

    -- IMPORTANT: player abilities occupy action slots 3..8; slot 8 is the Ultimate.
    -- ACTION_BAR_ULTIMATE_SLOT_INDEX itself resolves to the base/index value (normally 7),
    -- so ULTIMATE_SLOT above intentionally uses +1.
    if GetSlotType and ACTION_TYPE_ABILITY then
        local slotType = GetSlotType(ULTIMATE_SLOT, category)
        if slotType ~= ACTION_TYPE_ABILITY then
            return nil
        end
    end

    local boundId = GetSlotBoundId(ULTIMATE_SLOT, category)
    if not boundId or boundId <= 0 then
        return nil
    end

    local name = GetSlotName and GetSlotName(ULTIMATE_SLOT, category) or nil
    local texture = GetSlotTexture and GetSlotTexture(ULTIMATE_SLOT, category) or nil
    local effectiveId = boundId

    if boundId and boundId > 0 and GetEffectiveAbilityIdForAbilityOnHotbar then
        local resolved = GetEffectiveAbilityIdForAbilityOnHotbar(boundId, category)
        if resolved and resolved > 0 then
            effectiveId = resolved
        end
    end

    if (not name or name == "") and effectiveId and effectiveId > 0 and GetAbilityName then
        name = GetAbilityName(effectiveId)
    end
    if (not texture or texture == "") and effectiveId and effectiveId > 0 and GetAbilityIcon then
        texture = GetAbilityIcon(effectiveId)
    end

    local variant = self:GetVariantFromSignature(effectiveId, name, texture)
    if not variant and effectiveId ~= boundId then
        variant = self:GetVariantFromSignature(boundId, name, texture)
    end

    return variant, effectiveId or boundId, name, texture
end

function AOT:GetWeaponBarCategories()
    local categories = {}
    if HOTBAR_CATEGORY_PRIMARY ~= nil then
        table.insert(categories, HOTBAR_CATEGORY_PRIMARY)
    end
    if HOTBAR_CATEGORY_BACKUP ~= nil and HOTBAR_CATEGORY_BACKUP ~= HOTBAR_CATEGORY_PRIMARY then
        table.insert(categories, HOTBAR_CATEGORY_BACKUP)
    end
    return categories
end

function AOT:GetPreferredSlottedVariant()
    for _, category in ipairs(self:GetWeaponBarCategories()) do
        local variant = self:GetVariantFromSlot(category)
        if variant then
            self.lastSlottedVariant = variant
            return variant, category
        end
    end

    return self.lastSlottedVariant or VARIANTS.base, nil
end

function AOT:GetActuallySlottedOverloadVariant()
    -- This function intentionally checks ONLY Primary + Backup. Temporary bars,
    -- Werewolf, Overload hotbars and the currently active category do not count as
    -- "slotted" for auto-wake purposes. This prevents a stale Overload context from
    -- keeping the addon alive after the skill has been removed from the build.
    for _, category in ipairs(self:GetWeaponBarCategories()) do
        local variant = self:GetVariantFromSlot(category)
        if variant then
            self.lastSlottedVariant = variant
            return variant, category
        end
    end

    return nil, nil
end

function AOT:GetAnyToggledOverload()
    if not IsSlotToggled then return nil, nil end

    local found = false
    for _, category in ipairs(self:GetWeaponBarCategories()) do
        local variant = self:GetVariantFromSlot(category)
        if variant then
            found = true
            if IsSlotToggled(ULTIMATE_SLOT, category) then
                self.slotToggleConfirmed = true
                return true, variant
            end
        end
    end

    if found and self.slotToggleConfirmed then
        return false, self:GetPreferredSlottedVariant()
    end

    return nil, self:GetPreferredSlottedVariant()
end

function AOT:FindActiveOverloadBuff()
    local numBuffs = GetNumBuffs("player") or 0
    for index = 1, numBuffs do
        local buffName, timeStarted, timeEnding, buffSlot, stackCount, iconFilename,
              deprecatedBuffType, effectType, abilityType, statusEffectType,
              abilityId, canClickOff, castByPlayer = GetUnitBuffInfo("player", index)

        local variant = self:GetVariantFromSignature(abilityId, buffName, iconFilename)
        if variant then
            return true, {
                index = index,
                buffName = buffName,
                timeStarted = timeStarted,
                timeEnding = timeEnding,
                buffSlot = buffSlot,
                stackCount = stackCount,
                icon = iconFilename,
                abilityId = abilityId,
                canClickOff = canClickOff == true,
                castByPlayer = castByPlayer,
                variant = variant,
            }
        end
    end
    return false, nil
end

function AOT:GetUltimatePower()
    if not GetUnitPower or not ULTIMATE_POWER_TYPE then return 0, 0, 0 end
    local current, maximum, effectiveMaximum = GetUnitPower("player", ULTIMATE_POWER_TYPE)
    return tonumber(current) or 0, tonumber(maximum) or 0, tonumber(effectiveMaximum) or 0
end

function AOT:SetDisplayedVariant(variant)
    variant = variant or self:GetPreferredSlottedVariant() or VARIANTS.base
    self.currentVariant = variant

    if self.window then
        self.window.title:SetText(variant.title)
        self.window.icon:SetTexture(variant.icon)
    end
end

function AOT:GetReserveAlertLevel(currentUltimate)
    if not self.sv or self.uiObscured or self:IsPvPSuppressed() or not self.sv.reserveCutoffEnabled or not self.isOverloadActive then
        return "none"
    end

    local current = tonumber(currentUltimate)
    if current == nil then
        current = select(1, self:GetUltimatePower())
    end

    local threshold = tonumber(self.sv.reserveThreshold) or 130
    local alertThreshold = tonumber(self.sv.reserveWarningThreshold) or 160
    if alertThreshold < threshold then alertThreshold = threshold end

    if current <= threshold then
        return "critical"
    elseif current <= alertThreshold then
        return "warning"
    end

    return "none"
end

function AOT:GetReadyReminderEligible(currentUltimate)
    if not self.sv or not self.sv.addonEnabled or self.uiObscured or self:IsPvPSuppressed() or not self.sv.readyReminderEnabled or self.isOverloadActive then
        return false, nil
    end

    -- Built-in visual/sound test. This is deliberately independent of current Ultimate,
    -- but still stops immediately if Overload is switched ON.
    if (self.readyTestUntil or 0) > GetMs() then
        local testVariant = self:GetActuallySlottedOverloadVariant() or self.currentVariant or VARIANTS.base
        return true, testVariant
    end

    local current = tonumber(currentUltimate)
    if current == nil then
        current = select(1, self:GetUltimatePower())
    end

    local threshold = tonumber(self.sv.readyReminderThreshold) or 400
    if current < threshold then
        return false, nil
    end

    -- Do not rely on a cached morph here. The reminder must confirm that an Overload
    -- variant is really in the Ultimate slot of Primary or Backup right now.
    local variant, category = self:GetActuallySlottedOverloadVariant()
    if not variant then
        self:Debug(string.format("ready blocked: ULT=%d >= %d but no Overload found in slot %d", current, threshold, ULTIMATE_SLOT))
        return false, nil
    end

    self:Debug(string.format("ready eligible: ULT=%d >= %d | %s | bar=%s | slot=%d",
        current, threshold, variant.title, tostring(category), ULTIMATE_SLOT))
    return true, variant
end

function AOT:SetEmergencyFlashUpdate(enabled)
    local updateName = ADDON_NAME .. "_EmergencyFlash"
    if enabled and not self.emergencyFlashRunning then
        self.emergencyFlashRunning = true
        EVENT_MANAGER:RegisterForUpdate(updateName, 70, function()
            if not AOT.sv or not AOT.sv.addonEnabled or AOT:IsPvPSuppressed() or AOT.uiObscured or not AOT.sv.reserveCutoffEnabled or not AOT.isOverloadActive or AOT.reserveAlertLevel == "none" then
                AOT:SetEmergencyFlashUpdate(false)
                return
            end
            local current = select(1, AOT:GetUltimatePower())
            AOT:ApplyReserveAlertVisual(AOT.reserveAlertLevel, current)
        end)
    elseif not enabled and self.emergencyFlashRunning then
        self.emergencyFlashRunning = false
        EVENT_MANAGER:UnregisterForUpdate(updateName)
    end
end

function AOT:SetReadyReminderFlashUpdate(enabled)
    local updateName = ADDON_NAME .. "_ReadyReminderFlash"
    if enabled and not self.readyReminderFlashRunning then
        self.readyReminderFlashRunning = true
        EVENT_MANAGER:RegisterForUpdate(updateName, 160, function()
            if not AOT.sv or not AOT.sv.addonEnabled or AOT:IsPvPSuppressed() or AOT.uiObscured or not AOT.sv.readyReminderEnabled or AOT.isOverloadActive then
                AOT:SetReadyReminderFlashUpdate(false)
                return
            end

            local current = select(1, AOT:GetUltimatePower())
            local eligible, variant = AOT:GetReadyReminderEligible(current)
            if not eligible then
                AOT.readyReminderActive = false
                AOT:SetReadyReminderFlashUpdate(false)
                AOT:ApplyReserveAlertVisual("none", current)
                return
            end

            if variant then AOT:SetDisplayedVariant(variant) end
            AOT:PlayReadyReminder(false)
            AOT:ApplyReadyReminderVisual(current)
        end)
    elseif not enabled and self.readyReminderFlashRunning then
        self.readyReminderFlashRunning = false
        EVENT_MANAGER:UnregisterForUpdate(updateName)
    end
end

function AOT:PlayReadyReminder(force)
    if not self.sv or self:IsPvPSuppressed() or not self.sv.readyReminderSound or not PlaySound or not SOUNDS then return end

    local now = GetMs()
    local repeatDelay = 12000
    if not force and (now - (self.lastReadySoundAt or 0)) < repeatDelay then
        return
    end
    self.lastReadySoundAt = now

    local first = SOUNDS.GENERAL_ALERT_NOTIFICATION or SOUNDS.POSITIVE_CLICK or SOUNDS.DEFAULT_CLICK
    local second = SOUNDS.POSITIVE_CLICK or SOUNDS.GENERAL_ALERT_NOTIFICATION or first
    if first then PlaySound(first) end

    if second then
        zo_callLater(function()
            local current = select(1, AOT:GetUltimatePower())
            local eligible = AOT:GetReadyReminderEligible(current)
            if eligible and AOT.sv and AOT.sv.readyReminderSound then
                PlaySound(second)
            end
        end, 180)
    end
end

function AOT:ApplyReadyReminderVisual(current)
    if not self.window or not self.sv then return end

    local window = self.window
    local now = GetMs()
    local wave = (math.sin(now / 430) + 1) / 2
    local baseScale = (self.sv.scale or 100) / 100
    local baseAlpha = (self.sv.opacity or 95) / 100
    local pulseScale = 1 + (0.018 * wave)
    local pulseAlpha = math.min(1, baseAlpha + (0.08 * wave))
    local glowAlpha = 0.08 + (0.13 * wave)
    local lineAlpha = 0.55 + (0.45 * wave)

    window:SetScale(baseScale * pulseScale)
    window:SetAlpha(1)
    if window.bg then window.bg:SetAlpha(pulseAlpha) end

    if window.alertOverlay then
        window.alertOverlay:SetHidden(false)
        window.alertOverlay:SetColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 0.025 + (0.045 * wave))
    end
    if window.bg then
        window.bg:SetColor(0.018, 0.032 + (0.012 * wave), 0.050 + (0.016 * wave), 0.97)
    end
    if window.glow then
        window.glow:SetColor(COLORS.cyan[1], COLORS.cyan[2], COLORS.cyan[3], glowAlpha)
    end
    if window.topLine then
        window.topLine:SetColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], lineAlpha)
    end
    if window.bottomLine then
        window.bottomLine:SetColor(COLORS.cyan[1], COLORS.cyan[2], COLORS.cyan[3], 0.35 + (0.35 * wave))
    end
    if window.rightBar then window.rightBar:SetHidden(true) end

    window.statusBar:SetColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 0.78 + (0.22 * wave))
    window.statusGlow:SetColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 0.10 + (0.16 * wave))
    window.iconBorder:SetColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 0.72 + (0.28 * wave))
    window.statusLabel:SetText("READY TO ACTIVATE")
    window.statusLabel:SetColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 0.80 + (0.20 * wave))

    if window.icon then window.icon:SetAlpha(0.88 + (0.12 * wave)) end
    if window.title then window.title:SetColor(COLORS.white[1], COLORS.white[2], COLORS.white[3], 1) end
    if window.brand then window.brand:SetColor(COLORS.cyan[1], COLORS.cyan[2], COLORS.cyan[3], 0.82 + (0.18 * wave)) end

    -- During READY TO ACTIVATE, keep the HUD focused on the reminder itself.
    -- The permanent Ultimate counter is intentionally hidden in alert/reminder modes.
    if window.reserveLabel then
        window.reserveLabel:SetHidden(true)
    end
end

function AOT:ApplyReserveAlertVisual(level, current)
    if not self.window then return end

    local window = self.window
    local now = GetMs()
    local baseStateColor = self.isOverloadActive and COLORS.green or COLORS.red
    local isCritical = level == "critical"
    local isEmergency = level == "warning" or isCritical
    local interval = isCritical and 55 or 85
    local phase = math.floor(now / interval) % 6
    local flashWhite = phase == 1 or phase == 4
    local flashHard = phase == 0 or phase == 2 or phase == 4
    local emergencyColor = flashWhite and COLORS.white or COLORS.red

    if isEmergency then
        local baseScale = (self.sv and self.sv.scale or 100) / 100
        local pulseScale
        if isCritical then
            pulseScale = (phase % 2 == 0) and 1.065 or 0.955
        else
            pulseScale = (phase % 2 == 0) and 1.040 or 0.975
        end
        window:SetScale(baseScale * pulseScale)
        window:SetAlpha(1)
        if window.bg then window.bg:SetAlpha(1) end

        local overlayAlpha
        if isCritical then
            overlayAlpha = flashWhite and 0.42 or (flashHard and 0.58 or 0.16)
        else
            overlayAlpha = flashWhite and 0.24 or (flashHard and 0.42 or 0.10)
        end

        if window.alertOverlay then
            window.alertOverlay:SetHidden(false)
            window.alertOverlay:SetColor(emergencyColor[1], emergencyColor[2], emergencyColor[3], overlayAlpha)
        end
        if window.bg then
            if flashWhite then
                window.bg:SetColor(0.16, 0.02, 0.025, 0.98)
            elseif flashHard then
                window.bg:SetColor(0.24, 0.01, 0.02, 0.99)
            else
                window.bg:SetColor(0.06, 0.012, 0.018, 0.98)
            end
        end
        if window.glow then
            window.glow:SetColor(COLORS.red[1], COLORS.red[2], COLORS.red[3], flashHard and 0.48 or 0.18)
        end
        if window.topLine then window.topLine:SetColor(emergencyColor[1], emergencyColor[2], emergencyColor[3], 1) end
        if window.bottomLine then window.bottomLine:SetColor(emergencyColor[1], emergencyColor[2], emergencyColor[3], flashHard and 1 or 0.45) end
        if window.rightBar then
            window.rightBar:SetHidden(false)
            window.rightBar:SetColor(emergencyColor[1], emergencyColor[2], emergencyColor[3], flashHard and 1 or 0.35)
        end
        window.statusBar:SetColor(emergencyColor[1], emergencyColor[2], emergencyColor[3], 1)
        window.statusGlow:SetColor(COLORS.red[1], COLORS.red[2], COLORS.red[3], flashHard and 0.78 or 0.20)
        window.iconBorder:SetColor(emergencyColor[1], emergencyColor[2], emergencyColor[3], 1)
        window.statusLabel:SetColor(emergencyColor[1], emergencyColor[2], emergencyColor[3], 1)
        if window.icon then window.icon:SetAlpha(flashWhite and 0.45 or 1) end
        if window.title then window.title:SetColor(emergencyColor[1], emergencyColor[2], emergencyColor[3], 1) end
        if window.brand then window.brand:SetColor(emergencyColor[1], emergencyColor[2], emergencyColor[3], flashHard and 1 or 0.50) end

        if window.reserveLabel then
            -- No numeric Ultimate counter during reserve alarms. The alert gets the
            -- entire right-side message area so the player only sees the action cue.
            window.reserveLabel:SetHidden(false)
            window.reserveLabel:SetText("TURN OFF!")
            window.reserveLabel:SetColor(emergencyColor[1], emergencyColor[2], emergencyColor[3], 1)
        end
    else
        if self.sv then
            window:SetScale((self.sv.scale or 100) / 100)
            window:SetAlpha(1)
        end
        if window.alertOverlay then window.alertOverlay:SetHidden(true) end
        if window.bg then
            window.bg:SetColor(COLORS.bg[1], COLORS.bg[2], COLORS.bg[3], COLORS.bg[4])
            window.bg:SetAlpha((self.sv and self.sv.opacity or 95) / 100)
        end
        if window.glow then window.glow:SetColor(COLORS.cyan[1], COLORS.cyan[2], COLORS.cyan[3], 0.07) end
        if window.topLine then window.topLine:SetColor(COLORS.cyan[1], COLORS.cyan[2], COLORS.cyan[3], 1) end
        if window.bottomLine then window.bottomLine:SetColor(COLORS.cyanDim[1], COLORS.cyanDim[2], COLORS.cyanDim[3], 0.75) end
        if window.rightBar then window.rightBar:SetHidden(true) end
        window.statusBar:SetColor(baseStateColor[1], baseStateColor[2], baseStateColor[3], 1)
        window.statusGlow:SetColor(baseStateColor[1], baseStateColor[2], baseStateColor[3], self.isOverloadActive and 0.20 or 0.09)
        window.iconBorder:SetColor(baseStateColor[1], baseStateColor[2], baseStateColor[3], self.isOverloadActive and 0.95 or 0.55)
        window.statusLabel:SetText(self.isOverloadActive and "OVERLOAD ON" or "OVERLOAD OFF")
        window.statusLabel:SetColor(baseStateColor[1], baseStateColor[2], baseStateColor[3], 1)
        if window.icon then window.icon:SetAlpha(1) end
        if window.title then window.title:SetColor(COLORS.white[1], COLORS.white[2], COLORS.white[3], 1) end
        if window.brand then window.brand:SetColor(COLORS.cyan[1], COLORS.cyan[2], COLORS.cyan[3], 1) end
        if window.reserveLabel and not self.autoDormant then
            window.reserveLabel:SetHidden(false)
            window.reserveLabel:SetText(string.format("ULT %d", tonumber(current) or 0))
            window.reserveLabel:SetColor(COLORS.muted[1], COLORS.muted[2], COLORS.muted[3], 1)
        end
    end
end

function AOT:UpdateReserveVisual(currentUltimate)
    if not self.window or not self.sv then return end

    local current = tonumber(currentUltimate)
    if current == nil then
        current = select(1, self:GetUltimatePower())
    end

    local unlocked = not self.sv.locked
    if self.window.moveHint then
        self.window.moveHint:SetHidden(not unlocked)
    end

    local level = self:GetReserveAlertLevel(current)
    local readyEligible, readyVariant = false, nil
    if level == "none" then
        readyEligible, readyVariant = self:GetReadyReminderEligible(current)
    end

    if readyEligible and readyVariant then
        self:SetDisplayedVariant(readyVariant)
    end

    if readyEligible then
        if not self.readyReminderActive then
            self.readyReminderActive = true
            self.lastReadySoundAt = 0
            self:PlayReadyReminder(true)
        else
            self:PlayReadyReminder(false)
        end
    elseif self.readyReminderActive then
        self.readyReminderActive = false
        self.lastReadySoundAt = 0
    end

    if self.window.reserveLabel then
        -- Permanent Ultimate counter in the normal tracker state, regardless of
        -- Overload ON/OFF and regardless of lock state. Alert/reminder visuals below
        -- temporarily take over this area and suppress the numeric counter.
        local normalCounter = (level == "none") and (not readyEligible) and (not self.autoDormant)
        self.window.reserveLabel:SetHidden(not normalCounter)
        if normalCounter then
            self.window.reserveLabel:SetText(string.format("ULT %d", current))
            SetColor(self.window.reserveLabel, COLORS.muted)
        end
    end

    if self.window.cancelSurface then
        -- Manual click-to-stop is only relevant when locked and critically low.
        self.window.cancelSurface:SetMouseEnabled((not unlocked) and level == "critical" and self.isOverloadActive)
    end

    local emergencyActive = level ~= "none" and self.isOverloadActive
    self:SetEmergencyFlashUpdate(emergencyActive)
    self:SetReadyReminderFlashUpdate(readyEligible and not emergencyActive)

    if emergencyActive then
        self.readyReminderActive = false
        self:SetReadyReminderFlashUpdate(false)
        self:ApplyReserveAlertVisual(level, current)
    elseif readyEligible then
        self:ApplyReadyReminderVisual(current)
    else
        self:ApplyReserveAlertVisual("none", current)
    end
end

function AOT:SetOverloadState(active, variant)
    active = active == true
    if variant then self:SetDisplayedVariant(variant) end

    local changed = self.isOverloadActive ~= active
    self.isOverloadActive = active

    if active then
        self.readyReminderActive = false
        self.lastReadySoundAt = 0
        self:SetReadyReminderFlashUpdate(false)
    end

    if not active then
        self.reserveWarning = false
        self.reservePreWarning = false
        self.reserveAlertLevel = "none"
        self.reserveAttempted = false
        self.expectedToggleState = nil
        self:SetEmergencyFlashUpdate(false)
    end

    if not self.window then return end

    local stateColor = active and COLORS.green or COLORS.red
    self.window.stateInitialized = true
    self.window.statusLabel:SetText(active and "OVERLOAD ON" or "OVERLOAD OFF")
    self.window.statusLabel:SetColor(stateColor[1], stateColor[2], stateColor[3], 1)
    self.window.statusBar:SetColor(stateColor[1], stateColor[2], stateColor[3], 1)
    self.window.statusGlow:SetColor(stateColor[1], stateColor[2], stateColor[3], active and 0.20 or 0.09)
    self.window.iconBorder:SetColor(stateColor[1], stateColor[2], stateColor[3], active and 0.95 or 0.55)

    if changed then
        self:Debug((active and "ON: " or "OFF: ") .. (self.currentVariant and self.currentVariant.title or "OVERLOAD"))
    end

    self:UpdateReserveVisual()
end

function AOT:PlayPreWarningAlert()
    -- Kept for backward compatibility with older internal calls.
    self:PlayReserveAlert(true, "warning")
end

function AOT:PlayReserveAlert(force, requestedLevel)
    if not self.sv or self.uiObscured or self:IsPvPSuppressed() or not self.sv.reserveSound or not PlaySound or not SOUNDS then return end

    local level = requestedLevel or self.reserveAlertLevel or "warning"
    local now = GetMs()
    local repeatDelay = level == "critical" and 430 or 680
    if not force and (now - (self.lastCriticalSoundAt or 0)) < repeatDelay then
        return
    end
    self.lastCriticalSoundAt = now

    local primary = SOUNDS.GENERAL_ALERT_ERROR or SOUNDS.NEGATIVE_CLICK or SOUNDS.DUEL_START or SOUNDS.GENERAL_ALERT_NOTIFICATION
    local secondary = SOUNDS.DUEL_START or SOUNDS.NEGATIVE_CLICK or primary
    local tertiary = SOUNDS.NEGATIVE_CLICK or SOUNDS.GENERAL_ALERT_NOTIFICATION or primary
    if not primary then return end

    -- ESO exposes no per-addon volume multiplier. A rapid layered burst makes the
    -- warning much harder to ignore while still respecting the player's UI/SFX volume.
    local sequence
    if level == "critical" then
        sequence = {
            {0, primary}, {55, secondary}, {110, primary}, {165, tertiary},
            {225, primary}, {285, secondary}, {345, primary},
        }
    else
        sequence = {
            {0, primary}, {80, secondary}, {160, primary}, {245, tertiary},
        }
    end

    for _, pulse in ipairs(sequence) do
        local delay, soundId = pulse[1], pulse[2]
        if soundId then
            zo_callLater(function()
                if AOT.sv and not AOT.uiObscured and not AOT:IsPvPSuppressed() and AOT.sv.reserveSound and AOT.isOverloadActive and AOT.reserveAlertLevel ~= "none" then
                    PlaySound(soundId)
                end
            end, delay)
        end
    end
end

function AOT:TryCancelOverload(reason, announceFailure)
    local active, info = self:FindActiveOverloadBuff()
    if not active or not info then
        if announceFailure then
            Chat("No active Overload effect was found to cancel.")
        end
        return false, "no active effect"
    end

    self:SetDisplayedVariant(info.variant)

    if not info.canClickOff then
        if announceFailure then
            Chat(info.variant.title .. " is active, but ESO does not expose this effect as click-off cancellable. Press your Ultimate key to toggle it off.")
        end
        return false, "effect is not click-off cancellable"
    end

    if not CancelBuff then
        if announceFailure then
            Chat("CancelBuff is unavailable on this client. Press your Ultimate key to toggle Overload off.")
        end
        return false, "CancelBuff unavailable"
    end

    CancelBuff(info.index)
    self:Debug(string.format("CancelBuff(%d) requested (%s)", info.index, tostring(reason or "manual")))

    zo_callLater(function()
        AOT:RefreshOverloadState("post cancel 80ms")
    end, 80)
    zo_callLater(function()
        local stillActive = AOT:FindActiveOverloadBuff()
        AOT:RefreshOverloadState("post cancel verify")
        if stillActive and reason == "auto reserve" then
            -- Keep reserve handling visual/audio only. No automatic chat spam.
            AOT:PlayReserveAlert(false)
        end
    end, 220)

    return true, "cancel requested"
end

function AOT:CheckReserveCutoff(currentUltimate)
    if not self.sv or not self.sv.addonEnabled then return end

    local current = tonumber(currentUltimate)
    if current == nil then
        current = select(1, self:GetUltimatePower())
    end

    local oldLevel = self.reserveAlertLevel or "none"

    if not self.sv.reserveCutoffEnabled or not self.isOverloadActive then
        self.reserveWarning = false
        self.reservePreWarning = false
        self.reserveAlertLevel = "none"
        if not self.isOverloadActive then self.reserveAttempted = false end
        self:UpdateReserveVisual(current)
        return
    end

    local threshold = tonumber(self.sv.reserveThreshold) or 130
    local alertThreshold = tonumber(self.sv.reserveWarningThreshold) or 160
    if alertThreshold < threshold then alertThreshold = threshold end
    local newLevel = "none"

    if current <= threshold then
        newLevel = "critical"
    elseif current <= alertThreshold then
        newLevel = "warning"
    end

    self.reserveAlertLevel = newLevel
    self.reserveWarning = newLevel == "critical"
    self.reservePreWarning = newLevel == "warning"

    if newLevel == "none" then
        self.reserveAttempted = false
    elseif newLevel == "warning" then
        self.reserveAttempted = false
        -- Emergency alarm begins at the warning threshold (160 by default) and repeats.
        self:PlayReserveAlert(oldLevel == "none", "warning")
    elseif newLevel == "critical" then
        -- At/below the auto-stop threshold the alarm becomes even faster and the
        -- addon attempts the public CancelBuff route when ESO permits it.
        self:PlayReserveAlert(oldLevel ~= "critical", "critical")

        if not self.reserveAttempted then
            self.reserveAttempted = true
            self:TryCancelOverload("auto reserve", false)
        end
    end

    self:UpdateReserveVisual(current)
end

function AOT:RefreshOverloadState(reason)
    if not self.window or not self.sv or not self.sv.addonEnabled then return end

    -- Slot presence is the master context switch. Do not class-gate this addon:
    -- subclassing can make an Overload skill relevant outside a Sorcerer build.
    -- If no tracked Overload morph is in the Ultimate slot of either weapon bar,
    -- the tracker becomes dormant, hidden and silent until one is equipped again.
    local slottedVariant = self:GetActuallySlottedOverloadVariant()
    if not slottedVariant then
        self:SetAutoDormant(true)
        return
    end

    if self.autoDormant then
        self:SetAutoDormant(false)
    end

    self:SetDisplayedVariant(slottedVariant)

    if self:IsPvPSuppressed() then
        self.reserveAlertLevel = "none"
        self.readyReminderActive = false
        self:SetEmergencyFlashUpdate(false)
        self:SetReadyReminderFlashUpdate(false)
        self:ApplyVisualSettings()
        return
    end

    -- Primary signal: the actual active player effect.
    local buffActive, buffInfo = self:FindActiveOverloadBuff()
    if buffActive and buffInfo then
        self.overloadEffectConfirmed = true
        self:SetOverloadState(true, buffInfo.variant)
        self:Debug(string.format("buff active id=%s name=%s", tostring(buffInfo.abilityId), tostring(buffInfo.buffName)))
        self:CheckReserveCutoff()
        return
    end

    -- Secondary signal: the native toggle flag on either weapon bar.
    local slotState, slotVariant = self:GetAnyToggledOverload()
    if slotState == true then
        self:SetOverloadState(true, slotVariant)
        self:Debug("IsSlotToggled = true")
        self:CheckReserveCutoff()
        return
    elseif slotState == false then
        self:SetOverloadState(false, slotVariant)
        self:Debug("IsSlotToggled = false (confirmed)")
        return
    end

    -- Immediate feedback grace after EVENT_ACTION_SLOT_ABILITY_USED. This avoids
    -- a one-frame OFF flash while the effect/toggle API catches up.
    if self.expectedToggleState ~= nil and GetMs() < self.expectedToggleUntil then
        self:SetOverloadState(self.expectedToggleState, self.currentVariant)
        self:CheckReserveCutoff()
        return
    end

    -- Once ESO has positively shown us the Overload effect during this session,
    -- its absence is meaningful and can turn the HUD off.
    if self.overloadEffectConfirmed and self.isOverloadActive then
        self:SetOverloadState(false, self.currentVariant)
        return
    end

    -- Resource exhaustion safety.
    local currentUltimate = select(1, self:GetUltimatePower())
    if self.isOverloadActive and currentUltimate <= 0 then
        self:SetOverloadState(false, self.currentVariant)
        return
    end

    self:UpdateReserveVisual(currentUltimate)
end

function AOT:OnEffectChanged(_, changeType, _, effectName, unitTag, _, _, _, iconName, _, _, _, _, _, _, abilityId)
    if not self.sv or not self.sv.addonEnabled or self.autoDormant or unitTag ~= "player" then return end

    local variant = self:GetVariantFromSignature(abilityId, effectName, iconName)
    if not variant then return end

    self.overloadEffectConfirmed = true
    self:SetDisplayedVariant(variant)

    if changeType == EFFECT_RESULT_GAINED or
       changeType == EFFECT_RESULT_UPDATED or
       changeType == EFFECT_RESULT_FULL_REFRESH or
       changeType == EFFECT_RESULT_TRANSFER then
        self.expectedToggleState = nil
        self:SetOverloadState(true, variant)
        self:CheckReserveCutoff()
        self:Debug(string.format("effect gained/updated id=%s name=%s", tostring(abilityId), tostring(effectName)))
    elseif changeType == EFFECT_RESULT_FADED then
        self:Debug(string.format("effect faded id=%s name=%s", tostring(abilityId), tostring(effectName)))
        zo_callLater(function() AOT:RefreshOverloadState("effect faded") end, 30)
    end
end

function AOT:OnActionSlotAbilityUsed(_, slotNum)
    if not self.sv or not self.sv.addonEnabled or self.autoDormant or slotNum ~= ULTIMATE_SLOT then return end

    -- Never wake/toggle from a temporary active hotbar. First prove that Overload
    -- is actually equipped on one of the two real weapon bars.
    local slottedVariant = self:GetActuallySlottedOverloadVariant()
    if not slottedVariant then
        self:SetAutoDormant(true)
        return
    end

    local activeCategory = GetActiveHotbarCategory and GetActiveHotbarCategory() or nil
    local variant = nil
    if activeCategory == HOTBAR_CATEGORY_PRIMARY or activeCategory == HOTBAR_CATEGORY_BACKUP then
        variant = self:GetVariantFromSlot(activeCategory)
    end
    variant = variant or slottedVariant

    self:SetDisplayedVariant(variant)
    self.expectedToggleState = not self.isOverloadActive
    self.expectedToggleUntil = GetMs() + 700
    self:SetOverloadState(self.expectedToggleState, variant)
    self:Debug("Overload ultimate slot used; expected state toggled")

    zo_callLater(function() AOT:RefreshOverloadState("ultimate used 40ms") end, 40)
    zo_callLater(function() AOT:RefreshOverloadState("ultimate used 180ms") end, 180)
    zo_callLater(function() AOT:RefreshOverloadState("ultimate used 500ms") end, 500)
end

function AOT:OnPowerUpdate(_, unitTag, _, powerType, powerValue)
    if unitTag ~= "player" or not self.sv or not self.sv.addonEnabled or self.autoDormant or self:IsPvPSuppressed() or self.uiObscured then return end
    if ULTIMATE_POWER_TYPE and powerType ~= ULTIMATE_POWER_TYPE then return end

    self:UpdateReserveVisual(powerValue)
    if self.isOverloadActive then
        self:CheckReserveCutoff(powerValue)
    end
end

function AOT:PrintDiagnostics()
    Chat("Overload diagnostics:")
    Chat(string.format("Ultimate action slot: %d (ACTION_BAR_ULTIMATE_SLOT_INDEX=%s)", ULTIMATE_SLOT, tostring(ACTION_BAR_ULTIMATE_SLOT_INDEX)))

    local categories = {
        { "PRIMARY", HOTBAR_CATEGORY_PRIMARY },
        { "BACKUP", HOTBAR_CATEGORY_BACKUP },
    }

    for _, entry in ipairs(categories) do
        local label, category = entry[1], entry[2]
        if category ~= nil then
            local variant, id, name, texture = self:GetVariantFromSlot(category)
            local toggled = IsSlotToggled and IsSlotToggled(ULTIMATE_SLOT, category) or false
            Chat(string.format("%s ultimate: id=%s | name=%s | morph=%s | toggled=%s | icon=%s",
                label, tostring(id), tostring(name), variant and variant.title or "NOT OVERLOAD", tostring(toggled), tostring(texture)))
        end
    end

    local active, info = self:FindActiveOverloadBuff()
    if active and info then
        Chat(string.format("Active effect: id=%s | name=%s | morph=%s | canClickOff=%s | icon=%s",
            tostring(info.abilityId), tostring(info.buffName), info.variant.title, tostring(info.canClickOff), tostring(info.icon)))
    else
        Chat("No active Overload player effect found.")
    end

    local current = select(1, self:GetUltimatePower())
    Chat(string.format("Tracker: %s | Morph: %s | Ultimate: %d | Emergency: %s @ %d | Auto-stop: %d | Ready reminder: %s @ %d",
        self.isOverloadActive and "ON" or "OFF",
        self.currentVariant and self.currentVariant.title or "OVERLOAD",
        current,
        self.sv.reserveCutoffEnabled and "ON" or "OFF",
        self.sv.reserveWarningThreshold,
        self.sv.reserveThreshold,
        self.sv.readyReminderEnabled and "ON" or "OFF",
        self.sv.readyReminderThreshold))
end

function AOT:CreateTrackerWindow()
    local window = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadOverloadTrackerWindow")
    self.window = window

    window:SetDimensions(330, 82)
    window:SetClampedToScreen(true)
    window:SetDrawTier(DT_HIGH)
    window:SetDrawLayer(DL_OVERLAY)
    window:SetDrawLevel(20)

    window.bg = CreateSolid(window, "AlphaSquadOverloadTrackerBG", COLORS.bg)
    window.glow = CreateSolid(window, "AlphaSquadOverloadTrackerGlow", {COLORS.cyan[1], COLORS.cyan[2], COLORS.cyan[3], 0.07}, 1, 1, -1, -1)
    window.alertOverlay = CreateSolid(window, "AlphaSquadOverloadTrackerAlertOverlay", {1, 0, 0, 0.0}, 1, 1, -1, -1)
    window.alertOverlay:SetHidden(true)

    local topLine = WINDOW_MANAGER:CreateControl("AlphaSquadOverloadTrackerTopLine", window, CT_TEXTURE)
    topLine:SetAnchor(TOPLEFT, window, TOPLEFT, 0, 0)
    topLine:SetAnchor(TOPRIGHT, window, TOPRIGHT, 0, 0)
    topLine:SetHeight(2)
    SetColor(topLine, COLORS.cyan)
    window.topLine = topLine

    local bottomLine = WINDOW_MANAGER:CreateControl("AlphaSquadOverloadTrackerBottomLine", window, CT_TEXTURE)
    bottomLine:SetAnchor(BOTTOMLEFT, window, BOTTOMLEFT, 0, 0)
    bottomLine:SetAnchor(BOTTOMRIGHT, window, BOTTOMRIGHT, 0, 0)
    bottomLine:SetHeight(1)
    bottomLine:SetColor(COLORS.cyanDim[1], COLORS.cyanDim[2], COLORS.cyanDim[3], 0.75)
    window.bottomLine = bottomLine

    local statusBar = WINDOW_MANAGER:CreateControl("AlphaSquadOverloadTrackerStatusBar", window, CT_TEXTURE)
    statusBar:SetDimensions(5, 66)
    statusBar:SetAnchor(LEFT, window, LEFT, 6, 1)
    window.statusBar = statusBar

    local statusGlow = WINDOW_MANAGER:CreateControl("AlphaSquadOverloadTrackerStatusGlow", window, CT_TEXTURE)
    statusGlow:SetDimensions(12, 72)
    statusGlow:SetAnchor(LEFT, window, LEFT, 2, 1)
    window.statusGlow = statusGlow

    local rightBar = WINDOW_MANAGER:CreateControl("AlphaSquadOverloadTrackerRightBar", window, CT_TEXTURE)
    rightBar:SetDimensions(5, 66)
    rightBar:SetAnchor(RIGHT, window, RIGHT, -6, 1)
    rightBar:SetColor(COLORS.red[1], COLORS.red[2], COLORS.red[3], 1)
    rightBar:SetHidden(true)
    window.rightBar = rightBar

    local iconBorder = WINDOW_MANAGER:CreateControl("AlphaSquadOverloadTrackerIconBorder", window, CT_TEXTURE)
    iconBorder:SetDimensions(54, 54)
    iconBorder:SetAnchor(LEFT, window, LEFT, 18, 1)
    window.iconBorder = iconBorder

    local iconBg = WINDOW_MANAGER:CreateControl("AlphaSquadOverloadTrackerIconBG", window, CT_TEXTURE)
    iconBg:SetDimensions(50, 50)
    iconBg:SetAnchor(CENTER, iconBorder, CENTER, 0, 0)
    iconBg:SetColor(0.01, 0.015, 0.025, 1)

    local icon = WINDOW_MANAGER:CreateControl("AlphaSquadOverloadTrackerIcon", window, CT_TEXTURE)
    icon:SetDimensions(46, 46)
    icon:SetAnchor(CENTER, iconBorder, CENTER, 0, 0)
    icon:SetTexture(VARIANTS.base.icon)
    icon:SetTextureCoords(0.05, 0.95, 0.05, 0.95)
    window.icon = icon

    local brand = CreateLabel(window, "AlphaSquadOverloadTrackerBrand", "ZoFontGameSmall", "ĄLPHA ŞQUAD", COLORS.cyan)
    brand:SetDimensions(128, 17)
    brand:SetAnchor(TOPLEFT, window, TOPLEFT, 82, 8)
    brand:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    window.brand = brand

    local title = CreateLabel(window, "AlphaSquadOverloadTrackerTitle", "ZoFontWinH4", "OVERLOAD", COLORS.white)
    title:SetDimensions(235, 24)
    title:SetAnchor(TOPLEFT, window, TOPLEFT, 81, 24)
    title:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    window.title = title

    local statusLabel = CreateLabel(window, "AlphaSquadOverloadTrackerStatusLabel", "ZoFontGameBold", "OVERLOAD OFF", COLORS.red)
    statusLabel:SetDimensions(125, 20)
    statusLabel:SetAnchor(TOPLEFT, window, TOPLEFT, 82, 52)
    statusLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    window.statusLabel = statusLabel

    local reserveLabel = CreateLabel(window, "AlphaSquadOverloadTrackerReserveLabel", "ZoFontGameSmall", "", COLORS.muted)
    reserveLabel:SetDimensions(112, 20)
    reserveLabel:SetAnchor(TOPRIGHT, window, TOPRIGHT, -10, 52)
    reserveLabel:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    window.reserveLabel = reserveLabel

    local moveHint = CreateLabel(window, "AlphaSquadOverloadTrackerMoveHint", "ZoFontGameSmall", "CLICK + DRAG", COLORS.gold)
    moveHint:SetDimensions(105, 17)
    moveHint:SetAnchor(TOPRIGHT, window, TOPRIGHT, -10, 8)
    moveHint:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
    moveHint:SetHidden(true)
    window.moveHint = moveHint

    -- Unlocked: any mouse button + drag moves the HUD.
    local dragSurface = WINDOW_MANAGER:CreateControl("AlphaSquadOverloadTrackerDragSurface", window, CT_CONTROL)
    dragSurface:SetAnchorFill(window)
    dragSurface:SetMouseEnabled(true)
    window.dragSurface = dragSurface

    dragSurface:SetHandler("OnMouseDown", function()
        if AOT.sv and not AOT.sv.locked then
            window:StartMoving()
        end
    end)
    dragSurface:SetHandler("OnMouseUp", function()
        if AOT.sv and not AOT.sv.locked then
            window:StopMovingOrResizing()
        end
    end)

    -- Locked + reserve reached: any click attempts the public click-off cancel.
    -- This is not a simulated skill activation and never calls private combat APIs.
    local cancelSurface = WINDOW_MANAGER:CreateControl("AlphaSquadOverloadTrackerCancelSurface", window, CT_CONTROL)
    cancelSurface:SetAnchorFill(window)
    cancelSurface:SetMouseEnabled(false)
    window.cancelSurface = cancelSurface
    cancelSurface:SetHandler("OnMouseUp", function()
        if AOT.sv and AOT.sv.locked and AOT.reserveWarning and AOT.isOverloadActive then
            local requested = AOT:TryCancelOverload("manual HUD click", true)
            if not requested then
                AOT:PlayReserveAlert()
            end
        end
    end)

    self:ApplyPosition()
    self:ApplyVisualSettings()
    self:SetDisplayedVariant(VARIANTS.base)
    self:SetOverloadState(false, VARIANTS.base)
end

local function CreateButton(parent, name, text, x, y, width, height, onClick)
    local button = WINDOW_MANAGER:CreateControl(name, parent, CT_CONTROL)
    button:SetDimensions(width, height)
    button:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)
    button:SetMouseEnabled(true)

    local bg = CreateSolid(button, name .. "BG", COLORS.panel)
    button.bg = bg

    local top = WINDOW_MANAGER:CreateControl(name .. "Top", button, CT_TEXTURE)
    top:SetAnchor(TOPLEFT, button, TOPLEFT, 0, 0)
    top:SetAnchor(TOPRIGHT, button, TOPRIGHT, 0, 0)
    top:SetHeight(1)
    top:SetColor(COLORS.cyanDim[1], COLORS.cyanDim[2], COLORS.cyanDim[3], 0.9)

    local label = CreateLabel(button, name .. "Label", "ZoFontGame", text, COLORS.white)
    label:SetAnchorFill(button)
    label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    button.label = label

    button:SetHandler("OnMouseEnter", function()
        bg:SetColor(0.05, 0.11, 0.16, 1)
    end)
    button:SetHandler("OnMouseExit", function()
        bg:SetColor(COLORS.panel[1], COLORS.panel[2], COLORS.panel[3], COLORS.panel[4])
    end)
    button:SetHandler("OnMouseUp", function(_, mouseButton, upInside)
        if mouseButton == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false and onClick then
            onClick()
        end
    end)

    return button
end

function AOT:RefreshSettingsWindow()
    if not self.settingsWindow then return end
    for _, refresher in ipairs(self.settingsRefreshers) do
        refresher()
    end
end

function AOT:ShowSettingsPage(pageId)
    if not self.settingsPages then return end
    if not self.settingsPages[pageId] then pageId = "overload" end
    self.activeSettingsPage = pageId

    for id, page in pairs(self.settingsPages) do
        page:SetHidden(id ~= pageId)
    end

    for id, button in pairs(self.settingsNavButtons or {}) do
        local selected = id == pageId
        if button.bg then
            if selected then
                button.bg:SetColor(0.13, 0.075, 0.025, 0.98)
            else
                button.bg:SetColor(0.022, 0.030, 0.050, 0.96)
            end
        end
        if button.accent then button.accent:SetHidden(not selected) end
        if button.label then
            local color = selected and COLORS.orange or COLORS.white
            button.label:SetColor(color[1], color[2], color[3], 1)
        end
    end
end

function AOT:CreateSettingsWindow()
    -- One lightweight Ąlpha Şquad shell with internal module pages. Future modules
    -- only need a new sidebar entry + page; no extra ESO Settings panel is required.
    self.settingsRefreshers = {}
    self.settingsPages = {}
    self.settingsNavButtons = {}

    local win = WINDOW_MANAGER:CreateTopLevelWindow("AlphaSquadOverloadTrackerSettings")
    self.settingsWindow = win
    AlphaSquadUI = AlphaSquadUI or {}
    AlphaSquadUI.Settings = AlphaSquadUI.Settings or {}
    AlphaSquadUI.Settings.mainWindow = win
    win:SetDimensions(900, 720)
    win:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:SetMouseEnabled(true)
    win:SetDrawTier(DT_HIGH)
    win:SetDrawLayer(DL_OVERLAY)
    win:SetDrawLevel(100)
    win:SetHidden(true)

    CreateSolid(win, "AlphaSquadSettingsBG", {0.010, 0.015, 0.027, 0.992})

    local topLine = WINDOW_MANAGER:CreateControl("AlphaSquadSettingsTopLine", win, CT_TEXTURE)
    topLine:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    topLine:SetAnchor(TOPRIGHT, win, TOPRIGHT, 0, 0)
    topLine:SetHeight(3)
    SetColor(topLine, COLORS.orange)

    local header = WINDOW_MANAGER:CreateControl("AlphaSquadSettingsHeader", win, CT_CONTROL)
    header:SetDimensions(900, 64)
    header:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    header:SetMouseEnabled(true)
    header:SetHandler("OnMouseDown", function(_, button)
        if button == MOUSE_BUTTON_INDEX_LEFT or button == MOUSE_BUTTON_INDEX_RIGHT then win:StartMoving() end
    end)
    header:SetHandler("OnMouseUp", function(_, button)
        if button == MOUSE_BUTTON_INDEX_LEFT or button == MOUSE_BUTTON_INDEX_RIGHT then win:StopMovingOrResizing() end
    end)

    local title = CreateLabel(win, "AlphaSquadSettingsTitle", "ZoFontWinH2", SETTINGS_MENU_NAME, COLORS.white)
    title:SetDimensions(420, 30)
    title:SetAnchor(TOPLEFT, win, TOPLEFT, 20, 10)
    title:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local subtitle = CreateLabel(win, "AlphaSquadSettingsSubtitle", "ZoFontGameSmall", "MODULAR ESO TOOLS  •  v" .. VERSION .. "  •  by SeRuM1", COLORS.muted)
    subtitle:SetDimensions(520, 20)
    subtitle:SetAnchor(TOPLEFT, win, TOPLEFT, 21, 38)
    subtitle:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    CreateButton(win, "AlphaSquadSettingsClose", "X", 846, 14, 34, 30, function()
        if AOT.settingsOpenedFromGameMenu and AOT.settingsFragment then
            SCENE_MANAGER:RemoveFragment(AOT.settingsFragment)
            AOT.settingsOpenedFromGameMenu = false
        end
        win:SetHidden(true)
        AOT:ApplyVisualSettings()
        local ult = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.ULTTracker
        if ult and ult.ApplyVisibility then ult:ApplyVisibility() end
    end)

    local separator = WINDOW_MANAGER:CreateControl("AlphaSquadSettingsSeparator", win, CT_TEXTURE)
    separator:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 63)
    separator:SetAnchor(TOPRIGHT, win, TOPRIGHT, 0, 63)
    separator:SetHeight(1)
    separator:SetColor(COLORS.orange[1], COLORS.orange[2], COLORS.orange[3], 0.45)

    -- Sidebar: intentionally simple and static. It has no OnUpdate handler.
    local sidebar = WINDOW_MANAGER:CreateControl("AlphaSquadSettingsSidebar", win, CT_CONTROL)
    sidebar:SetDimensions(190, 656)
    sidebar:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 64)
    CreateSolid(sidebar, "AlphaSquadSettingsSidebarBG", {0.014, 0.021, 0.037, 0.995})
    local sideLine = WINDOW_MANAGER:CreateControl("AlphaSquadSettingsSidebarLine", sidebar, CT_TEXTURE)
    sideLine:SetAnchor(TOPRIGHT, sidebar, TOPRIGHT, 0, 0)
    sideLine:SetDimensions(1, 656)
    sideLine:SetColor(COLORS.orange[1], COLORS.orange[2], COLORS.orange[3], 0.18)

    local modulesHeader = CreateLabel(sidebar, "AlphaSquadModulesHeader", "ZoFontGameBold", "MODULES", COLORS.orange)
    modulesHeader:SetDimensions(158, 24)
    modulesHeader:SetAnchor(TOPLEFT, sidebar, TOPLEFT, 18, 18)
    modulesHeader:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local function AddNavButton(id, text, y)
        local button = WINDOW_MANAGER:CreateControl("AlphaSquadNav_" .. id, sidebar, CT_CONTROL)
        button:SetDimensions(166, 40)
        button:SetAnchor(TOPLEFT, sidebar, TOPLEFT, 12, y)
        button:SetMouseEnabled(true)
        button.bg = CreateSolid(button, "AlphaSquadNav_" .. id .. "BG", {0.022, 0.030, 0.050, 0.96})
        button.accent = WINDOW_MANAGER:CreateControl("AlphaSquadNav_" .. id .. "Accent", button, CT_TEXTURE)
        button.accent:SetAnchor(TOPLEFT, button, TOPLEFT, 0, 0)
        button.accent:SetDimensions(3, 40)
        SetColor(button.accent, COLORS.orange)
        button.label = CreateLabel(button, "AlphaSquadNav_" .. id .. "Label", "ZoFontGameBold", text, COLORS.white)
        button.label:SetAnchor(TOPLEFT, button, TOPLEFT, 14, 0)
        button.label:SetDimensions(142, 40)
        button.label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        button:SetHandler("OnMouseEnter", function()
            if AOT.activeSettingsPage ~= id then button.bg:SetColor(0.040, 0.050, 0.070, 1) end
        end)
        button:SetHandler("OnMouseExit", function()
            if AOT.activeSettingsPage ~= id then button.bg:SetColor(0.022, 0.030, 0.050, 0.96) end
        end)
        button:SetHandler("OnMouseUp", function(_, mouseButton, upInside)
            if mouseButton == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false then AOT:ShowSettingsPage(id) end
        end)
        self.settingsNavButtons[id] = button
        return button
    end

    AddNavButton("overload", "Overload", 50)
    AddNavButton("ulttracker", "ULT Tracker", 94)

    local communityHeader = CreateLabel(sidebar, "AlphaSquadCommunityNavHeader", "ZoFontGameBold", "COMMUNITY", COLORS.orange)
    communityHeader:SetDimensions(158, 24)
    communityHeader:SetAnchor(TOPLEFT, sidebar, TOPLEFT, 18, 156)
    communityHeader:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    AddNavButton("community", "Website & About", 188)

    local future = CreateLabel(sidebar, "AlphaSquadFutureModules", "ZoFontGameSmall",
        "Future Ąlpha Şquad modules\nwill appear here.", COLORS.muted)
    future:SetDimensions(154, 48)
    future:SetAnchor(TOPLEFT, sidebar, TOPLEFT, 18, 249)
    future:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    future:SetVerticalAlignment(TEXT_ALIGN_TOP)

    local versionLabel = CreateLabel(sidebar, "AlphaSquadSidebarVersion", "ZoFontGameSmall", "v" .. VERSION, COLORS.muted)
    versionLabel:SetDimensions(150, 20)
    versionLabel:SetAnchor(BOTTOMLEFT, sidebar, BOTTOMLEFT, 18, -15)
    versionLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local content = WINDOW_MANAGER:CreateControl("AlphaSquadSettingsContent", win, CT_CONTROL)
    content:SetDimensions(690, 640)
    content:SetAnchor(TOPLEFT, win, TOPLEFT, 200, 70)

    local function CreatePage(id)
        local page = WINDOW_MANAGER:CreateControl("AlphaSquadPage_" .. id, content, CT_CONTROL)
        page:SetAnchorFill(content)
        page:SetHidden(true)
        self.settingsPages[id] = page
        return page
    end

    local function CreateCard(parent, name, x, y, w, h, titleText, titleColor)
        local card = WINDOW_MANAGER:CreateControl(name, parent, CT_CONTROL)
        card:SetDimensions(w, h)
        card:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)
        card.bg = CreateSolid(card, name .. "BG", {0.019, 0.028, 0.047, 0.985})
        local accent = WINDOW_MANAGER:CreateControl(name .. "Accent", card, CT_TEXTURE)
        accent:SetAnchor(TOPLEFT, card, TOPLEFT, 0, 0)
        accent:SetDimensions(3, h)
        SetColor(accent, titleColor or COLORS.orange)
        local label = CreateLabel(card, name .. "Title", "ZoFontGameBold", titleText, titleColor or COLORS.orange)
        label:SetDimensions(w - 28, 24)
        label:SetAnchor(TOPLEFT, card, TOPLEFT, 14, 8)
        label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        return card
    end

    local function AddToggleRow(parent, name, labelText, y, getter, setter)
        local label = CreateLabel(parent, name .. "Label", "ZoFontGame", labelText, COLORS.white)
        label:SetDimensions(parent:GetWidth() - 116, 30)
        label:SetAnchor(TOPLEFT, parent, TOPLEFT, 14, y)
        label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        local button = CreateButton(parent, name .. "Button", "", parent:GetWidth() - 96, y, 80, 30, function()
            setter(not getter())
            AOT:ApplyVisualSettings()
            AOT:RefreshSettingsWindow()
        end)
        table.insert(self.settingsRefreshers, function()
            local enabled = getter()
            button.label:SetText(enabled and "ON" or "OFF")
            local c = enabled and COLORS.green or COLORS.red
            button.label:SetColor(c[1], c[2], c[3], 1)
        end)
    end

    local function AddStepperRow(parent, name, labelText, y, getter, setter, step, minimum, maximum, suffix, color)
        local label = CreateLabel(parent, name .. "Label", "ZoFontGame", labelText, COLORS.white)
        label:SetDimensions(parent:GetWidth() - 170, 30)
        label:SetAnchor(TOPLEFT, parent, TOPLEFT, 14, y)
        label:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        CreateButton(parent, name .. "Minus", "−", parent:GetWidth() - 154, y, 38, 30, function()
            setter(Clamp(getter() - step, minimum, maximum))
            AOT:RefreshSettingsWindow()
        end)
        local value = CreateLabel(parent, name .. "Value", "ZoFontGameBold", "", color or COLORS.cyan)
        value:SetDimensions(56, 30)
        value:SetAnchor(TOPLEFT, parent, TOPLEFT, parent:GetWidth() - 112, y)
        value:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
        CreateButton(parent, name .. "Plus", "+", parent:GetWidth() - 52, y, 38, 30, function()
            setter(Clamp(getter() + step, minimum, maximum))
            AOT:RefreshSettingsWindow()
        end)
        table.insert(self.settingsRefreshers, function()
            value:SetText(tostring(getter()) .. (suffix or ""))
        end)
    end

    -- ULT TRACKER MODULE PAGE
    local ultTrackerPage = CreatePage("ulttracker")
    local ultTrackerModule = AlphaSquadUI
        and AlphaSquadUI.Modules
        and AlphaSquadUI.Modules.ULTTracker

    if ultTrackerModule and ultTrackerModule.BuildIntegratedSettingsPage then
        ultTrackerModule:BuildIntegratedSettingsPage(ultTrackerPage, {
            CreateLabel = CreateLabel,
            CreateCard = CreateCard,
            AddToggleRow = AddToggleRow,
            AddStepperRow = AddStepperRow,
            CreateButton = CreateButton,
            RegisterRefresher = function(fn)
                table.insert(self.settingsRefreshers, fn)
            end,
            colors = COLORS,
        })
    else
        local unavailableTitle = CreateLabel(ultTrackerPage, "AlphaSquadULTUnavailableTitle", "ZoFontWinH2", "ULT TRACKER", COLORS.white)
        unavailableTitle:SetDimensions(420, 32)
        unavailableTitle:SetAnchor(TOPLEFT, ultTrackerPage, TOPLEFT, 8, 2)
        unavailableTitle:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

        local unavailable = CreateLabel(ultTrackerPage, "AlphaSquadULTUnavailableText", "ZoFontGame",
            "ULT Tracker is not available in this build.", COLORS.muted)
        unavailable:SetDimensions(620, 80)
        unavailable:SetAnchor(TOPLEFT, ultTrackerPage, TOPLEFT, 9, 64)
        unavailable:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    end

    -- OVERLOAD MODULE PAGE
    local overload = CreatePage("overload")
    local overloadTitle = CreateLabel(overload, "AlphaSquadOverloadPageTitle", "ZoFontWinH2", "OVERLOAD TRACKER", COLORS.white)
    overloadTitle:SetDimensions(420, 32)
    overloadTitle:SetAnchor(TOPLEFT, overload, TOPLEFT, 8, 2)
    overloadTitle:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    local overloadSub = CreateLabel(overload, "AlphaSquadOverloadPageSub", "ZoFontGameSmall",
        "Fast, event-driven tracking for Overload • Energy Overload • Power Overload", COLORS.muted)
    overloadSub:SetDimensions(650, 22)
    overloadSub:SetAnchor(TOPLEFT, overload, TOPLEFT, 9, 34)
    overloadSub:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local general = CreateCard(overload, "AlphaSquadCardGeneral", 8, 68, 322, 190, "GENERAL", COLORS.orange)
    AddToggleRow(general, "AlphaSquadOptEnabled", "Enable tracking", 42,
        function() return AOT.sv.addonEnabled end, function(v) AOT:SetAddonEnabled(v) end)
    AddToggleRow(general, "AlphaSquadOptVisible", "Show tracker HUD", 78,
        function() return AOT.sv.visible end, function(v) AOT:SetTrackerVisible(v) end)
    AddToggleRow(general, "AlphaSquadOptLocked", "Lock position", 114,
        function() return AOT.sv.locked end, function(v) AOT:SetLocked(v) end)
    AddToggleRow(general, "AlphaSquadOptPvP", "Disable in PvP", 150,
        function() return AOT.sv.disableInPvP end,
        function(v)
            AOT.sv.disableInPvP = v == true
            AOT.reserveAlertLevel = "none"
            AOT.readyReminderActive = false
            AOT:SetEmergencyFlashUpdate(false)
            AOT:SetReadyReminderFlashUpdate(false)
            AOT:ApplyVisualSettings()
        end)

    local emergency = CreateCard(overload, "AlphaSquadCardEmergency", 344, 68, 322, 226, "EMERGENCY RESERVE", COLORS.red)
    AddToggleRow(emergency, "AlphaSquadOptReserve", "Reserve system", 42,
        function() return AOT.sv.reserveCutoffEnabled end,
        function(v) AOT.sv.reserveCutoffEnabled = v == true; AOT.reserveAttempted = false; AOT:CheckReserveCutoff() end)
    AddToggleRow(emergency, "AlphaSquadOptReserveSound", "Alert sounds", 78,
        function() return AOT.sv.reserveSound end, function(v) AOT.sv.reserveSound = v == true end)
    AddStepperRow(emergency, "AlphaSquadOptWarning", "Warning starts", 118,
        function() return AOT.sv.reserveWarningThreshold end,
        function(v) AOT.sv.reserveWarningThreshold = math.max(v, AOT.sv.reserveThreshold); AOT:CheckReserveCutoff() end,
        5, 25, 500, "", COLORS.red)
    AddStepperRow(emergency, "AlphaSquadOptStop", "Auto-stop", 158,
        function() return AOT.sv.reserveThreshold end,
        function(v)
            AOT.sv.reserveThreshold = v
            if AOT.sv.reserveWarningThreshold < v then AOT.sv.reserveWarningThreshold = v end
            AOT.reserveAttempted = false
            AOT:CheckReserveCutoff()
        end,
        5, 25, 500, "", COLORS.cyan)

    local appearance = CreateCard(overload, "AlphaSquadCardAppearance", 8, 270, 322, 236, "APPEARANCE", COLORS.cyan)
    AddStepperRow(appearance, "AlphaSquadOptScale", "Tracker scale", 42,
        function() return AOT.sv.scale end,
        function(v) AOT.sv.scale = v; AOT:ApplyVisualSettings() end,
        5, 60, 160, "%", COLORS.cyan)
    AddStepperRow(appearance, "AlphaSquadOptOpacity", "Background opacity", 82,
        function() return AOT.sv.opacity end,
        function(v) AOT.sv.opacity = v; AOT:ApplyVisualSettings() end,
        5, 30, 100, "%", COLORS.cyan)
    CreateButton(appearance, "AlphaSquadOptReset", "RESET POSITION", 14, 132, 140, 34, function()
        AOT:ResetPosition()
    end)
    CreateButton(appearance, "AlphaSquadOptMove", "UNLOCK & MOVE", 164, 132, 144, 34, function()
        AOT.sv.addonEnabled = true
        AOT.sv.visible = true
        AOT:SetLocked(false)
        win:SetHidden(true)
        AOT:ApplyVisualSettings()
    end)
    local opacityNote = CreateLabel(appearance, "AlphaSquadOpacityNote", "ZoFontGameSmall",
        "Opacity affects the background only. Text, icon and borders stay fully visible.", COLORS.muted)
    opacityNote:SetDimensions(290, 48)
    opacityNote:SetAnchor(TOPLEFT, appearance, TOPLEFT, 14, 178)
    opacityNote:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    opacityNote:SetVerticalAlignment(TEXT_ALIGN_TOP)

    local ready = CreateCard(overload, "AlphaSquadCardReady", 344, 306, 322, 174, "READY REMINDER", COLORS.gold)
    AddToggleRow(ready, "AlphaSquadOptReady", "Ready reminder", 42,
        function() return AOT.sv.readyReminderEnabled end,
        function(v) AOT.sv.readyReminderEnabled = v == true; AOT.readyReminderActive = false; AOT.lastReadySoundAt = 0; AOT:UpdateReserveVisual() end)
    AddToggleRow(ready, "AlphaSquadOptReadySound", "Reminder sound", 78,
        function() return AOT.sv.readyReminderSound end, function(v) AOT.sv.readyReminderSound = v == true end)
    AddStepperRow(ready, "AlphaSquadOptReadyThreshold", "Ready at", 118,
        function() return AOT.sv.readyReminderThreshold end,
        function(v) AOT.sv.readyReminderThreshold = v; AOT.readyReminderActive = false; AOT.lastReadySoundAt = 0; AOT:UpdateReserveVisual() end,
        10, 100, 500, "", COLORS.gold)

    local runtime = CreateCard(overload, "AlphaSquadCardRuntime", 344, 492, 322, 126, "PERFORMANCE", COLORS.green)
    local runtimeText = CreateLabel(runtime, "AlphaSquadRuntimeText", "ZoFontGameSmall",
        "Event-driven by default. Safety sync runs only once per second (and slower while dormant). Alert animation loops exist only while an alert is actually visible.", COLORS.muted)
    runtimeText:SetDimensions(290, 82)
    runtimeText:SetAnchor(TOPLEFT, runtime, TOPLEFT, 14, 38)
    runtimeText:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    runtimeText:SetVerticalAlignment(TEXT_ALIGN_TOP)

    -- COMMUNITY / ABOUT PAGE
    local community = CreatePage("community")
    local communityTitle = CreateLabel(community, "AlphaSquadCommunityTitle", "ZoFontWinH2", "ĄLPHA ŞQUAD COMMUNITY", COLORS.white)
    communityTitle:SetDimensions(520, 34)
    communityTitle:SetAnchor(TOPLEFT, community, TOPLEFT, 8, 3)
    communityTitle:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    local communitySub = CreateLabel(community, "AlphaSquadCommunitySub", "ZoFontGameSmall",
        "Endgame ESO PvE • HM • Trifectas • Builds • Guides • Recruitment", COLORS.muted)
    communitySub:SetDimensions(650, 22)
    communitySub:SetAnchor(TOPLEFT, community, TOPLEFT, 9, 38)
    communitySub:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local siteCard = CreateCard(community, "AlphaSquadSiteCard", 8, 78, 658, 182, "VISIT OUR WEBSITE", COLORS.orange)
    local siteIntro = CreateLabel(siteCard, "AlphaSquadSiteIntro", "ZoFontGame", 
        "Discover Ąlpha Şquad guides, builds, roster information and endgame resources.", COLORS.white)
    siteIntro:SetDimensions(620, 50)
    siteIntro:SetAnchor(TOPLEFT, siteCard, TOPLEFT, 16, 42)
    siteIntro:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    siteIntro:SetVerticalAlignment(TEXT_ALIGN_TOP)
    local siteUrl = CreateLabel(siteCard, "AlphaSquadSiteURL", "ZoFontGameBold", SITE_URL, COLORS.cyan)
    siteUrl:SetDimensions(390, 32)
    siteUrl:SetAnchor(TOPLEFT, siteCard, TOPLEFT, 16, 92)
    siteUrl:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    siteUrl:SetMouseEnabled(true)
    siteUrl:SetHandler("OnMouseEnter", function(c) SetColor(c, COLORS.white) end)
    siteUrl:SetHandler("OnMouseExit", function(c) SetColor(c, COLORS.cyan) end)
    siteUrl:SetHandler("OnMouseUp", function(_, button, upInside)
        if button == MOUSE_BUTTON_INDEX_LEFT and upInside ~= false then AOT:OpenWebsite() end
    end)
    CreateButton(siteCard, "AlphaSquadSiteButton", "VISIT WEBSITE", 458, 88, 176, 38, function() AOT:OpenWebsite() end)
    local confirmNote = CreateLabel(siteCard, "AlphaSquadSiteConfirm", "ZoFontGameSmall",
        "ESO may ask for confirmation before opening an external website.", COLORS.muted)
    confirmNote:SetDimensions(610, 24)
    confirmNote:SetAnchor(TOPLEFT, siteCard, TOPLEFT, 16, 140)
    confirmNote:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local aboutCard = CreateCard(community, "AlphaSquadAboutCard", 8, 276, 658, 174, "ABOUT THIS ADDON", COLORS.cyan)
    local about = CreateLabel(aboutCard, "AlphaSquadAboutText", "ZoFontGameSmall",
        "Ąlpha Şquad Overload Tracker is built as the first module of a larger modular toolkit. The settings shell is shared, so future features can be added as new sidebar modules without creating extra Settings entries or permanent background loops.\n\nCreated by SeRuM1  •  English UI  •  Subclassing compatible", COLORS.muted)
    about:SetDimensions(620, 126)
    about:SetAnchor(TOPLEFT, aboutCard, TOPLEFT, 16, 40)
    about:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    about:SetVerticalAlignment(TEXT_ALIGN_TOP)

    local commandCard = CreateCard(community, "AlphaSquadCommandCard", 8, 466, 658, 152, "USEFUL COMMANDS", COLORS.gold)
    local commands = CreateLabel(commandCard, "AlphaSquadCommandsText", "ZoFontGameSmall",
        "/asoverload  •  open settings\n/asoverload lock | unlock  •  save/unlock HUD position\n/asoverload status | inspect  •  manual diagnostics only\n/asoverload website  •  open alphasquadeso.com", COLORS.muted)
    commands:SetDimensions(620, 104)
    commands:SetAnchor(TOPLEFT, commandCard, TOPLEFT, 16, 40)
    commands:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    commands:SetVerticalAlignment(TEXT_ALIGN_TOP)

    self:ShowSettingsPage(self.activeSettingsPage or "overload")
    self:RefreshSettingsWindow()
end

function AOT:RegisterDirectSettingsPanel()
    if not ZO_GameMenu_AddSettingPanel or not KEYBOARD_OPTIONS or not self.settingsWindow then return end

    local panelId = KEYBOARD_OPTIONS.currentPanelId
    KEYBOARD_OPTIONS.currentPanelId = panelId + 1
    KEYBOARD_OPTIONS.panelNames[panelId] = "Ąlpha Şquad"
    self.directSettingsPanelId = panelId
    self.settingsFragment = ZO_FadeSceneFragment:New(self.settingsWindow)

    local panelData = {
        id = panelId,
        name = SETTINGS_MENU_NAME,
        visible = true,
    }

    panelData.callback = function(_, anchorFunction)
        AOT.settingsOpenedFromGameMenu = true
        AOT.settingsWindow:SetMovable(false)
        AOT.settingsWindow:ClearAnchors()
        if anchorFunction then
            anchorFunction(AOT.settingsWindow)
        elseif ZO_ReanchorControlForLeftSidePanel then
            ZO_ReanchorControlForLeftSidePanel(AOT.settingsWindow)
        else
            AOT.settingsWindow:SetAnchor(CENTER, GuiRoot, CENTER, 170, 0)
        end
        SCENE_MANAGER:AddFragment(AOT.settingsFragment)
        KEYBOARD_OPTIONS:ChangePanels(panelId)
        AOT:RefreshSettingsWindow()
        zo_callLater(function()
            AOT:ApplyVisualSettings()
            local ult = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.ULTTracker
            if ult and ult.ApplyVisibility then ult:ApplyVisibility() end
        end, 0)
    end

    panelData.unselectedCallback = function()
        if AOT.settingsFragment then
            SCENE_MANAGER:RemoveFragment(AOT.settingsFragment)
        end
        AOT.settingsOpenedFromGameMenu = false
        AOT.settingsWindow:SetMovable(true)
        zo_callLater(function()
            AOT:ApplyVisualSettings()
            local ult = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.ULTTracker
            if ult and ult.ApplyVisibility then ult:ApplyVisibility() end
        end, 0)
        if SetCameraOptionsPreviewModeEnabled then
            SetCameraOptionsPreviewModeEnabled(false, CAMERA_OPTIONS_PREVIEW_NONE)
        end
    end

    self.directSettingsPanelData = panelData
    ZO_GameMenu_AddSettingPanel(panelData)
end

function AOT:RegisterHUDSceneVisibility()
    local function OnHudSceneStateChange()
        zo_callLater(function() AOT:RefreshUIObscuredState() end, 0)
    end
    if HUD_SCENE and HUD_SCENE.RegisterCallback then
        HUD_SCENE:RegisterCallback("StateChange", OnHudSceneStateChange)
    end
    if HUD_UI_SCENE and HUD_UI_SCENE.RegisterCallback then
        HUD_UI_SCENE:RegisterCallback("StateChange", OnHudSceneStateChange)
    end
    self:RefreshUIObscuredState()
end

function AOT:ToggleSettingsWindow()
    if not self.settingsWindow then return end
    if self.settingsOpenedFromGameMenu and self.settingsFragment then
        SCENE_MANAGER:RemoveFragment(self.settingsFragment)
        self.settingsOpenedFromGameMenu = false
    end
    local hidden = self.settingsWindow:IsHidden()
    if hidden then
        self.settingsWindow:SetMovable(true)
        self.settingsWindow:ClearAnchors()
        self.settingsWindow:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    end
    self.settingsWindow:SetHidden(not hidden)
    if hidden then self:RefreshSettingsWindow() end
    self:ApplyVisualSettings()
    local ult = AlphaSquadUI and AlphaSquadUI.Modules and AlphaSquadUI.Modules.ULTTracker
    if ult and ult.ApplyVisibility then ult:ApplyVisibility() end
end

function AOT:PrintHelp()
    Chat("Commands:")
    Chat("/asoverload - Open or close settings.")
    Chat("/asoverload toggle - Toggle HUD visibility.")
    Chat("/asoverload show | hide - Show or hide the HUD.")
    Chat("/asoverload enable | disable - Enable or disable tracking.")
    Chat("/asoverload lock | unlock - Save+lock position or unlock movement.")
    Chat("/asoverload reserve on|off - Enable or disable the emergency reserve system.")
    Chat("/asoverload warning 160 - Set the emergency alert start threshold (25-500).")
    Chat("/asoverload threshold 130 - Set the auto-stop reserve threshold (25-500).")
    Chat("/asoverload ready on|off - Enable or disable the 400+ Ultimate Overload-ready reminder.")
    Chat("/asoverload ready 400 - Set the ready reminder threshold (100-500).")
    Chat("/asoverload ready sound on|off - Enable or disable the gentle ready reminder sound.")
    Chat("/asoverload readytest - Force the READY visual and sound for 6 seconds to verify the reminder.")
    Chat("/asoverload cancel - Request click-off cancellation of active Overload.")
    Chat("/asoverload status - Print addon, morph, Ultimate and reserve status.")
    Chat("/asoverload inspect - Print live Overload slot/effect diagnostics.")
    Chat("/asoverload debug - Toggle extra debug messages.")
    Chat("/asoverload website - Open the Ąlpha Şquad community website.")
    Chat("/asoverload reset | help - Reset HUD position or print this list.")
end

function AOT:RegisterSlashCommands()
    SLASH_COMMANDS["/asoverload"] = function(argument)
        local arg = tostring(argument or ""):match("^%s*(.-)%s*$") or ""
        local lower = string.lower(arg)

        if lower == "lock" then
            self:SetLocked(true)
            Chat(string.format("Position locked and saved at X:%d Y:%d.", self.sv.x or 0, self.sv.y or 0))
        elseif lower == "unlock" or lower == "move" then
            self.sv.addonEnabled = true
            self.sv.visible = true
            self:SetLocked(false)
            Chat("Position unlocked. Drag the tracker with any mouse button, then lock it to save that position.")
        elseif lower == "reset" then
            self:ResetPosition()
            Chat("Position reset.")
        elseif lower == "toggle" then
            self:ToggleTrackerVisibility()
        elseif lower == "show" then
            self:SetTrackerVisible(true)
            Chat("Tracker shown.")
        elseif lower == "hide" then
            self:SetTrackerVisible(false)
            Chat("Tracker hidden. Tracking remains enabled.")
        elseif lower == "enable" or lower == "on" then
            self.sv.visible = true
            self:SetAddonEnabled(true)
            Chat("Addon tracking enabled.")
        elseif lower == "disable" or lower == "off" then
            self.sv.visible = false
            self:SetAddonEnabled(false)
            Chat("Addon tracking disabled and HUD hidden. Use /asoverload enable to reactivate it.")
        elseif lower == "reserve on" then
            self.sv.reserveCutoffEnabled = true
            self.reserveAttempted = false
            self:CheckReserveCutoff()
            self:RefreshSettingsWindow()
            Chat(string.format("Emergency reserve system enabled. Alert starts at %d; auto-stop threshold is %d.", self.sv.reserveWarningThreshold, self.sv.reserveThreshold))
        elseif lower == "reserve off" then
            self.sv.reserveCutoffEnabled = false
            self.reserveWarning = false
            self.reservePreWarning = false
            self.reserveAlertLevel = "none"
            self.reserveAttempted = false
            self:SetEmergencyFlashUpdate(false)
            self:UpdateReserveVisual()
            self:RefreshSettingsWindow()
            Chat("Emergency reserve system disabled.")
        elseif lower == "reserve" or lower == "reserve toggle" then
            self.sv.reserveCutoffEnabled = not self.sv.reserveCutoffEnabled
            self.reserveWarning = false
            self.reserveAttempted = false
            self:CheckReserveCutoff()
            self:RefreshSettingsWindow()
            Chat("Emergency reserve system " .. (self.sv.reserveCutoffEnabled and "enabled." or "disabled."))
        elseif lower:match("^warning%s+") then
            local value = tonumber(lower:match("^warning%s+(%d+)$"))
            if value then
                self.sv.reserveWarningThreshold = Clamp(value, self.sv.reserveThreshold, 500)
                self:CheckReserveCutoff()
                self:RefreshSettingsWindow()
                Chat(string.format("Emergency alert will start at %d Ultimate.", self.sv.reserveWarningThreshold))
            else
                Chat("Usage: /asoverload warning 160")
            end
        elseif lower:match("^threshold%s+") then
            local value = tonumber(lower:match("^threshold%s+(%d+)$"))
            if value then
                self.sv.reserveThreshold = Clamp(math.floor(value + 0.5), 25, 500)
                if self.sv.reserveWarningThreshold < self.sv.reserveThreshold then
                    self.sv.reserveWarningThreshold = self.sv.reserveThreshold
                end
                self.reserveAttempted = false
                self:CheckReserveCutoff()
                self:RefreshSettingsWindow()
                Chat(string.format("Auto-stop reserve threshold set to %d Ultimate.", self.sv.reserveThreshold))
            else
                Chat("Usage: /asoverload threshold 130")
            end
        elseif lower == "ready on" then
            self.sv.readyReminderEnabled = true
            self.readyReminderActive = false
            self.lastReadySoundAt = 0
            self:UpdateReserveVisual()
            self:RefreshSettingsWindow()
            Chat(string.format("Overload ready reminder enabled at %d Ultimate.", self.sv.readyReminderThreshold))
        elseif lower == "ready off" then
            self.sv.readyReminderEnabled = false
            self.readyReminderActive = false
            self.lastReadySoundAt = 0
            self:SetReadyReminderFlashUpdate(false)
            self:UpdateReserveVisual()
            self:RefreshSettingsWindow()
            Chat("Overload ready reminder disabled.")
        elseif lower == "ready sound on" then
            self.sv.readyReminderSound = true
            self.lastReadySoundAt = 0
            self:RefreshSettingsWindow()
            Chat("Ready reminder sound enabled.")
        elseif lower == "ready sound off" then
            self.sv.readyReminderSound = false
            self:RefreshSettingsWindow()
            Chat("Ready reminder sound disabled.")
        elseif lower:match("^ready%s+%d+$") then
            local value = tonumber(lower:match("^ready%s+(%d+)$"))
            if value then
                self.sv.readyReminderThreshold = Clamp(math.floor(value + 0.5), 100, 500)
                self.readyReminderActive = false
                self.lastReadySoundAt = 0
                self:UpdateReserveVisual()
                self:RefreshSettingsWindow()
                Chat(string.format("Overload ready reminder threshold set to %d Ultimate.", self.sv.readyReminderThreshold))
            end
        elseif lower == "readytest" or lower == "testready" then
            self.sv.readyReminderEnabled = true
            self.readyTestUntil = GetMs() + 6000
            self.readyReminderActive = false
            self.lastReadySoundAt = 0
            self:UpdateReserveVisual()
            self:RefreshSettingsWindow()
            Chat("READY reminder test started for 6 seconds.")
        elseif lower == "cancel" or lower == "stop" then
            local requested = self:TryCancelOverload("chat command", true)
            if requested then
                Chat("Overload cancellation requested.")
            end
        elseif lower == "website" or lower == "site" or lower == "community" then
            self:OpenWebsite()
            Chat("Opening the Ąlpha Şquad website.")
        elseif lower == "status" then
            local addonState = self.sv.addonEnabled and "ENABLED" or "DISABLED"
            local hudState = self.sv.visible and "SHOWN" or "HIDDEN"
            local overloadState = self.isOverloadActive and "ON" or "OFF"
            local current = select(1, self:GetUltimatePower())
            Chat(string.format("Addon: %s | HUD: %s | %s: %s | Ultimate: %d | Emergency: %s @ %d | Auto-stop: %d | Ready: %s @ %d",
                addonState, hudState, self.currentVariant.title, overloadState, current,
                self.sv.reserveCutoffEnabled and "ON" or "OFF", self.sv.reserveWarningThreshold, self.sv.reserveThreshold,
                self.sv.readyReminderEnabled and "ON" or "OFF", self.sv.readyReminderThreshold))
        elseif lower == "inspect" or lower == "diagnostics" then
            self:PrintDiagnostics()
        elseif lower == "debug" then
            self.debugEnabled = not self.debugEnabled
            Chat("Debug messages " .. (self.debugEnabled and "enabled." or "disabled."))
            if self.debugEnabled then self:PrintDiagnostics() end
        elseif lower == "help" or lower == "commands" or lower == "?" then
            self:PrintHelp()
        elseif lower == "" or lower == "settings" or lower == "options" then
            self:ToggleSettingsWindow()
        else
            Chat("Unknown command: " .. lower)
            Chat("Use /asoverload help to see all commands.")
        end
    end
end

function AOT:RegisterEvents()
    local effectEvent = ADDON_NAME .. "_EffectChanged"
    EVENT_MANAGER:RegisterForEvent(effectEvent, EVENT_EFFECT_CHANGED, function(...)
        AOT:OnEffectChanged(...)
    end)
    EVENT_MANAGER:AddFilterForEvent(effectEvent, EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, "player")

    EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_PlayerActivated", EVENT_PLAYER_ACTIVATED, function()
        zo_callLater(function() AOT:RefreshUIObscuredState(); AOT:RefreshOverloadState("player activated") end, 250)
    end)

    EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_ActionUsed", EVENT_ACTION_SLOT_ABILITY_USED, function(...)
        AOT:OnActionSlotAbilityUsed(...)
    end)

    if EVENT_ACTION_SLOT_STATE_UPDATED then
        EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_SlotStateUpdated", EVENT_ACTION_SLOT_STATE_UPDATED, function(_, slotNum)
            if slotNum == ULTIMATE_SLOT then
                zo_callLater(function() AOT:RefreshOverloadState("slot state") end, 25)
            end
        end)
    end

    -- Fires when the actual action assigned to a slot changes. Refresh on any slot
    -- update because API builds can differ in the exact event arguments/index base.
    if EVENT_ACTION_SLOT_UPDATED then
        EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_SlotUpdated", EVENT_ACTION_SLOT_UPDATED, function(_, slotNum)
            -- Ignore unrelated skill-slot edits when the API provides a slot index.
            if slotNum ~= nil and slotNum ~= ULTIMATE_SLOT then return end
            zo_callLater(function() AOT:RefreshOverloadState("ultimate slot updated") end, 25)
        end)
    end

    if EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED then
        EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_HotbarUpdated", EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED, function()
            zo_callLater(function() AOT:RefreshOverloadState("active hotbar updated") end, 25)
        end)
    end

    if EVENT_POWER_UPDATE then
        local powerEvent = ADDON_NAME .. "_PowerUpdate"
        EVENT_MANAGER:RegisterForEvent(powerEvent, EVENT_POWER_UPDATE, function(...)
            AOT:OnPowerUpdate(...)
        end)
        -- Filter at the event manager level so the callback fires only for the player's Ultimate.
        if REGISTER_FILTER_UNIT_TAG and REGISTER_FILTER_POWER_TYPE and ULTIMATE_POWER_TYPE then
            EVENT_MANAGER:AddFilterForEvent(powerEvent, EVENT_POWER_UPDATE,
                REGISTER_FILTER_UNIT_TAG, "player",
                REGISTER_FILTER_POWER_TYPE, ULTIMATE_POWER_TYPE)
        end
    end

    -- Event-driven tracking is primary. This slow heartbeat is only a safety net
    -- for rare missed API transitions, keeping idle CPU usage negligible.
    local lastDormantPoll = 0
    EVENT_MANAGER:RegisterForUpdate(ADDON_NAME .. "_HealthSync", 1000, function()
        if AOT.autoDormant then
            local now = GetMs()
            if now - lastDormantPoll < 3000 then return end
            lastDormantPoll = now
        end
        AOT:RefreshOverloadState("health sync")
    end)
end

function AOT:Initialize()
    local defaultX, defaultY = self:GetDefaultPosition()
    local defaults = {
        addonEnabled = true,
        visible = true,
        locked = false,
        scale = 100,
        opacity = 95,
        x = defaultX,
        y = defaultY,
        positionSaved = false,
        reserveCutoffEnabled = true,
        reserveThreshold = 130,
        reserveWarningThreshold = 160,
        reserveSound = true,
        readyReminderEnabled = true,
        readyReminderThreshold = 400,
        readyReminderSound = true,
        disableInPvP = false,
    }

    local worldNamespace = GetWorldName and GetWorldName() or nil
    self.sv = ZO_SavedVars:NewAccountWide("AlphaSquadOverloadTrackerSavedVariables", 1, worldNamespace, defaults)

    -- Migration from old versions.
    if self.sv.enabled ~= nil then
        self.sv.visible = self.sv.enabled
        self.sv.enabled = nil
    end
    if self.sv.reserveCutoffEnabled == nil then self.sv.reserveCutoffEnabled = true end
    if self.sv.reserveThreshold == nil then self.sv.reserveThreshold = 130 end
    if self.sv.reserveWarningThreshold == nil then self.sv.reserveWarningThreshold = 160 end
    if self.sv.reserveWarningThreshold < self.sv.reserveThreshold then self.sv.reserveWarningThreshold = self.sv.reserveThreshold end
    if self.sv.reserveSound == nil then self.sv.reserveSound = true end
    if self.sv.readyReminderEnabled == nil then self.sv.readyReminderEnabled = true end
    if self.sv.readyReminderThreshold == nil then self.sv.readyReminderThreshold = 400 end
    self.sv.readyReminderThreshold = Clamp(self.sv.readyReminderThreshold, 100, 500)
    if self.sv.readyReminderSound == nil then self.sv.readyReminderSound = true end
    if self.sv.disableInPvP == nil then self.sv.disableInPvP = false end

    self.localizedPowerName = GetAbilityName and GetAbilityName(VARIANTS.power.abilityId) or "Power Overload"
    self.localizedEnergyName = GetAbilityName and GetAbilityName(VARIANTS.energy.abilityId) or "Energy Overload"

    self:CreateTrackerWindow()
    self:CreateSettingsWindow()
    self:RegisterDirectSettingsPanel()
    self:RegisterHUDSceneVisibility()
    self:RegisterSlashCommands()
    self:RegisterEvents()

    zo_callLater(function()
        AOT:RefreshUIObscuredState()
        AOT:RefreshOverloadState("initial")
    end, 500)
end

local function OnAddonLoaded(_, addonName)
    if addonName ~= ADDON_NAME then return end
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
    AOT:Initialize()
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
