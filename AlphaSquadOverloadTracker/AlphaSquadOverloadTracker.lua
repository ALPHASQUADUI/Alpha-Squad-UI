--[[
    Ä„lpha Åquad - Overload Tracker
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

local ADDON_NAME = "AlphaSquadOverloadTracker"
local DISPLAY_NAME = "Ä„lpha Åquad - Overload Tracker"
local SETTINGS_MENU_NAME = "|cE66A19Ä„|cEA7628l|cEE8237p|cF18E47h|cF49A58a |cF6A968Å|cF8B77Aq|cFAC58Cu|cFCD49Ea|cFFF3D0d|r"
local VERSION = "2.5.0"
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
    d(string.format("|c35D9FF[Ä„S Overload]|r %s", tostring(message)))
end

function AOT:OpenWebsite()
    if RequestOpenUnsafeURL then
        RequestOpenUnsafeURL(SITE_URL)
    else
        Chat("Visit the Ä„lpha Åquad website: " .. SITE_URL)
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

function AOT:ShouldAutoHideForPvP()
    return self.sv and self.sv.disableInPvP == true and self:IsPvPContext()
end

function AOT:IsHudVisibleScene()
    if not SCUNE_MANAGER then return true end
    local current = SCENE_MANAGER:GetCurrentScene()
    if not current then return true end
    local name = current:GetName()
    return name == "hud" or name == "hudui" or name == "hudUIˆ)•¹()™Õ¹Ñ¥½¸=PéI•™É•Í¡U%=‰ÍÕÉ•‘MÑ…Ñ” ¤(€€€±½…°İ…Í=‰ÍÕÉ•€ôÍ•±˜¹Õ¥=‰ÍÕÉ•(€€€Í•±˜¹Õ¥=‰ÍÕÉ•€ô¹½ĞÍ•±˜é%Í!Õ‘Y¥Í¥‰±•M•¹” ¤((€€€¥˜İ…Í=‰ÍÕÉ•…¹¹½ĞÍ•±˜¹Õ¥=‰ÍÕÉ•Ñ¡•¸(€€€€€€€€´´I•ÑÕÉ¹¥¹œÑ¼Ñ¡”!U…¸¡…¹”…Ñ¥½¸‰…È½¹Ñ•áĞ¸I•™É•Í ½¹”¸(€€€€€€€é½}…±±1…Ñ•È¡™Õ¹Ñ¥½¸ ¤=PéI•™É•Í¡=Ù•É±½…‘MÑ…Ñ” ‰¡ÕÉ•ÑÕÉ¸ˆ¤•¹°€ÔÀ¤(€€€•¹((€€€Í•±˜éÁÁ±åY¥Í¥‰¥±¥Ñä ¤)•¹()™Õ¹Ñ¥½¸=PéI•¥ÍÑ•É!UM•¹•Y¥Í¥‰¥±¥Ñä ¤(€€€±½…°Í•¹•Ì€ôì(€€€€€€€!AU}M9°(€€€€€€€!U}U%}M9°(€€€ô(€€€™½È|°Í•¹”¥¸¥Á…¥ÉÌ¡Í•¹•Ì¤‘¼(€€€€€€€¥˜Í•¹”…¹Í•¹”¹I•¥ÍÑ•É…±±‰…¬Ñ¡•¸(€€€€€€€€€€€Í•¹”éI•¥ÍÑ•É…±±‰…¬ ‰MÑ…Ñ•¡…¹”ˆ°™Õ¹Ñ¥½¸ ¤(€€€€€€€€€€€€€€€é½}…±±1…Ñ•È¡™Õ¹Ñ¥½¸ ¤=PéI•™É•Í¡U%=‰ÍÕÉ•‘MÑ…Ñ” ¤•¹°€À¤(€€€€€€€€€€€•¹¤(€€€€€€€•¹(€€€•¹(€€€é½}…±±1…Ñ•È¡™Õ¹Ñ¥½¸ ¤=PéI•™É•Í¡U%=‰ÍÕÉ•‘MÑ…Ñ” ¤•¹°€À¤)•¹()™Õ¹Ñ¥½¸=Pé%‘•¹Ñ¥™åY…É¥…¹Ğ¡…‰¥±¥Ñå%°¹…µ”°¥½¸¤(€€€…‰¥±¥Ñå%€ôÑ½¹Õµ‰•È¡…‰¥±¥Ñå%¤½È€À(€€€±½…°¹…µ•0€ô9½Éµ…±¥é”¡¹…µ”¤(€€€±½…°¥½¹0€ô9½Éµ…±¥é”¡¥½¸¤((€€€¥˜YI%9QL¹Á½İ•È¹…‰¥±¥Ñå%…¹…‰¥±¥Ñå%€ôôYI%9QL¹Á½İ•È¹…‰¥±¥Ñå%Ñ¡•¸(€€€€€€€É•ÑÕÉ¸YI%9QL¹Á½İ•È(€€€•¹(€€€¥˜YI%9QL¹•¹•Éä¹…‰¥±¥Ñå%…¹…‰¥±¥Ñå%€ôôYI%9QL¹•¹•Éä¹…‰¥±¥Ñå%Ñ¡•¸(€€€€€€€É•ÑÕÉ¸YI%9QL¹•¹•Éä(€€€•¹((€€€¥˜Í•±˜¹±½…±¥é•‘A½İ•É9…µ”…¹¹…µ•0€ôô9½Éµ…±¥é”¡Í•±˜¹±½…±¥é•‘A½İ•É9…µ”¤Ñ¡•¸(€€€€€€€É•ÑÕÉ¸YI%9QL¹Á½İ•È(€€€•¹(€€€¥˜Í•±˜¹±½…±¥é•‘¹•Éå9…µ”…¹¹…µ•0€ôô9½Éµ…±¥é”¡Í•±˜¹±½…±¥é•‘¹•Éå9…µ”¤Ñ¡•¸(€€€€€€€É•ÑÕÉ¸YI%9QL¹•¹•Éä(€€€•¹((€€€¥˜¹…µ•0é™¥¹ ‰Á½İ•Èˆ°€Ä°ÑÉÕ”¤…¹¹…µ•0é™¥¹ ‰½Ù•É±½…ˆ°€Ä°ÑÉÕ”¤Ñ¡•¸(€€€€€€€É•ÑÕÉ¸YI%9QL¹Á½İ•È(€€€•¹(€€€¥˜¹…µ•0é™¥¹ ‰•¹•Éäˆ°€Ä°ÑÉÕ”¤…¹¹…µ•0é™¥¹ ‰½Ù•É±½…ˆ°€Ä°ÑÉÕ”¤Ñ¡•¸(€€€€€€€É•ÑÕÉ¸YI%9QL¹•¹•Éä(€€€•¹(€€€¥˜¹…µ•0€ôô€‰½Ù•É±½…ˆÑ¡•¸(€€€€€€€É•ÑÕÉ¸YI%9QL¹‰…Í”(€€€•¹((€€€¥˜¥½¹0é™¥¹ ‰Á½İ•É}½Ù•É±½…ˆ°€Ä°ÑÉÕ”¤Ñ¡•¸É•ÑÕÉ¸YI%9QL¹Á½İ•È•¹(€€€¥˜¥½¹0é™¥¹ ‰•¹•Éå}½Ù•É±½…ˆ°€Ä°ÑÉÕ”¤Ñ¡•¸É•ÑÕÉ¸YI%9QL¹•¹•Éä•¹(€€€¥˜¥½¹0é™¥¹ ‰}½Ù•É±½…ˆ°€Ä°ÑÉÕ”¤½È¥½¹0é™¥¹ ˆ½½Ù•É±½…ˆ°€Ä°ÑÉÕ”¤Ñ¡•¸É•ÑÕÉ¸YI%9QL¹‰…Í”•¹((€€€€´´…±±‰…¬™½È±½…±¥é•±¥•¹ÑÌè½¹±ä±…ÍÍ¥™ä…Ì=Ù•É±½…¥˜‰½Ñ ¹…µ”…¹(€€€€´´¥½¸ÍÑÉ½¹±äÁ½¥¹ĞÑ¼Ñ¡”M½É•É•È=Ù•É±½…Í­¥±°¸(€€€¥˜¹…µ•0é™¥¹ ‰½Ù•É±½…ˆ°€Ä°ÑÉÕ”¤…¹¥½¹0é™¥¹ ‰½Ù•É±½…ˆ°€Ä°ÑÉÕ”¤Ñ¡•¸(€€€€€€€É•ÑÕÉ¸YI%9QL¹‰…Í”(€€€•¹((€€€É•ÑÕÉ¸¹¥°)•¹()™Õ¹Ñ¥½¸=Pé¥¹‘=Ù•É±½…‘M±½Ğ ¤(€€€±½…°™½Õ¹€ô¹¥°(€€€±½…°…Ñ•½É¥•Ì€ôì!=Q	I}Q=Ie}AI%5Id°!=Q	I}Q=Ie}	-U@ô((€€€™½È|°…Ñ•½Éä¥¸¥Á…¥ÉÌ¡…Ñ•½É¥•Ì¤‘¼(€€€€€€€¥˜…Ñ•½Éäøô¹¥°Ñ¡•¸(€€€€€€€€€€€±½…°…‰¥±¥Ñå%€ô€¡•ÑM±½Ñ	½Õ¹‘%…¹•ÑM±½Ñ	½Õ¹‘%¡U1Q%5Q}M1=P°…Ñ•½Éä¤¤½È€À(€€€€€€€€€€€±½…°¹…µ”€ô€¡•ÑM±½Ñ9…µ”…¹•ÑM±½Ñ9…µ”¡U1%5Q}M1=P°…Ñ•½Éä¤¤½È€ˆˆ(€€€€€€€€€€€±½…°¥½¸€ô€¡•ÑM±½ÑQ•áÑÕÉ”…¹•ÑM±½ÑQ•áÑÕÉ”¡U1Q%5Q}M1=P°…Ñ•½Éä¤¤½È€ˆˆ(€€€€€€€€€€€±½…°Ù…É¥…¹Ğ€ôÍ•±˜é%‘•¹Ñ¥™åY…É¥…¹Ğ¡…‰¥±¥Ñå%°¹…µ”°¥½¸¤((€€€€€€€€€€€¥˜Ù…É¥…¹ĞÑ¡•¸(€€€€€€€€€€€€€€€±½…°Ñ½±•€ô™…±Í”(€€€€€€€€€€€€€€€¥˜%ÍM±½ÑQ½±•Ñ¡•¸(€€€€€€€€€€€€€€€€€€€±½…°½¬°É•ÍÕ±Ğ€ôÁ…±°¡%ÍM±½ÑQ½±•°U1Q%5Q}M1=P°…Ñ•½Éä¤(€€€€€€€€€€€€€€€€€€€¥˜½¬Ñ¡•¸Ñ½±•€ôÉ•ÍÕ±Ğ€ôôÑÉÕ”•¹(€€€€€€€€€€€€€€€•¹((€€€€€€€€€€€€€€€±½…°•¹ÑÉä€ôì(€€€€€€€€€€€€€€€€€€€…Ñ•½Éä€ô…Ñ•½Éä°(€€€€€€€€€€€€€€€€€€€…‰¥±¥Ñå%€ô…‰¥±¥Ñå%°(€€€€€€€€€€€€€€€€€€€¹…µ”€ô¹…µ”°(€€€€€€€€€€€€€€€€€€€¥½¸€ô¥½¸°(€€€€€€€€€€€€€€€€€€€Ù…É¥…¹Ğ€ôÙ…É¥…¹Ğ°(€€€€€€€€€€€€€€€€€€€Ñ½±•€ôÑ½±•°(€€€€€€€€€€€€€€€ô((€€€€€€€€€€€€€€€¥˜¹½Ğ™½Õ¹Ñ¡•¸(€€€€€€€€€€€€€€€€€€€™½Õ¹€ô•¹ÑÉä(€€€€€€€€€€€€€€€•±Í•¥˜•¹ÑÉä¹Ñ½±•…¹¹½Ğ™½Õ¹¹Ñ½±•Ñ¡•¸(€€€€€€€€€€€€€€€€€€€™½Õ¹€ô•¹ÑÉä(€€€€€€€€€€€€€€€•¹(€€€€€€€€€€€•¹(€€€€€€€•¹(€€€•¹((€€€É•ÑÕÉ¸™½Õ¹)•¹()™Õ¹Ñ¥½¸=PéA±…å•É!…Í=Ù•É±½…‘M±½ÑÑ• ¤(€€€É•ÑÕÉ¸Í•±˜é¥¹‘=Ù•É±½…‘M±½Ğ ¤øô¹¥°)•¹()™Õ¹Ñ¥½¸=Pé•ÑU±Ñ¥µ…Ñ•A½İ•È ¤(€€€¥˜¹½Ğ•ÑU¹¥ÑA½İ•ÈÑ¡•¸É•ÑÕÉ¸€À°€À•¹(€€€±½…°ÕÉÉ•¹Ğ°µ…á¥µÕ´€ô•ÑU¹¥ÑA½İ•È ‰Á±…å•Èˆ°U1Q%5Q}A=]I}QeA¤(€€€É•ÑÕÉ¸Ñ½¹Õµ‰•È¡ÕÉÉ•¹Ğ¤½È€À°Ñ½¹Õµ‰•È¡µ…á¥µÕ´¤½È€À)•¹()™Õ¹Ñ¥½¸=Pé¥¹‘=Ù•É±½…‘	Õ™˜ ¤(€€€¥˜¹½Ğ•Ñ9Õµ	Õ™™Ì½È¹½Ğ•ÑU¹¥Ñ	Õ™™%¹™¼Ñ¡•¸É•ÑÕÉ¸¹¥°•¹((€€€±½…°¹Õµ	Õ™™Ì€ô•Ñ9Õµ	Õ™™Ì ‰Á±…å•Èˆ¤½È€À(€€€™½È¥¹‘•à€ô€Ä°¹Õµ	Õ™™Ì‘¼(€€€€€€€±½…°¹…µ”°|°|°|°|°|°|°|°|°|°…¹±¥­=™˜°|°|°|°|°…‰¥±¥Ñå%€ô•ÑU¹¥Ñ	Õ™™%¹™¼ ‰Á±…å•Èˆ°¥¹‘•à¤(€€€€€€€±½…°¥½¸€ô€¡•ÑU¹¥Ñ	Õ™™%¹™¼…¹Í•±•Ğ È°•ÑU¹¥Ñ	Õ™™%¹™¼ ‰Á±…å•Èˆ°¥¹‘•à¤¤¤½È€ˆˆ(€€€€€€€±½…°Ù…É¥…¹Ğ€ôÍ•±˜é%‘•¹Ñ¥™åY…É¥…¹Ğ¡…‰¥±¥Ñå%°¹…µ”°¥½¸¤(€€€€€€€¥˜Ù…É¥…¹ĞÑ¡•¸(€€€€€€€€€€€É•ÑÕÉ¸ì(€€€€€€€€€€€€€€€‰Õ™™%¹‘•à€ô¥¹‘•à°(€€€€€€€€€€€€€€€…‰¥±¥Ñå%€ô…‰¥±¥Ñå%°(€€€€€€€€€€€€€€€¹…µ”€ô¹…µ”°(€€€€€€€€€€€€€€€¥½¸€ô¥½¸°(€€€€€€€€€€€€€€€…¹±¥­=™˜€ô…¹±¥­=™˜€ôôÑÉÕ”°(€€€€€€€€€€€€€€€Ù…É¥…¹Ğ€ôÙ…É¥…¹Ğ°(€€€€€€€€€€€ô(€€€€€€€•¹(€€€•¹((€€€É•ÑÕÉ¸¹¥°)•¹()™Õ¹Ñ¥½¸=PéÉ•…Ñ•QÉ…­•É]¥¹‘½Ü ¤(€€€±½…°İ¥¹‘½Ü€ô]%9=]}59HéÉ•…Ñ•Q½Á1•Ù•±]¥¹‘½Ü ‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•É]¥¹‘½Üˆ¤(€€€İ¥¹‘½ÜéM•Ñ¥µ•¹Í¥½¹Ì ÌÌÀ°€ÄÀà¤(€€€İ¥¹‘½ÜéM•Ñ±…µÁ•‘Q½MÉ••¸¡ÑÉÕ”¤(€€€İ¥¹‘½ÜéM•ÑÉ…İ…‰±”¡ÑÉÕ”¤(€€€İ¥¹‘½ÜéM•Ñ5½ÕÍ•¹…‰±•¡ÑÉÕ”¤(€€€İ¥¹‘½ÜéM•Ñ5½Ù…‰±”¡ÑÉÕ”¤(€€€İ¥¹‘½ÜéM•Ñ!¥‘‘•¸¡™…±Í”¤((€€€İ¥¹‘½Ü¹‰…­É½Õ¹€ôÉ•…Ñ•M½±¥¡İ¥¹‘½Ü°€‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•É	…­É½Õ¹ˆ°=1=IL¹‰œ¤(€€€İ¥¹‘½Ü¹‰…­É½Õ¹éM•Ñ½±½È¡=1=IL¹‰lÅt°=1=IL¹‰lÉt°=1=IL¹‰lÍt°€À¸äØ¤((€€€İ¥¹‘½Ü¹Ñ½Á	…È€ôÉ•…Ñ•M½±¥¡İ¥¹‘½Ü°€‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•ÉQ½Á	…Èˆ°=1=IL¹å…¸°€À°€À°€À°€´È¤(€€€İ¥¹‘½Ü¹‰½ÑÑ½µ	…È€ôÉ•…Ñ•M½±¥¡İ¥¹‘½Ü°€‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•É	½ÑÑ½µ	…Èˆ°=1=IL¹å…¹¥´°€À°€´ÄÀØ°€À°€À¤((€€€İ¥¹‘½Ü¹¡•…‘•È€ôÉ•…Ñ•1…‰•°¡İ¥¹‘½Ü°€‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•É!•…‘•Èˆ°€‰mÍ¼U%4Y¥Ñ…±¥”M¡…‘½İuğÄÙñ¡…É‘Í¡…‘½ÜéÑ¡¥¸ˆ°€‹1A!ƒqEUˆ°=1=IL¹å…¸¤(€€€İ¥¹‘½Ü¹¡•…‘•ÈéM•Ñ¹¡½È¡Q=A1P°İ¥¹‘½Ü°Q=A1P°€ÈÈ°€ÄÀ¤((€€€İ¥¹‘½Ü¹µ½Ù•!¥¹Ğ€ôÉ•…Ñ•1…‰•°¡İ¥¹‘½Ü°€‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•É5½Ù•!¥¹Ğˆ°€‰l¡5A¥uğÄÉñ¡…É‘Í¡…‘½ÜéÑ¡¥¸ˆ°€‰1%,€¬Iˆ°=1=IL¹µÕÑ•¤(€€€İ¥¹‘½Ü¹µ½Ù•!¥¹ĞéM•Ñ¥µ•¹Í¥½¹Ì ÄÈÀ°€Äà¤(€€€İ¥¹‘½Ü¹µ½Ù•!¥¹ĞéM•Ñ¹¡½È¡Q=AI%!P°İ¥¹‘½Ü°Q=AI%!P°€´ÄĞ°€ÄÀ¤(€€€İ¥¹‘½Ü¹µ½Ù•!¥¹ĞéM•Ñ!½É¥é½¹Ñ…±±¥¹µ•¹Ğ¡QaQ}1%9}I%!P¤((€€€±½…°¥½¹É…µ”€ô]%9=]}59HéÉ•…Ñ•½¹ÑÉ½° ‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•É%½¹É…µ”ˆ°İ¥¹‘½Ü°Q}=9QI=0¤(€€€¥½¹É…µ”éM•Ñ¥µ•¹Í¥½¹Ì ÔØ°€ÔØ¤(€€€¥½¹É…µ”éM•Ñ¹¡½È¡Q=A1P°İ¥¹‘½Ü°Q=A1P°€ÈÈ°€ĞÀ¤(€€€İ¥¹‘½Ü¹¥½¹É…µ”€ô¥½¹É…µ”((€€€İ¥¹‘½Ü¹¥½¹±½Ü€ôÉ•…Ñ•M½±¥¡¥½¹É…µ”°€‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•É%½¹±½Üˆ°ìÀ¸ÈØ°€Ä¸ÀÀ°€À¸ÔØ°€À¸ÄÉô¤(€€€İ¥¹‘½Ü¹¥½¹±½ÜM•Ñ¡½É¥±°¥˜™…±Í”Ñ¡•¸•¹€´´9½½ÀÕ…É™½È½±‘•ÈÁ…ÉÍ•ÉÌ¸(€€€İ¥¹‘½Ü¹¥½¹±½ÜéM•Ñ¹¡½È¡Q=A1P°¥½¹É…µ”°Q=A1P°€´Ì°€´Ì¤(€€€İ¥¹‘½Ü¹¥½¹±½ÜéM•Ñ¹¡½È¡	=QQ=5I%!P°¥½¹É…µ”°	=QQ=5I%!P°€Ì°€Ì¤((€€€İ¥¹‘½Ü¹¥½¹	½É‘•ÉQ½À€ôÉ•…Ñ•M½±¥¡¥½¹É…µ”°€‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•É%½¹	½É‘•ÉQ½Àˆ°=1=IL¹É•°€À°€À°€À°€´È¤(€€€İ¥¹‘½Ü¹¥½¹	½É‘•É	½ÑÑ½´€ôÉ•…Ñ•M½±¥¡¥½¹É…µ”°€‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•É%½¹	½É‘•É	½ÑÑ½´ˆ°=1=IL¹É•°€À°€´ÔĞ°€À°€À¤(€€€İ¥¹‘½Ü¹¥½¹	½É‘•É1•™Ğ€ôÉ•…Ñ•M½±¥¡¥½¹É…µ”°€‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•É%½¹	½É‘•É1•™Ğˆ°=1=IL¹É•°€À°€À°€´ÔĞ°€À¤(€€€İ¥¹‘½Ü¹¥½¹	½É‘•ÉI¥¡Ğ€ôÉ•…Ñ•M½±¥¡¥½¹É…µ”°€‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•É%½¹	½É‘•ÉI¥¡Ğˆ°=1=IL¹É•°€ÔĞ°€À°€À°€À¤((€€€İ¥¹‘½Ü¹¥½¸€ô]%9=]}59HéÉ•…Ñ•½¹ÑÉ½° ‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•É%½¸ˆ°¥½¹É…µ”°Q}QaQUI¤(€€€İ¥¹‘½Ü¹¥½¸éM•Ñ¹¡½É¥±°¡¥½¹É…µ”¤(€€€İ¥¹‘½Ü¹¥½¸éM•ÑQ•áÑÕÉ”¡YI%9QL¹‰…Í”¹¥½¸¤(€€€İ¥¹‘½Ü¹¥½¸éM•ÑQ•áÑÕÉ•½½É‘Ì À¸ÀØ°€À¸äĞ°€À¸ÀØ°€À¸äĞ¤((€€€İ¥¹‘½Ü¹…•¹Ñ	…È€ô]%9=]}59HéÉ•…Ñ•½¹ÑÉ½° ‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•É•¹Ñ	…Èˆ°İ¥¹‘½Ü°Q}QaQUI¤(€€€İ¥¹‘½Ü¹…•¹Ñ	…ÈéM•Ñ¥µ•¹Í¥½¹Ì Ğ°€ÔØ¤(€€€İ¥¹‘½Ü¹…•¹Ñ	…ÈéM•Ñ¹¡½È¡Q=AI%!P°¥½¹É…µ”°Q=A1P°€´Ø°€À¤(€€€M•Ñ½±½È¡İ¥¹‘½Ü¹…•¹Ñ	…È°=1=IL¹É•¤((€€€İ¥¹‘½Ü¹…‰¥±¥Ñå1…‰•°€ôÉ•…Ñ•1…‰•°¡İ¥¹‘½Ü°€‰±Á¡…MÅÕ…‘=Ù•É±½…‘QÉ…­•É‰¥±¥Ñå1,ãFãSÔÓECB1 ÔÑ Ô‚DƒÓ
