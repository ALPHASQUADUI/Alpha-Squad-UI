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
local function SaveBuildPause(value)
    local sc=ASUI.Modules.SupportCoverage
    local saved=Preference() or sc and sc.sv
    if saved then saved.buildSharingResumeRequired=value or nil end
end
local function Value(control)
    local ok,value=pcall(control.getFunc)
    if ok and type(value)=="boolean" then return value end
end
-- LGB removes its internal table after startup. Its native LAM Allow Sending
-- callbacks remain the authority; do not reach into upvalues or SavedVariables.
-- Ask its existing options producer for data, without creating/opening a panel.
local function CaptureNativeOptions()
    if S.capturingOptions then return nil end
    local lam,callbacks,panel=LibAddonMenu2,CALLBACK_MANAGER,LibGroupBroadcastOptions
    if not LibGroupBroadcast or not lam or type(lam.RegisterOptionControls)~="function"
        or not callbacks or type(callbacks.FireCallbacks)~="function" or not panel then return nil end
    local original=lam.RegisterOptionControls
    local captured
    local function capture(self,id,options,...)
        if id=="LibGroupBroadcastOptions" and type(options)=="table" then captured=options end
        return original(self,id,options,...)
    end
    S.capturingOptions=true
    lam.RegisterOptionControls=capture
    local ok=pcall(callbacks.FireCallbacks,callbacks,"LAM-BeforePanelControlsCreated",panel)
    lam.RegisterOptionControls=original
    S.capturingOptions=false
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
    local enabled,anyEnabled=true,false
    for _,protocol in pairs(protocols) do
        local value=Call(protocol,"IsEnabled")
        if value==nil then return false,"The library could not confirm its sharing setting.",false end
        if value~=true then enabled=false end
        if value==true then anyEnabled=true end
    end
    if kind=="builds" then
        local sc=ASUI.Modules.SupportCoverage
        if not sc or not sc.sv or not sc.share then
            return false,sc and sc.share and sc.share.error or "Build transport unavailable.",false
        end
        if sc.share.transportResumeRequired then
            if anyEnabled then
                return false,sc.share.controlError or "Native build sending could not be paused. Reload the UI before sharing again.",false
            end
            return false,"Build sharing is paused because queued data could not be cleared. Choose ON to retry safely.",true
        end
        if not sc.sv.shareData or not sc.sv.experimentalSharing then
            if sc.share.controlError then
                if anyEnabled or sc.share.queueRevokeFailed then return false,sc.share.controlError,not anyEnabled end
                sc.share.controlError=nil;S.errors[kind]=nil
            end
            return false,nil,true
        end
        if not sc.share.available then return false,sc.share.error or "Build transport unavailable.",false end
        if sc.share.controlError then
            if sc.share.queueRevokeFailed then return false,sc.share.controlError,false end
            -- Valid native controls may have been corrected in the library's
            -- panel after an earlier failed attempt in this interface.
            sc.share.controlError=nil;S.errors[kind]=nil
        end
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
    if not accepted and enabled then
        for id,value in pairs(previous) do pcall(manager.SetProtocolEnabled,manager,id,value) end
    end
    -- Native LGB prunes disabled messages immediately before broadcasting.
    return accepted
end
-- Used only when a queue cannot be revoked at a lifecycle boundary. Consent
-- remains unchanged; only our native protocols are blocked. A later external
-- OFF is indistinguishable from this OFF through LGB's supported API, so never
-- restore an old ON automatically. The next explicit ON performs revocation.
function S.SuspendBuildTransport()
    local sc=ASUI.Modules.SupportCoverage
    if not sc or not sc.share then return false end
    sc.share.transportResumeRequired=true
    SaveBuildPause(true)
    if S.nativeControls.builds==false then S.nativeControls.builds=nil end
    local accepted=SetProtocols("builds",false)
    if not accepted then
        sc.share.controlError="Queued build data could not be cleared and native controls are unavailable. Reload the UI before sharing again."
        S.errors.builds=sc.share.controlError
    end
    return accepted
end
function S.RestoreBuildTransport()
    local sc=ASUI.Modules.SupportCoverage
    return sc and sc.share and not sc.share.transportResumeRequired or false
