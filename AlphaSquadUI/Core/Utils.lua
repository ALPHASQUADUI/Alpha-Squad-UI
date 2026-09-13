-- Ąlpha Şquad UI - Shared utilities
AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Utils = AlphaSquadUI.Utils or {}

function AlphaSquadUI.Utils.Clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value ~= value or value == math.huge or value == -math.huge then value = minimum end
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function AlphaSquadUI.Utils.Normalize(value)
    if not value then return "" end
    return string.lower(tostring(value)):gsub("\\", "/")
end
