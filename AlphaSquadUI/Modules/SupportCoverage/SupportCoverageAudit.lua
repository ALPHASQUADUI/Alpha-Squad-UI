-- Bounded snapshot copy and optional pre-combat readiness settings.
-- Legacy expected-build templates are retained in SavedVariables but not evaluated.
local SC = AlphaSquadUI.Modules.SupportCoverage
local Audit = {}; SC.Audit = Audit

local function Copy(value, depth, state)
    if type(value) ~= "table" then return value end
    depth = (depth or 0) + 1
    state = state or {seen={}, remaining=8192}
    if depth > 12 or state.remaining <= 0 or state.seen[value] then return nil end
    state.seen[value]=true
    local result = {}
    for key, child in pairs(value) do
        if state.remaining <= 0 then break end
        state.remaining=state.remaining-1
        if type(key)=="string" or type(key)=="number" or type(key)=="boolean" then
            result[key] = Copy(child, depth, state)
        end
    end
    state.seen[value]=nil
    return result
end
Audit.Copy = Copy

function SC:EnsureAuditSettings()
    local sv = self.sv
    for key, default in pairs({checkFoodPresence=true, checkMissingGlyphs=true,
        experimentalSharing=true, checkPotionPresence=false}) do
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
