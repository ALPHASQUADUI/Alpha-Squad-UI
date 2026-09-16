-- Native ESO tooltips, raised above this addon's windows only while in use.
AlphaSquadUI = AlphaSquadUI or {}
local T = {}; AlphaSquadUI.Tooltips = T
local function L(text, ...)
    if AlphaSquadUI.L then return AlphaSquadUI.L(text, ...) end
    return select("#", ...) > 0 and string.format(text, ...) or text
end
local saved, hooked = {}, setmetatable({}, {__mode="k"})

local function Call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    if ok then return value end
end
local function Number(value, minimum, maximum)
    return type(value)=="number" and value==value and value>=minimum and value<=maximum and value or nil
end
local function Id(value) return Number(value,1,2147483647) and value%1==0 and value or nil end
local function OwnScale(control)
    local own = Number(Call(control, "GetControlScale"), 0.001, 100)
    if own and type(control.SetControlScale) == "function" then return own, "SetControlScale" end
    local scale = Number(Call(control, "GetScale"), 0.001, 100) or 1
    if Call(control, "GetInheritsScale") == true then
        local parent = Call(control, "GetParent")
        scale = scale / (Number(Call(parent, "GetScale"), 0.001, 100) or 1)
    end
    return scale, "SetScale"
end
local function Text(value, fallback)
    if type(value)~="string" or value=="" then return fallback and L(fallback) or "" end
    return (value:gsub("%^.*$",""):gsub("|[cC]%x%x%x%x%x%x",""):gsub("|[rR]",""):gsub("|","||"))
end
local function Save(control)
    if not control or control==GuiRoot or saved[control] then return end
    local scale, scaleMethod = OwnScale(control)
    saved[control]={tier=Call(control,"GetDrawTier"),layer=Call(control,"GetDrawLayer"),
        level=Call(control,"GetDrawLevel"),scale=scale,scaleMethod=scaleMethod,applied={}}
end
local function Restore()
    for control, state in pairs(saved) do
        for field, method in pairs({tier="SetDrawTier",layer="SetDrawLayer",level="SetDrawLevel"}) do
            local getter=({tier="GetDrawTier",layer="GetDrawLayer",level="GetDrawLevel"})[field]
            if state[field]~=nil and Call(control,getter)==state.applied[field] then Call(control,method,state[field]) end
        end
        if state.resized then
            local current=OwnScale(control)
            if math.abs(current-state.appliedScale)<0.000001 then Call(control,state.scaleMethod,state.scale) end
        end
    end
    saved={}
end
function T.Hide()
    if T.clearing then return end
    T.clearing=true
    local active=T.active
    local currentOwner=Call(active,"GetOwner")
    local reused=currentOwner~=nil and T.owner~=nil and currentOwner~=T.owner
    T.active,T.owner=nil,nil
    if active and not reused then
        if ClearTooltipImmediately then pcall(ClearTooltipImmediately,active)
        elseif ClearTooltip then pcall(ClearTooltip,active);Call(active,"SetHidden",true)
        else Call(active,"SetHidden",true) end
    end
    Restore()
    T.clearing=false
end
local function Watch(control)
    if not control or hooked[control] or not ZO_PreHookHandler then return end
    hooked[control]=true
    ZO_PreHookHandler(control,"OnHide",function()
        if T.owner==control or T.active==control then T.Hide() end
    end)
end
function T.Raise(tooltip)
    if not tooltip then return end
    local window=Call(tooltip,"GetOwningWindow")
    for _, control in ipairs({window or tooltip, tooltip}) do
        if control~=GuiRoot then
            Save(control)
            local applied=saved[control].applied
            if DT_HIGH~=nil then Call(control,"SetDrawTier",DT_HIGH);applied.tier=DT_HIGH end
            if DL_OVERLAY~=nil then Call(control,"SetDrawLayer",DL_OVERLAY);applied.layer=DL_OVERLAY end
            applied.level=math.max(10000,Number(Call(control,"GetDrawLevel"),0,1000000) or 0)
            Call(control,"SetDrawLevel",applied.level)
        end
    end
    T.active=tooltip
    Watch(tooltip)
end
local function Begin(owner, tooltip)
    T.Hide()
    if not tooltip or not InitializeTooltip then return false end
    local right=Number(Call(owner,"GetRight"),0,100000) or 0
    local width=Number(Call(GuiRoot,"GetWidth"),1,100000) or 1920
    local point,relative,offset=TOPLEFT,TOPRIGHT,10
    if right>width*0.60 then point,relative,offset=TOPRIGHT,TOPLEFT,-10 end
    local ok=pcall(InitializeTooltip,tooltip,owner,point,offset,0,relative)
    if not ok then return false end
    T.owner=owner
    T.Raise(tooltip)
    Watch(owner)
    return true
end
local function Finish(tooltip)
    T.Raise(tooltip)
    -- Native tooltips clamp position; very long source lists also fit screen height.
    local h=Number(Call(tooltip,"GetHeight"),1,100000)
    local rootH=Number(Call(GuiRoot,"GetHeight"),80,100000)
    local w=Number(Call(tooltip,"GetWidth"),1,100000)
    local rootW=Number(Call(GuiRoot,"GetWidth"),80,100000)
    local state=saved[tooltip]
    if h and rootH and w and rootW and state then
        -- GetWidth/GetHeight include inherited scaling; multiply the existing
        -- local scale by the fit ratio rather than applying that ratio twice.
        local fit=math.min(1,(rootH-32)/h,(rootW-32)/w)
        if fit < 1 then
            local scale = OwnScale(tooltip)
            state.resized=true
            state.appliedScale=scale*fit
            Call(tooltip,state.scaleMethod,state.appliedScale)
        end
    end
