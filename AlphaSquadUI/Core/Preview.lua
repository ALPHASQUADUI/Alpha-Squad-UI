-- Presentation-only editor state. Never stored in SavedVariables or build data.
local ASUI = AlphaSquadUI
local Preview = { mode = "mixed" }
ASUI.Preview = Preview
local modes = {
    {id = "mixed", name = "Mixed states"},
    {id = "ready", name = "Ready / covered"},
    {id = "missing", name = "Missing / charging"},
    {id = "overload", name = "Overload"},
    {id = "live", name = "Live data"},
}
function Preview.GetMode() return Preview.mode end
function Preview.GetModes()
    local result = {}
    for i, value in ipairs(modes) do result[i] = {id = value.id, name = value.name} end
    return result
end
function Preview.SetMode(id)
    for _, value in ipairs(modes) do
        if value.id == id then
            if Preview.mode == id then return true end
            Preview.mode = id
            if ASUI.Layout and ASUI.Layout.active then ASUI.Layout.Refresh() end
            return true
        end
    end
    return false
end
