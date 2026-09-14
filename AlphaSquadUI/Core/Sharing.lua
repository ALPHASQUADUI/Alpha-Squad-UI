-- Sharing choices are independent of HUD/module activation.
local ASUI=AlphaSquadUI
local S={errors={},nativeControls={}};ASUI.Sharing=S
local definitions={
    builds={addon="AlphaSquadUI",section="Alpha Squad UI — Build Sharing",preference="buildSharing",
        protocols={[510]="AlphaSquadSupportCoverage",[507]="AlphaSquadSupportDetails"}},
    ultimate={addon="LibGroupCombatStats",section="Group Combat Stats",preference="ultimateSharing",
        protocols={[20]="UltType",[21]="UltValue"}},
    sets={addon="LibSetDetection",section="Lib Set Detection",preference="setsSharing",protocols={[40]="SetData"}},
}
local function Call(object,method,...)
    if not object or type(object[method])~="function" then return nil end
    local ok,value=pcall(object[method],object,...);if ok then return value end
end
local function Preference() local p=ASUI.Preferences;if p then p.Initialize();return p.sv end end
local function Value(control)
    local ok,value=pcall(control.getFunc)
    if ok and type(value)=="boolean" then return value end
end
-- LGB removes its internal table after startup. Its native LAM Allow Sending
-- callbacks remain the authority; do not reach into upvalues or SavedVariables.
-- Ask its existing options producer for data, without creating/opening a panel.
local function CaptureNativeOptions()
    local lam,callbacks,panel=LibAddonMenu2,CALLBACK_MANAGER,LibGroupBroadcastOptions
    if not LibGroupBroadcast or not lam or type(lam.RegisterOptionControls)~="function"
        or not callbacks or type(callbacks.FireCallbacks)~="function" or not panel then return nil end
    local original=lam.RegisterOptionControls
    local captured
    local function capture(self,id,options,...)
        if id=="LibGroupBroadcastOptions" and type(options)=="table" then captured=options end
        return original(self,id,options,...)
    end
    lam.RegisterOptionControls=capture
    local ok=pcall(callbacks.FireCallbacks,callbacks,"LAM-BeforePanelControlsCreated",panel)
    lam.RegisterOptionControls=original
    if ok then return captured end
end
local function NativeControls(kind)
    if S.nativeControls[kind]~=nil then return S.nativeControls[kind] or nil end
    local function Unavailable() S.nativeControls[kind]=false;return nil end
    local definition=definitions[kind]
    if not definition then return nil end
    if kind~="builds" and type(rawget(_G,definition.addon))~="table" then return nil end
    local options=CaptureNativeOptions()
    if type(options)~="table" then return Unavailable() end
    local section,duplicate
    for _,data in ipairs(options) do
        if data.type=="submenu" and data.name==definition.section then
            if section then duplicate=true end
            section=data
        end
    end
    if not section or duplicate or type(section.controls)~="table" then return Unavailable() end
    local found,header={},nil
    for _,data in ipairs(section.controls) do
        if data.type=="header" then header=data.name
        elseif data.type=="checkbox" and data.name=="Allow Sending"
            and type(data.getFunc)=="function" and type(data.setFunc)=="function" then
            for id,name in pairs(definition.protocols) do
                if header==name then
                    if found[id] then return Unavailable() end
                    found[id]=data
                end
            end
        end
    end
    for id in pairs(definition.protocols) do if not found[id] or Value(found[id])==nil then return Unavailable() end end
    S.nativeControls[kind]=found
    return found
end
function S.GetProtocols(kind)
    local definition=definitions[kind]
    if not definition then return nil end
    local controls=NativeControls(kind)
    if not controls then return nil end
    local protocols={}
    for id,control in pairs(controls) do
        local option=control
        protocols[id]={IsEnabled=function()return Value(option) end}
    end
    return protocols,{SetProtocolEnabled=function(_,id,value) controls[id].setFunc(value) end}
end
function S.GetStatus(kind)
    local protocols=S.GetProtocols(kind)
    if not protocols then return false,S.errors[kind] or "Sharing controls unavailable. Install or update the listed libraries.",false end
    local enabled=true
    for _,protocol in pairs(protocols) do
        local value=Call(protocol,"IsEnabled")
        if value==nil then return false,"The library could not confirm its sharing setting.",false end
        if value~=true then enabled=false end
    end
    if kind=="builds" then
        local sc=ASUI.Modules.SupportCoverage
        if not sc or not sc.sv or not sc.share or not sc.share.available then
            return false,sc and sc.share and sc.share.error or "Build transport unavailable.",false
        end
        if not sc.sv.shareData or not sc.sv.experimentalSharing then return false,nil,true end
    end
    return enabled,S.errors[kind],true