end
function T.ShowText(owner, text)
    if type(text)~="string" or text=="" or not SetTooltipText then T.Hide();return false end
    if not Begin(owner,InformationTooltip) then return false end
    local ok=pcall(SetTooltipText,InformationTooltip,Text(text))
    if not ok then T.Hide();return false end
    Finish(InformationTooltip);return true
end
local function Note(tooltip,text)
    if tooltip and tooltip.AddLine then Call(tooltip,"AddLine",text,"ZoFontGameSmall",0.72,0.74,0.78) end
end
function T.ShowItem(owner,item,remote)
    if type(item)~="table" then return T.ShowText(owner,L("Equipment information unavailable.")) end
    local link=item.link
    if type(link)=="string" and link:find("|H%d+:item:") and ItemTooltip and ItemTooltip.SetLink and Begin(owner,ItemTooltip) then
        -- Never resolve a remote item through this client's bag or equipped slots.
        local ok=pcall(ItemTooltip.SetLink,ItemTooltip,link)
        if ok then
            if item.reference then Note(ItemTooltip,L("Set reference item. This is not a report of the player's equipped trait or enchantment.")) end
            if remote==true or item.remote==true then
                Note(ItemTooltip,L("Set counters in this tooltip use your equipment. See this player's set summary for their totals."))
            end
            Finish(ItemTooltip);return true
        end
        T.Hide()
    end
    local lines={Text(item.name,"Equipment"),Text(item.slotName),Text(item.setName),
        L("Trait: %s",Text(item.traitName,"Unavailable")),Text(item.traitDescription)}
    if item.hasEnchant==false then lines[#lines+1]=L("No enchantment")
    elseif item.hasEnchant==true then
        lines[#lines+1]=L("Enchantment: %s",Text(item.enchantName,"Name unavailable"))
        lines[#lines+1]=Text(item.enchantDescription)
    else lines[#lines+1]=L("Enchantment unavailable") end
    return T.ShowText(owner,table.concat(lines,"\n"))
end
function T.ShowSkill(owner,skill,remote)
    if type(skill)~="table" or not Id(skill.id or skill.abilityId) then return T.ShowText(owner,L("Skill information unavailable.")) end
    local tooltip=AbilityTooltip or SkillTooltip
    local id=skill.id or skill.abilityId
    local craftedId=Id(skill.craftedId or skill.craftedAbilityId)
    local scripts=skill.scripts or {}
    local scriptIds={}
    for index=1,3 do scriptIds[index]=Id(type(scripts[index])=="table" and scripts[index].id or scripts[index]) end
    if craftedId and (skill.scriptsKnown~=true or not scriptIds[1] or not scriptIds[2] or not scriptIds[3]) then
        return T.ShowText(owner,Text(skill.name,"Scribed skill").."\n"..L("Committed scripts unavailable. A different player's scripts are not substituted."))
    end
    if craftedId and not (tooltip and tooltip.SetCraftedAbility) then
        local lines={Text(skill.name,"Scribed skill"),L("Committed scripts:")}
        for _, script in ipairs(scripts) do lines[#lines+1]=Text(type(script)=="table" and script.name,"Script description unavailable") end
        return T.ShowText(owner,table.concat(lines,"\n"))
    end
    if tooltip and tooltip.SetAbilityId and Begin(owner,tooltip) then
        local ok
        if craftedId and tooltip.SetCraftedAbility then
            ok=pcall(tooltip.SetCraftedAbility,tooltip,craftedId,scriptIds[1],scriptIds[2],scriptIds[3],0)
        else ok=pcall(tooltip.SetAbilityId,tooltip,id) end
        if ok then
            if remote==true or skill.remote==true then Note(tooltip,L("Ability preview: numbers use your character's stats.")) end
            Finish(tooltip);return true
        end
        T.Hide()
    end
    return T.ShowText(owner,Text(skill.name,"Skill").."\n"..Text(skill.description,"Description unavailable."))
end
function T.ShowChampion(owner,star)
    if type(star)~="table" or not Id(star.id) then return T.ShowText(owner,L("Champion star information unavailable.")) end
    local sc=AlphaSquadUI.Modules and AlphaSquadUI.Modules.SupportCoverage
    local info=star
    if sc and sc.DescribeChampionSkill then
        info=sc:DescribeChampionSkill(star.id,star.slot,star.points,star.pointsKnown==true) or star
    end
    local lines={Text(info.name,"Champion star")}
    if info.pointsKnown==true and Number(info.points,0,100000) then
        lines[#lines+1]=L("%s points invested • slotted",tostring(info.points))
        lines[#lines+1]=Text(info.description,"Description unavailable.")
        local bonus=Text(info.currentBonus)
        if bonus~="" then lines[#lines+1]=bonus end
    else lines[#lines+1]=L("Points invested unavailable. The star's exact bonus cannot be verified.") end
    return T.ShowText(owner,table.concat(lines,"\n\n"))
end
if AlphaSquadUI.Localization then
    AlphaSquadUI.Localization.RegisterCallback("tooltips", function() T.Hide() end)
end
