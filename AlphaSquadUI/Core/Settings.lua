-- Ąlpha Şquad UI - Shared settings registry and shell bridge
AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Settings = AlphaSquadUI.Settings or {}

local Settings = AlphaSquadUI.Settings
Settings.pages = Settings.pages or {}
Settings.mainWindow = Settings.mainWindow or nil
Settings.showPageCallback = Settings.showPageCallback or nil
Settings.refreshCallback = Settings.refreshCallback or nil

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
    Settings.mainWindow:SetHidden(false)
    Settings.RefreshMain()
    return true
end
