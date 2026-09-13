-- Ąlpha Şquad UI - Shared settings registry and shell bridge
AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Settings = AlphaSquadUI.Settings or {}

local Settings = AlphaSquadUI.Settings
Settings.pages = Settings.pages or {}
Settings.mainWindow = Settings.mainWindow or nil
Settings.showPageCallback = Settings.showPageCallback or nil
Settings.refreshCallback = Settings.refreshCallback or nil
Settings.exclusiveWindows = Settings.exclusiveWindows or {}

function Settings.RefreshModuleVisibility()
    for _, module in pairs(AlphaSquadUI.Modules or {}) do
        if type(module) == "table" then
            if type(module.ApplyVisibility) == "function" then module:ApplyVisibility()
            elseif type(module.ApplyVisualSettings) == "function" then module:ApplyVisualSettings() end
        end
    end
end

function Settings.RegisterExclusiveWindow(id, control, closeCallback)
    if not id or not control then return end
    Settings.exclusiveWindows[id] = { control = control, close = closeCallback }
end

function Settings.AnyExclusiveWindowVisible()
    for _, entry in pairs(Settings.exclusiveWindows) do
        if not entry.control:IsHidden() then return true end
    end
    return false
end

function Settings.ShowExclusiveWindow(id)
    local target = Settings.exclusiveWindows[id]
    if not target then return false end
    for otherId, entry in pairs(Settings.exclusiveWindows) do
        if otherId ~= id and not entry.control:IsHidden() then
            if type(entry.close) == "function" then entry.close()
            else entry.control:SetHidden(true) end
        end
    end
    target.control:SetHidden(false)
    Settings.RefreshModuleVisibility()
    return true
end

function Settings.CloseMain()
    local entry = Settings.exclusiveWindows.settings
    if entry and type(entry.close) == "function" then entry.close()
    elseif Settings.mainWindow then Settings.mainWindow:SetHidden(true) end
    Settings.RefreshModuleVisibility()
end

-- Clipped mouse-wheel/slider scrolling with no animation or OnUpdate loop.
function Settings.CreateScrollArea(parent, name, x, y, width, height, contentHeight)
    local scroll = WINDOW_MANAGER:CreateControl(name, parent, CT_SCROLL)
    scroll:SetAnchor(TOPLEFT, parent, TOPLEFT, x, y)
    scroll:SetDimensions(width - 16, height)
    scroll:SetMouseEnabled(true)
    local child = WINDOW_MANAGER:CreateControl(name .. "Child", scroll, CT_CONTROL)
    child:SetAnchor(TOPLEFT, scroll, TOPLEFT, 0, 0)
    child:SetDimensions(width - 16, contentHeight or height)
    local slider = WINDOW_MANAGER:CreateControl(name .. "Bar", parent, CT_SLIDER)
    slider:SetAnchor(TOPLEFT, parent, TOPLEFT, x + width - 12, y)
    slider:SetDimensions(10, height)
    slider:SetOrientation(ORIENTATION_VERTICAL)
    slider:SetMouseEnabled(true)
    slider:SetValueStep(1)
    local thumb = "/esoui/art/miscellaneous/scrollbox_elevator.dds"
    slider:SetThumbTexture(thumb, thumb, thumb, 10, 40, 0, 0, 1, 1)
    scroll.offset = 0
    local function SetOffset(value)
        scroll.offset = math.max(0, math.min(scroll.maximum or 0, tonumber(value) or 0))
        scroll:SetVerticalScroll(scroll.offset)
    end
    local function UpdateBounds()
        scroll.maximum = math.max(0, child:GetHeight() - scroll:GetHeight())
        slider:SetMinMax(0, scroll.maximum)
        slider:SetHidden(scroll.maximum == 0)
        SetOffset(scroll.offset)
        slider:SetValue(scroll.offset)
    end
    local function OnWheel(_, delta)
        SetOffset(scroll.offset - delta * 40)
        slider:SetValue(scroll.offset)
    end
    slider:SetHandler("OnValueChanged", function(_, value) SetOffset(value) end)
    slider:SetHandler("OnMouseWheel", OnWheel)
    scroll:SetHandler("OnMouseWheel", OnWheel)
    scroll:SetHandler("OnRectHeightChanged", UpdateBounds)
    child:SetHandler("OnRectHeightChanged", UpdateBounds)
    scroll.UpdateBounds = UpdateBounds
    scroll.scrollbar = slider
    UpdateBounds()
    return child, scroll, slider
end

function Settings.RegisterPage(id, builder)
    if not id or type(builder) ~= "function" then return end
    Settings.pages[id] = builder
end

function Settings.GetPageBuilder(id)
    return id and Settings.pages[id] or nil
end

-- The visual shell is currently created by the proven Overload UI.
-- Modules talk only to this Core bridge so the shell can move later without
-- changing module APIs or slash commands.
function Settings.AttachShell(mainWindow, showPageCallback, refreshCallback)
    Settings.mainWindow = mainWindow
    Settings.showPageCallback = showPageCallback
    Settings.refreshCallback = refreshCallback
end

function Settings.RefreshMain()
    if Settings.refreshCallback then
        Settings.refreshCallback()
    end
end

