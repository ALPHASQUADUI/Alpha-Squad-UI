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
    return (string.lower(tostring(value)):gsub("\\", "/"))
end

-- Native dimensions already include inherited UI scale. Layout setters expect
-- unscaled units; converting once prevents shrinkage after a viewport change.
function AlphaSquadUI.Utils.GetLogicalDimensions(control)
    if not control then return 0, 0 end
    local scale = control.GetScale and tonumber(control:GetScale()) or 1
    if not scale or scale ~= scale or scale <= 0 or scale == math.huge then scale = 1 end
    local width = control.GetWidth and tonumber(control:GetWidth()) or 0
    local height = control.GetHeight and tonumber(control:GetHeight()) or 0
    if not width or width ~= width or width == math.huge or width == -math.huge then width = 0 end
    if not height or height ~= height or height == math.huge or height == -math.huge then height = 0 end
    return math.max(0, width / scale), math.max(0, height / scale)
end

function AlphaSquadUI.Utils.GetLogicalWidth(control)
    local width = AlphaSquadUI.Utils.GetLogicalDimensions(control)
    return width
end

function AlphaSquadUI.Utils.GetLogicalHeight(control)
    local _, height = AlphaSquadUI.Utils.GetLogicalDimensions(control)
    return height
end
