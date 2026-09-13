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
        "Choose the group features you need. Install their libraries with Minion or ESOUI, then /reloadui.", colors.muted)
    intro:SetDimensions(650, 36)
    intro:SetAnchor(TOPLEFT, page, TOPLEFT, 9, 35)
    intro:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    intro:SetVerticalAlignment(TEXT_ALIGN_TOP)

    local rows = {
        { key = "LibGroupBroadcast", name = "LibGroupBroadcast", y = 76,
          text = "For build exchange. Requires LibAddonMenu-2.0 (38+) and LibDebugLogger. Use Alpha Squad UI or AlphaSquadBuildShare on each sender. Enable build exchange and Share my build in Support Coverage to send your build." },
        { key = "LibGroupCombatStats", name = "LibGroupCombatStats", y = 184,
          text = "For group Ultimates. Requires LibCombat and LibGroupBroadcast. Enable ULT sharing in its settings or a compatible sender addon. Group members do not need Alpha Squad UI. This does not share a complete build." },
        { key = "LibFoodDrinkBuff", name = "LibFoodDrinkBuff", y = 292,
          text = "For more food and drink recognition. Install and enable it; no additional setup is needed. Only buffs visible to your client or reported by a compatible sender can be checked. Unavailable information stays Unknown." },
        { key = "LibCombat", name = "LibCombat", y = 400,
          text = "Required by LibGroupCombatStats. Install the current version and leave it enabled. No Alpha Squad configuration is needed. Alpha Squad requests Ultimate sharing only; it does not collect combat reports." },
        { key = "LibAddonMenu2", name = "LibAddonMenu-2.0", y = 508,
          text = "Required by LibGroupBroadcast: version 38 or newer. Leave it enabled to access library settings and sharing options. Alpha Squad has its own settings window and does not otherwise require this library." },
        { key = "LibDebugLogger", name = "LibDebugLogger", y = 616,
          text = "Required by LibGroupBroadcast. Install and enable the current version. No Alpha Squad configuration or additional log viewer is needed. Your sharing settings still control which build details you send." },
        { key = "LibSetDetection", name = "LibSetDetection", y = 724,
          text = "For shared set names and front/back counts without the full addon. Install version 5+ and LibGroupBroadcast on both clients. Incognito choices are respected. Reports do not include individual items, traits, glyphs, CP or skill bars." },
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
        "Missing data? Check ESO's Add-Ons menu for disabled dependencies, then confirm the sender has enabled sharing. Group membership alone does not reveal a complete build. Build exchange uses unreserved transport IDs; leave it off outside coordinated groups.", colors.muted)
    body:SetDimensions(628, 68)
    body:SetAnchor(TOPLEFT, help, TOPLEFT, 14, 34)
    body:SetVerticalAlignment(TEXT_ALIGN_TOP)
    body:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
end)
