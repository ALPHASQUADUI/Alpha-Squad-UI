-- Ąlpha Şquad UI - Shared settings namespace
-- The Overload module currently owns its proven settings UI.
-- Future modules can register pages through this shared namespace.
AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Settings = AlphaSquadUI.Settings or {}
AlphaSquadUI.Settings.pages = AlphaSquadUI.Settings.pages or {}

function AlphaSquadUI.Settings.RegisterPage(id, definition)
    if not id then return end
    AlphaSquadUI.Settings.pages[id] = definition
end
