-- Ąlpha Şquad UI - Shared event registry
-- Kept intentionally lightweight. Modules own their gameplay event subscriptions.
AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Events = AlphaSquadUI.Events or {}

function AlphaSquadUI.Events.MakeNamespace(moduleName, eventName)
    return string.format("AlphaSquadUI_%s_%s", tostring(moduleName or "Core"), tostring(eventName or "Event"))
end