function Settings.OpenPage(id)
    if not Settings.mainWindow then return false end
    if Settings.showPageCallback then
        Settings.showPageCallback(id)
    end
    if Settings.exclusiveWindows.settings then Settings.ShowExclusiveWindow("settings")
    else Settings.mainWindow:SetHidden(false) end
    Settings.RefreshMain()
    return true
end

Settings.RegisterPage("libraries", function(page, ui)
    page.contentHeight = 960
    local colors = ui.colors
    local title = ui.CreateLabel(page, "AlphaSquadLibrariesTitle", "ZoFontWinH2", "LIBRARIES & SHARING", colors.white)
    title:SetDimensions(650, 34)
    title:SetAnchor(TOPLEFT, page, TOPLEFT, 8, 2)
    title:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    local intro = ui.CreateLabel(page, "AlphaSquadLibrariesIntro", "ZoFontGameSmall",
        "Core trackers work without libraries. Install libraries for the features you want, then /reloadui.", colors.muted)
    intro:SetDimensions(650, 36)
    intro:SetAnchor(TOPLEFT, page, TOPLEFT, 9, 35)
    intro:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    intro:SetVerticalAlignment(TEXT_ALIGN_TOP)

    local rows = {
        { key = "LibGroupBroadcast", name = "LibGroupBroadcast", y = 76,
          text = "Requires LibAddonMenu-2.0 (38+) and LibDebugLogger. Full build senders need Alpha Squad UI or AlphaSquadBuildShare with experimental sharing enabled. Other compatible libraries can share partial sets or Ultimates through their own protocols." },
        { key = "LibGroupCombatStats", name = "LibGroupCombatStats", y = 184,
          text = "Requires LibCombat and LibGroupBroadcast. Enable ULT sharing in the library or a compatible sender addon. Receives compatible Ultimate shares without Alpha Squad UI. This library does not send full equipment, skills or Champion builds." },
        { key = "LibFoodDrinkBuff", name = "LibFoodDrinkBuff", y = 292,
          text = "Optional identification of food/drink buffs visible to your client. Enable the library; no extra configuration is needed. A native fallback remains available. Remote food still needs a compatible sender or observable native evidence." },
        { key = "LibCombat", name = "LibCombat", y = 400,
          text = "Required by LibGroupCombatStats. Install the current version and leave it enabled. No Alpha Squad specific settings are needed. Alpha Squad requests Ultimate sharing only. LibSets is not required and does not unlock remote equipment inspection." },
        { key = "LibAddonMenu2", name = "LibAddonMenu-2.0", y = 508,
          text = "Required by LibGroupBroadcast (version 38 or newer). Provides library settings panels. Leave it enabled, then open the library's settings to review sharing permissions. Alpha Squad's own settings window works without LibAddonMenu." },
        { key = "LibDebugLogger", name = "LibDebugLogger", y = 616,
          text = "Required by LibGroupBroadcast. Install and enable the current version. No Alpha Squad specific configuration or additional debug viewer is needed. Installing a library never grants permission to share another player's private build data." },
        { key = "LibSetDetection", name = "LibSetDetection", y = 724,
          text = "Install version 5+ with LibGroupBroadcast on both clients for named sets and separate front/back counts without Alpha Squad UI. Disclosed sets can count as last reported sources. Incognito choices are respected. This does not expose individual items, glyphs, Champion Points or skill bars." },
    }
    for index, data in ipairs(rows) do
        local card = ui.CreateCard(page, "AlphaSquadLibraryCard" .. index, 8, data.y, 658, 98, data.name, colors.orange)
        local status = ui.CreateLabel(card, "AlphaSquadLibraryStatus" .. index, "ZoFontGameSmall", "", colors.muted)
        status:SetDimensions(180, 24)
        status:SetAnchor(TOPRIGHT, card, TOPRIGHT, -14, 8)
        status:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
        local body = ui.CreateLabel(card, "AlphaSquadLibraryBody" .. index, "ZoFontGameSmall", data.text, colors.muted)
        body:SetDimensions(628, 58)
        body:SetAnchor(TOPLEFT, card, TOPLEFT, 14, 34)
        body:SetVerticalAlignment(TEXT_ALIGN_TOP)
        body:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
        local libraryKey = data.key
        ui.RegisterRefresher(function()
            local installed = rawget(_G, libraryKey) ~= nil
            status:SetText(installed and "INSTALLED" or "NOT INSTALLED")
            local c = installed and colors.green or colors.muted
            status:SetColor(c[1], c[2], c[3], 1)
        end)
    end

    local help = ui.CreateCard(page, "AlphaSquadLibraryHelp", 8, 838, 658, 104, "SETUP & PRIVACY", colors.cyan)
    local body = ui.CreateLabel(help, "AlphaSquadLibraryHelpText", "ZoFontGameSmall",
        "Install from Minion or ESOUI with each library's declared dependencies. Check ESO's Add-Ons menu for disabled or missing dependencies. Group membership alone cannot reveal another player's full build; unavailable evidence stays Unknown. No combat reports or history are needed for preparation.", colors.muted)
    body:SetDimensions(628, 68)
    body:SetAnchor(TOPLEFT, help, TOPLEFT, 14, 34)
    body:SetVerticalAlignment(TEXT_ALIGN_TOP)
    body:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
end)
