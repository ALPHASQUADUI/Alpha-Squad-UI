-- Bounded snapshot copy and optional pre-combat readiness settings.
-- Legacy expected-build templates are retained in SavedVariables but not evaluated.
local SC = AlphaSquadUI.Modules.SupportCoverage
local Audit = {}; SC.Audit = Audit

local function Copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = (depth or 0) + 1
    if depth > 12 then return nil end
    local result = {}
    for key, child in pairs(value) do result[key] = Copy(child, depth) end
    return result
end
Audit.Copy = Copy

function SC:EnsureAuditSettings()
    local sv = self.sv
    for key, default in pairs({checkFoodPresence=true, checkMissingGlyphs=true,
        experimentalSharing=false, checkPotionPresence=false}) do
        if type(sv[key]) ~= "boolean" then sv[key] = default end
    end
    sv.foodWarningSeconds = self.Clamp(tonumber(sv.foodWarningSeconds) or 300, 0, 1800)
    -- Preserve tracking OFF from the earlier effect-rule UI, without retaining
    -- combat uptime targets or report generation in the current runtime.
    sv.effectRules = type(sv.effectRules) == "table" and sv.effectRules or {}
    for key, rule in pairs(sv.effectRules) do
        if not SC.Catalog.effects[key] or type(rule) ~= "table" then
            sv.effectRules[key] = nil
        else
            sv.effectRules[key] = {enabled=rule.enabled}
            if type(rule.enabled) ~= "boolean" then sv.effectRules[key].enabled = nil end
        end
    end
end