end
function S.SetEnabled(kind,enabled)
    local definition=definitions[kind]
    if not definition then return false,"Unknown sharing option." end
    local prefs=Preference();enabled=enabled==true
    if S.nativeControls[kind]==false then S.nativeControls[kind]=nil end
    local sc=ASUI.Modules.SupportCoverage
    local revoked=true
    if kind=="builds" and sc and sc.sv then
        sc.sv.shareData=enabled;sc.sv.experimentalSharing=enabled
        if enabled then sc:InitializeSharing() end
        -- Replacing only our queued payloads also revokes them when the user
        -- switches OFF then ON before LGB reaches its next broadcast boundary.
        if sc.ClearQueuedBuildMessages and (not enabled or sc.share and sc.share.queueRevokeFailed) then
            revoked=sc:ClearQueuedBuildMessages()~=false
        end
    end
    local accepted=SetProtocols(kind,enabled and revoked)
    if not revoked then accepted=false end
    if kind=="builds" and sc and sc.share then
        if accepted then sc.share.transportResumeRequired=nil;SaveBuildPause(false)
        elseif not revoked then sc.share.transportResumeRequired=true;SaveBuildPause(true) end
    end
    if prefs then
        prefs[definition.preference]=enabled
        prefs[definition.preference.."Pending"]=not accepted and enabled or nil
        -- An explicit OFF is also retained if a dependency is temporarily absent.
        if not accepted and not enabled then prefs[definition.preference.."Pending"]=false end
    end
    S.errors[kind]=not accepted and "Sharing controls unavailable. Install or update the listed libraries." or nil
    if not revoked then
        S.errors[kind]=sc.share.queueRevokeNeedsGroup and "Sharing remains blocked until you join a group or reload the UI; previous queued data must be cleared first."
            or "Queued build data could not be revoked. Update LibGroupBroadcast or reload the UI before enabling sharing."
    end
    if kind=="ultimate" and accepted and enabled then S.StartUltimateSender() end
    if kind=="builds" and sc then
        if sc.share then sc.share.controlError=S.errors[kind] end
        if not enabled then
            if sc.ResetSharingState then sc:ResetSharingState("Sharing disabled")
            elseif sc.ResetBuildDetailState then sc:ResetBuildDetailState() end
        end
        if enabled and accepted and sc.ResumeBuildSharing then sc:ResumeBuildSharing() end
        if sc.UpdateRuntime then sc:UpdateRuntime() end
        if sc.MarkScanDirty then sc:MarkScanDirty("sharing changed") end
    end
    return accepted,S.errors[kind]
end
function S.StartUltimateSender()
    local enabled,_,available=S.GetStatus("ultimate")
    if not available or not enabled then return false end
    if S.ultimateSender then return true end
    if not LibGroupCombatStats or type(LibGroupCombatStats.RegisterAddon)~="function" then return false end
    local ok,result=pcall(LibGroupCombatStats.RegisterAddon,"AlphaSquadUIUltimateSender",{"ULT"})
    if ok and result then S.ultimateSender=result;return true end
    return false
end
function S.Initialize()
    local prefs=Preference()
    if not prefs then return end
    local sc=ASUI.Modules.SupportCoverage
    if prefs.buildSharingResumeRequired and sc and sc.share then sc.share.transportResumeRequired=true end
    -- New categories require an explicit ON. Existing preferences and native
    -- OFF choices survive upgrades; only an explicit pending action may turn
    -- a native protocol ON during a retry.
    local initializeDefaults=prefs.sharingDefaultsVersion~=1
    if initializeDefaults then prefs.sharingDefaultsVersion=1 end
    for _,kind in ipairs({"builds","ultimate","sets"}) do
        if S.nativeControls[kind]==false then S.nativeControls[kind]=nil end
        local definition=definitions[kind]
        local pending=prefs[definition.preference.."Pending"]
        local enabled=prefs[definition.preference]
        if kind=="builds" and type(enabled)~="boolean" then
            local sc=ASUI.Modules.SupportCoverage
            if sc and sc.sv and sc.sv.shareData==true and sc.sv.experimentalSharing==true then
                -- Older profiles stored accepted build consent in the module.
                -- Fresh module defaults are OFF, so this cannot opt in a new install.
                enabled=true;prefs[definition.preference]=true
            end
        end
        if type(enabled)~="boolean" then
            S.SetEnabled(kind,false)
        elseif type(pending)=="boolean" then
            local sc=ASUI.Modules.SupportCoverage
            if not (kind=="builds" and sc and sc.share and sc.share.transportResumeRequired) then
                S.SetEnabled(kind,pending)
            end
        elseif initializeDefaults then
            if not enabled then S.SetEnabled(kind,false)
            elseif kind=="builds" then
                local sc=ASUI.Modules.SupportCoverage
                if sc and sc.sv then
                    sc.sv.shareData=true;sc.sv.experimentalSharing=true
                    sc:InitializeSharing()
                end
            end
        else
            -- After setup, the actual native setting is authoritative. A later
            -- OFF in either interface must survive reloads and zone changes.
            local actual,_,available=S.GetStatus(kind)
            local sc=ASUI.Modules.SupportCoverage
            if available and not (kind=="builds" and sc and sc.share and sc.share.transportResumeRequired) then
                prefs[definition.preference]=actual
            end
        end
    end
    S.StartUltimateSender()
end
