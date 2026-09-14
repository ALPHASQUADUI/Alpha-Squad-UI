-- Account/server preferences and character layouts, preserving existing namespaces.
local ASUI=AlphaSquadUI
local P={entries={}};ASUI.Preferences=P
local function Copy(value,seen,depth)
    if type(value)~="table" then
        if type(value)~="function" then return value end
        return nil
    end
    if (depth or 0)>12 then return nil end
    seen=seen or {};if seen[value] then return nil end;seen[value]=true
    local result={};local count=0
    for k,v in pairs(value) do
        count=count+1;if count>4096 then break end
        if type(k)=="string" or type(k)=="number" then result[k]=Copy(v,seen,(depth or 0)+1) end
    end
    seen[value]=nil;return result
end
local function Values(sv)
    local mt=getmetatable(sv)
    return mt and type(mt.__index)=="table" and mt.__index or sv
end
local function Transfer(source,target)
    local values=Values(target)
    for key,value in pairs(values) do
        if key~="version" and key~="default" and type(value)~="function" then target[key]=nil end
    end
    for key,value in pairs(Values(source)) do
        if key~="version" and key~="default" and type(value)~="function" then target[key]=Copy(value) end
    end
end
function P.Initialize()
    if P.sv then return end
    P.sv=ZO_SavedVars:NewAccountWide("AlphaSquadUISettingsSavedVariables",1,GetWorldName and GetWorldName() or nil,{crossSync=true})
    if type(P.sv.crossSync)~="boolean" then P.sv.crossSync=true end
end
function P.Open(module,name,namespace,defaults)
    P.Initialize()
    local entry=P.entries[module]
    if not entry then
        entry={name=name,namespace=namespace,defaults=defaults}
        entry.account=ZO_SavedVars:NewAccountWide(name,1,namespace,defaults)
        P.entries[module]=entry
    end
    if not P.sv.crossSync and not entry.character then
        entry.character=ZO_SavedVars:NewCharacterIdSettings(name,1,namespace,defaults)
        if entry.character.crossSyncSeeded~=true then Transfer(entry.account,entry.character);entry.character.crossSyncSeeded=true end
    end
    entry.current=P.sv.crossSync and entry.account or entry.character
    return entry.current
end
function P.SetCrossSync(enabled)
    P.Initialize();enabled=enabled==true
    if P.sv.crossSync==enabled then return end
    for module,entry in pairs(P.entries) do
        if not enabled and not entry.character then entry.character=ZO_SavedVars:NewCharacterIdSettings(entry.name,1,entry.namespace,entry.defaults) end
        local target=enabled and entry.account or entry.character
        Transfer(entry.current,target);target.crossSyncSeeded=true;entry.current=target
        if module=="Shell" then ASUI.Settings.layout=target
        else
            local instance=ASUI.Modules[module]
            if instance then
                instance.sv=target
                if instance.Group then instance.Group.sv=target.group end
            end
        end
    end
    P.sv.crossSync=enabled
end
