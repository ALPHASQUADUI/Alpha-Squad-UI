-- Specialized Overload behavior within the shared personal Ultimate tracker.
-- Only native, click-off-capable player effects can be cancelled.
local ASUI=AlphaSquadUI
local ULT=ASUI.Modules.ULTTracker
local O={active=false,level="none",cancelAttempted=false,lastAlertAt=0,lastReadyAt=0}
ULT.Overload=O
local EM=EVENT_MANAGER
local defaults={enabled=true,reserveCutoffEnabled=true,reserveThreshold=130,reserveWarningThreshold=160,
    reserveSound=true,readyReminderEnabled=true,readyReminderThreshold=400,readyReminderSound=true,disableInPvP=false}
local function Number(value,fallback,minimum,maximum)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge then return fallback end
    return math.max(minimum or 0,math.min(maximum or 1000000,value))
end
local function Now() return GetGameTimeMilliseconds and GetGameTimeMilliseconds() or 0 end
local function Moving() return ASUI.Layout and ASUI.Layout.IsMoving(ULT) end
local function Normalize(value) return string.lower(tostring(value or "")):gsub("\\","/") end
function O:IsAbility(id,name,icon)
    if id==30366 or id==30381 then return true end
    local texture=Normalize(icon)
    if texture:find("ability_sorcerer_power_overload",1,true) or texture:find("ability_sorcerer_energy_overload",1,true)
        or texture:find("ability_sorcerer_overload",1,true) then return true end
    if GetAbilityIcon and type(id)=="number" and id>0 and id<=2147483647 and id%1==0 then
        local native=Normalize(GetAbilityIcon(id))
        if native~=texture and (native:find("ability_sorcerer_overload",1,true)
            or native:find("ability_sorcerer_power_overload",1,true) or native:find("ability_sorcerer_energy_overload",1,true)) then return true end
    end
    return false
end
function O:IsBar(bar)
    if not bar then return false end
    if type(bar.isOverload)=="boolean" then return bar.isOverload end
    return self:IsAbility(bar.abilityId,bar.name,bar.icon)
end
function O:Config() return ULT.sv and ULT.sv.overload end
function O:Suppressed()
    local config=self:Config()
    if not config or not config.enabled then return true end
    return config.disableInPvP and ((IsInCampaign and IsInCampaign()) or (IsActiveWorldBattleground and IsActiveWorldBattleground())
        or (IsPlayerInAvAWorld and IsPlayerInAvAWorld())) or false
end
function O:GetPriorityBar()
    if self:Suppressed() then return nil end
    local current=ULT:GetActiveBarCategory()
    for _,key in ipairs({"primary","backup"}) do
        local bar=ULT.bars[key]
        if self:IsBar(bar) and bar.category==current then return key end
    end
    for _,key in ipairs({"primary","backup"}) do if self:IsBar(ULT.bars[key]) then return key end end
end
function O:CanAct()
    local settings=ASUI.Settings
    return ULT.sv and ULT.sv.enabled and ULT.sv.visible and not ULT.loading and not ULT.uiObscured
        and not Moving() and not self:Suppressed() and self:GetPriorityBar()~=nil
        and not (settings and settings.AnyExclusiveWindowVisible and settings.AnyExclusiveWindowVisible())
end
function O:FindActiveBuff()
    if not GetNumBuffs or not GetUnitBuffInfo then return nil end
    local count=math.floor(Number(GetNumBuffs("player"),0,0,512))
    for index=1,count do
        local name,_,_,_,_,icon,_,_,_,_,abilityId,canClickOff=GetUnitBuffInfo("player",index)
        if self:IsAbility(abilityId,name,icon) then return {index=index,canClickOff=canClickOff==true} end
    end
end
function O:TryCancel(reason)
    if not self:CanAct() then return false,"Unavailable in this context" end
    local buff=self:FindActiveBuff()
    if not buff or not buff.canClickOff or not CancelBuff then return false,"Use your Ultimate key to switch Overload off" end
    CancelBuff(buff.index)
    if zo_callLater then
        zo_callLater(function() if ULT.initialized and ULT.sv.enabled and not ULT.loading then ULT:Refresh("Overload cancellation") end end,80)
        zo_callLater(function() if ULT.initialized and ULT.sv.enabled and not ULT.loading then ULT:Refresh("Overload cancellation verify") end end,220)
    end
    return true,"Cancellation requested"
end
function O:PlayAlert(ready,force)
    if not self:CanAct() or not PlaySound or not SOUNDS then return end
    local config=self:Config()
    if ready and not config.readyReminderSound or not ready and not config.reserveSound then return end
    local key=ready and "lastReadyAt" or "lastAlertAt"
    local interval=ready and 12000 or (self.level=="critical" and 1400 or 2200)
    if not force and Now()-(self[key] or 0)<interval then return end
    self[key]=Now()
    local sound=ready and (SOUNDS.GENERAL_ALERT_NOTIFICATION or SOUNDS.POSITIVE_CLICK)
        or (SOUNDS.GENERAL_ALERT_ERROR or SOUNDS.GENERAL_ALERT_NOTIFICATION or SOUNDS.NEGATIVE_CLICK)
    if sound then PlaySound(sound) end
