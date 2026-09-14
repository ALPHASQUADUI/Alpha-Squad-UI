-- One place for explicit sharing choices. UI module state is independent.
local ASUI=AlphaSquadUI
local S={};ASUI.Sharing=S
local definitions={
    builds={addon="AlphaSquadUI",protocols={[510]="AlphaSquadSupportCoverage",[507]="AlphaSquadSupportDetails"}},
    ultimate={addon="LibGroupCombatStats",protocols={[20]="UltType",[21]="UltValue"}},
    sets={addon="LibSetDetection",protocols={[40]="SetData"}},
}
local function Call(object,method,...)
    if not object or type(object[method])~="function" then return nil end
    local ok,value=pcall(object[method],object,...);if ok then return value end
end
local function Preference() local p=ASUI.Preferences;if p then p.Initialize();return p.sv end end
-- LGB has no public toggle API. This isolated bridge uses its own settings
-- manager after checking BOTH handler ownership and protocol identities. If the
-- implementation changes, settings remain untouched and the native panel opens.
function S.GetProtocols(kind)
    local definition=definitions[kind]
    local internal=LibGroupBroadcast and LibGroupBroadcast.internal
    local manager=internal and internal.protocolManager
    local handlers=internal and Call(internal.handlerManager,"GetHandlers")
    if not definition or not manager or type(handlers)~="table" then return nil end
    local found={}
    for _,handler in ipairs(handlers) do
        if handler.addonName==definition.addon then
            for _,protocol in ipairs(handler.protocols or {}) do
                local id=Call(protocol,"GetId")
                if id and definition.protocols[id]==Call(protocol,"GetName") then found[id]=protocol end
            end
        end
    end
    for id in pairs(definition.protocols) do if not found[id] then return nil end end
    return found,manager
end
function S.OpenNativeSettings()
    if LibAddonMenu2 and LibAddonMenu2.OpenToPanel and LibGroupBroadcastOptions then
        ASUI.Settings.CloseMain();LibAddonMenu2:OpenToPanel(LibGroupBroadcastOptions);return true
    end
    return false
end
function S.IsEnabled(kind)
    local prefs=Preference()
    if kind=="builds" then
        local sc=ASUI.Modules.SupportCoverage
        return sc and sc.sv and sc.sv.shareData==true and sc.sv.experimentalSharing==true or false
    end
    local protocols=S.GetProtocols(kind)
    if not protocols then return false end
    for _,protocol in pairs(protocols) do if Call(protocol,"IsEnabled")~=true then return false end end
    return not prefs or prefs[kind.."Sharing"]~=false
end
function S.SetEnabled(kind,enabled)
    local prefs=Preference();enabled=enabled==true
    local sc=ASUI.Modules.SupportCoverage
    if kind=="builds" and sc and sc.sv then
        sc.sv.shareData=enabled;sc.sv.experimentalSharing=enabled
        if prefs then prefs.buildSharing=enabled end
        if enabled then sc:InitializeSharing() end
    end
    local protocols,manager=S.GetProtocols(kind)
    if protocols and type(manager.SetProtocolEnabled)=="function" then
        for id in pairs(protocols) do Call(manager,"SetProtocolEnabled",id,enabled) end
        -- Remove only messages disabled by these settings, never other protocols.
        Call(manager,"RemoveDisabledMessages")
        if prefs then prefs[kind.."Sharing"]=enabled end
    elseif kind~="builds" then S.OpenNativeSettings();return false end
    if kind=="ultimate" and enabled then S.StartUltimateSender() end
    if kind=="builds" and sc then
        if not enabled then sc:ResetSharingState("Sharing disabled") end
        if sc.UpdateRuntime then sc:UpdateRuntime() end
        sc:MarkScanDirty("sharing changed")
    end
    return kind=="builds" or protocols~=nil
end
function S.StartUltimateSender()
    local prefs=Preference()
    if prefs and prefs.ultimateSharing==false then return false end
    if S.ultimateSender then return true end
    if not LibGroupCombatStats or type(LibGroupCombatStats.RegisterAddon)~="function" then return false end
    local ok,result=pcall(LibGroupCombatStats.RegisterAddon,"AlphaSquadUIUltimateSender",{"ULT"})
    if ok and result then S.ultimateSender=result;return true end
    return false
end