end
function S.IsEnabled(kind) return (S.GetStatus(kind)) end
local function SetProtocols(kind,enabled)
    local protocols,manager=S.GetProtocols(kind)
    if not protocols or type(manager.SetProtocolEnabled)~="function" then return false end
    local previous={}
    for id,protocol in pairs(protocols) do
        previous[id]=Call(protocol,"IsEnabled")
        if type(previous[id])~="boolean" then return false end
    end
    local accepted=true
    for id,protocol in pairs(protocols) do
        local ok=pcall(manager.SetProtocolEnabled,manager,id,enabled)
        if not ok or Call(protocol,"IsEnabled")~=enabled then accepted=false end
    end
    if not accepted then
        for id,value in pairs(previous) do pcall(manager.SetProtocolEnabled,manager,id,value) end
    end
    -- Native LGB prunes disabled messages immediately before broadcasting.
    return accepted
end
function S.SetEnabled(kind,enabled)
    local definition=definitions[kind]
    if not definition then return false,"Unknown sharing option." end
    local prefs=Preference();enabled=enabled==true
    if S.nativeControls[kind]==false then S.nativeControls[kind]=nil end
    local sc=ASUI.Modules.SupportCoverage
    if kind=="builds" and sc and sc.sv then
        sc.sv.shareData=enabled;sc.sv.experimentalSharing=enabled
        if enabled then sc:InitializeSharing() end
    end
    local accepted=SetProtocols(kind,enabled)
    if prefs then
        prefs[definition.preference]=enabled
        prefs[definition.preference.."Pending"]=not accepted and enabled or nil
        -- An explicit OFF is also retained if a dependency is temporarily absent.
        if not accepted and not enabled then prefs[definition.preference.."Pending"]=false end
    end
    S.errors[kind]=not accepted and "Sharing controls unavailable. Install or update the listed libraries." or nil
    if kind=="ultimate" and accepted and enabled then S.StartUltimateSender() end
    if kind=="builds" and sc then
        if not enabled then sc:ResetSharingState("Sharing disabled") end
        if sc.UpdateRuntime then sc:UpdateRuntime() end
        sc:MarkScanDirty("sharing changed")
    end
    return accepted,S.errors[kind]
end
function S.StartUltimateSender()
    local prefs=Preference()
    local _,_,available=S.GetStatus("ultimate")
    if available and not S.IsEnabled("ultimate") then return false end
    if not available and prefs and prefs.ultimateSharing==false then return false end
    if S.ultimateSender then return true end
    if not LibGroupCombatStats or type(LibGroupCombatStats.RegisterAddon)~="function" then return false end
    local ok,result=pcall(LibGroupCombatStats.RegisterAddon,"AlphaSquadUIUltimateSender",{"ULT"})
    if ok and result then S.ultimateSender=result;return true end
    return false
end
function S.Initialize()
    local prefs=Preference()
    if not prefs then return end
    -- One account-wide installation/migration step: configure the three owned
    -- sharing categories, including libraries installed before Alpha Squad UI.
    -- Saved Alpha Squad ON/OFF choices take priority over the new ON default.
    local initializeDefaults=prefs.sharingDefaultsVersion~=1
    if initializeDefaults then prefs.sharingDefaultsVersion=1 end
    for _,kind in ipairs({"builds","ultimate","sets"}) do
        if S.nativeControls[kind]==false then S.nativeControls[kind]=nil end
        local definition=definitions[kind]
        local pending=prefs[definition.preference.."Pending"]
        if initializeDefaults then
            local enabled=prefs[definition.preference]
            if type(enabled)~="boolean" then enabled=true end
            S.SetEnabled(kind,enabled)
        elseif type(pending)=="boolean" then
            S.SetEnabled(kind,pending)
        else
            -- After setup, the actual native setting is authoritative. A later
            -- OFF in either interface must survive reloads and zone changes.
            local enabled,_,available=S.GetStatus(kind)
            if available then prefs[definition.preference]=enabled end
        end
    end
    S.StartUltimateSender()
end