end
function O:Update(current,reason)
    self:UpdateRuntime()
    local config=self:Config()
    local priority=self:GetPriorityBar()
    if not config or not priority then
        self.active=false;self.level="none";self.cancelAttempted=false;self.expectedUntil=nil;self.ready=false
        for _,bar in pairs(ULT.bars) do bar.overload=false;bar.overloadState=nil end
        return
    end
    if reason~="power" or self.buffDirty or self.buffChecked~=true then
        self.cachedBuff=self:FindActiveBuff();self.buffChecked=true;self.buffDirty=false
    end
    local buff=self.cachedBuff
    local toggled,knownToggle=false,false
    for _,bar in pairs(ULT.bars) do
        if self:IsBar(bar) and IsSlotToggled then
            local value=IsSlotToggled(ULT.ULTIMATE_SLOT,bar.category)
            if type(value)=="boolean" then knownToggle=true;toggled=toggled or value end
        end
    end
    local active=buff~=nil or toggled
    if not buff and not knownToggle and self.expectedUntil and Now()<self.expectedUntil then active=self.expectedActive==true end
    self.active=active and current>0
    local previous=self.level
    self.level="none"
    if self.active and config.reserveCutoffEnabled then
        if current<=config.reserveThreshold then self.level="critical"
        elseif current<=config.reserveWarningThreshold then self.level="warning" end
    end
    if self.level~="critical" then self.cancelAttempted=false end
    local previousReady=self.ready
    local ready=not self.active and config.readyReminderEnabled and current>=config.readyReminderThreshold
    self.ready=ready
    for _,bar in pairs(ULT.bars) do
        bar.overload=self:IsBar(bar)
        bar.overloadState=bar.overload and (self.level~="none" and self.level or self.active and "active" or ready and "ready" or "off") or nil
    end
    if self:CanAct() then
        if self.level~="none" then
            self:PlayAlert(false,previous~=self.level)
            if self.level=="critical" and not self.cancelAttempted then self.cancelAttempted=true;self:TryCancel("reserve") end
        elseif ready then self:PlayAlert(true,not previousReady) end
    end
end
function O:OnUsed(slot)
    if slot~=ULT.ULTIMATE_SLOT or self:Suppressed() or Moving() then return end
    for _,bar in pairs(ULT.bars) do
        if bar.category==ULT:GetActiveBarCategory() and self:IsBar(bar) then
            self.expectedActive=not self.active;self.expectedUntil=Now()+700;return
        end
    end
end
function O:UpdateRuntime()
    local config=self:Config()
    local active=(ULT.sv and ULT.sv.enabled and config and config.enabled and not ULT.loading and self:GetPriorityBar()~=nil)==true
    if self.eventsActive==active then return end
    self.eventsActive=active==true
    local name="AlphaSquadUI_ULTTracker_OverloadEffect"
    if not EVENT_EFFECT_CHANGED then return end
    if not active then
        EM:UnregisterForEvent(name,EVENT_EFFECT_CHANGED)
        self.cachedBuff=nil;self.buffChecked=false;self.buffDirty=true
        self.active=false;self.level="none";self.ready=false;self.cancelAttempted=false
        return
    end
    EM:RegisterForEvent(name,EVENT_EFFECT_CHANGED,function(_,_,_,effectName,unitTag,_,_,_,icon,_,_,_,_,_,_,abilityId)
        if unitTag~="player" or not O:IsAbility(abilityId,effectName,icon) or O.refreshPending then return end
        O.buffDirty=true;O.refreshPending=true
        zo_callLater(function() O.refreshPending=false;if O.eventsActive and not ULT.loading then ULT:Refresh("Overload effect") end end,30)
    end)
    if REGISTER_FILTER_UNIT_TAG then EM:AddFilterForEvent(name,EVENT_EFFECT_CHANGED,REGISTER_FILTER_UNIT_TAG,"player") end
end
function O:SetOption(key,value)
    local config=self:Config()
    if not config or defaults[key]==nil then return false end
    if type(defaults[key])=="boolean" then value=value==true
    elseif key=="readyReminderThreshold" then value=math.floor(Number(value,defaults[key],100,500))
    else value=math.floor(Number(value,defaults[key],25,500)) end
    config[key]=value
    if config.reserveWarningThreshold<config.reserveThreshold then config.reserveWarningThreshold=config.reserveThreshold end
    self.cancelAttempted=false;self.lastReadyAt=0;self:UpdateRuntime()
    ULT:Refresh("Overload option");if ULT.RefreshSettings then ULT:RefreshSettings() end
    return true
end
function O:Migrate(finalize)
    local adopted=false
    if not ULT.sv then return end
    local sv=ULT.sv
    if type(sv.overload)~="table" then sv.overload={} end
    if sv.unifiedUltimateVersion~=1 then
        local namespace=GetWorldName and GetWorldName() or nil
        local legacy=ZO_SavedVars:NewAccountWide("AlphaSquadOverloadTrackerSavedVariables",1,namespace,{})
        if ASUI.Preferences and ASUI.Preferences.sv and ASUI.Preferences.sv.crossSync==false and ZO_SavedVars.NewCharacterIdSettings then
            local character=ZO_SavedVars:NewCharacterIdSettings("AlphaSquadOverloadTrackerSavedVariables",1,namespace,{})
            if character.crossSyncSeeded then legacy=character end
        end
        for key,default in pairs(defaults) do
            local source=legacy[key]
            if key=="enabled" then source=legacy.addonEnabled end
            if sv.overload[key]==nil and type(source)==type(default) then sv.overload[key]=source end
        end
        local used=legacy.addonEnabled==true and legacy.visible~=false and (self:IsBar(ULT.bars.primary) or self:IsBar(ULT.bars.backup))
        if used and finalize~=false then
            adopted=true
            sv.enabled=true;sv.visible=true
            sv.x=Number(legacy.x,sv.x,-100000,100000);sv.y=Number(legacy.y,sv.y,-100000,100000)
            sv.scale=Number(legacy.scale,sv.scale,60,180);sv.positionSaved=legacy.positionSaved==true
        end
        if finalize~=false then sv.unifiedUltimateVersion=1 end
    end
    for key,default in pairs(defaults) do
        local value=sv.overload[key]
        if type(default)=="boolean" then if type(value)~="boolean" then sv.overload[key]=default end
        else sv.overload[key]=math.floor(Number(value,default,key=="readyReminderThreshold" and 100 or 25,500)) end
    end
    if sv.overload.reserveWarningThreshold<sv.overload.reserveThreshold then sv.overload.reserveWarningThreshold=sv.overload.reserveThreshold end
    return adopted
end
function O:RegisterCommands()
    SLASH_COMMANDS["/asoverload"]=function(argument)
        local command=Normalize(argument):match("^%s*(.-)%s*$")
        if command=="" then
            if ASUI.Shell and ASUI.Shell.ToggleSettingsWindow then ASUI.Shell:ToggleSettingsWindow()
            elseif ASUI.Settings then ASUI.Settings.OpenPage("ulttracker") end
        elseif command=="settings" or command=="options" then ASUI.Settings.OpenPage("ultoverload")
        elseif command=="on" or command=="enable" then O:SetOption("enabled",true)
        elseif command=="off" or command=="disable" then O:SetOption("enabled",false)
        elseif command=="reserve on" or command=="reserve off" then O:SetOption("reserveCutoffEnabled",command=="reserve on")
        elseif command=="reserve" or command=="reserve toggle" then O:SetOption("reserveCutoffEnabled",not O:Config().reserveCutoffEnabled)
        elseif command=="ready on" or command=="ready off" then O:SetOption("readyReminderEnabled",command=="ready on")
        elseif command=="ready sound on" or command=="ready sound off" then O:SetOption("readyReminderSound",command=="ready sound on")
        elseif command:match("^threshold%s+%d+$") then O:SetOption("reserveThreshold",tonumber(command:match("(%d+)$")))
        elseif command:match("^warning%s+%d+$") then O:SetOption("reserveWarningThreshold",tonumber(command:match("(%d+)$")))
        elseif command:match("^ready%s+%d+$") then O:SetOption("readyReminderThreshold",tonumber(command:match("(%d+)$")))
        elseif command=="toggle" then ULT:SetVisible(not ULT.sv.visible)
        elseif command=="reset" then if ASUI.Layout then ASUI.Layout.Start();ASUI.Layout.Select(ULT);ASUI.Layout.ResetSelected() end
        elseif command=="website" or command=="site" or command=="community" then if ASUI.Settings then ASUI.Settings.OpenLink(ASUI.website or "https://alphasquadeso.com/") end
        elseif command=="status" or command=="inspect" or command=="diagnostics" then
            if d then d(string.format("Overload behavior: %s • State: %s • Warning: %d • Auto-stop: %d • Ready: %d",
                O:Config().enabled and "ON" or "OFF",O.active and "ACTIVE" or "OFF",O:Config().reserveWarningThreshold,O:Config().reserveThreshold,O:Config().readyReminderThreshold)) end
        elseif command=="readytest" or command=="testready" or command=="debug" then ASUI.Settings.OpenPage("ultoverload")
        elseif command=="move" or command=="unlock" then if ASUI.Layout then ASUI.Layout.Start() end
        elseif command=="lock" then if ASUI.Layout then ASUI.Layout.Finish() end
        elseif command=="cancel" or command=="stop" then local _,message=O:TryCancel("manual");if d then d(message) end
        elseif command=="show" then ULT:SetVisible(true)
        elseif command=="hide" then ULT:SetVisible(false)
        else if d then d("/asoverload • settings • on/off • cancel • /asmove") end end
    end
end
