-- Ąlpha Şquad UI - Shared theme tokens
AlphaSquadUI = AlphaSquadUI or {}
AlphaSquadUI.Theme = AlphaSquadUI.Theme or {}

local Theme = AlphaSquadUI.Theme
Theme.colors = Theme.colors or {
    bg = {0.010, 0.016, 0.030, 0.96},
    panel = {0.020, 0.030, 0.052, 0.98},
    panelActive = {0.050, 0.035, 0.020, 0.99},
    orange = {1.00, 0.58, 0.16, 1.00},
    white = {0.95, 0.97, 1.00, 1.00},
    muted = {0.53, 0.62, 0.72, 1.00},
    green = {0.34, 0.82, 0.52, 1.00},
    red = {1.00, 0.30, 0.35, 1.00},
    gold = {0.97, 0.78, 0.30, 1.00},
    cyan = {0.20, 0.82, 1.00, 1.00},
    cyanDim = {0.10, 0.36, 0.49, 1.00},
}

-- UTF-8 aware, static color markup: no animation and no frame callbacks.
function Theme.Gradient(text,first,last)
    -- Do not use byte ranges in Lua patterns: the client's Unicode-aware
    -- matcher can discard extended Latin letters such as Ą and Ş.
    text=tostring(text)
    local chars={};local position=1
    while position<=#text do
        local lead=string.byte(text,position)
        local length=lead>=240 and lead<=244 and 4 or lead>=224 and lead<=239 and 3 or lead>=194 and lead<=223 and 2 or 1
        local lastByte=math.min(#text,position+length-1)
        chars[#chars+1]=string.char(string.byte(text,position,lastByte))
        position=lastByte+1
    end
    local out={}
    for i,char in ipairs(chars) do
        local t=(i-1)/math.max(1,#chars-1)
        local r=math.floor(first[1]+(last[1]-first[1])*t+0.5)
        local g=math.floor(first[2]+(last[2]-first[2])*t+0.5)
        local b=math.floor(first[3]+(last[3]-first[3])*t+0.5)
        out[#out+1]=string.format("|c%02X%02X%02X%s|r",r,g,b,char)
    end
    return table.concat(out)
end
Theme.brandText=Theme.Gradient("Ąlpha Şquad",{255,111,12},{255,184,62}).." |cFFFFFFUI|r"
Theme.authorText=Theme.Gradient("@SeRuM1",{78,158,255},{102,222,255})
function Theme.Brand(section) return Theme.brandText..(section and ("  •  "..section) or "") end
function Theme.PlayerName(name)
    local clean=(tostring(name or ""):gsub("|[cC]%x%x%x%x%x%x",""):gsub("|[rR]",""):gsub("|","||"))
    return clean=="@SeRuM1" and Theme.authorText or clean
end

-- Theme changes repaint existing native controls once. Status, quality and
-- Champion colors are shared semantic tokens and never vary between presets.
local DEFAULT_PRESET="obsidian"
local presetOrder={"ember","tactical","obsidian"}
local presets={
    ember={name="Ember Classic",description="Signature orange borders, warm panels and clear accent lines.",
        colors={bg={0.010,0.012,0.017,0.97},panel={0.035,0.026,0.021,0.97},
            panelActive={0.095,0.050,0.015,0.99},border={0.34,0.19,0.075,0.95},
            hover={0.15,0.075,0.025,1},selected={0.20,0.092,0.024,1},
            sidebar={0.023,0.018,0.015,0.99},header={0.10,0.046,0.012,0.42},
            surface={0.024,0.020,0.019,0.97},accent={1,0.46,0.075,1}},
        edge=1.5,windowAccent=3,cardAccent=2,headerHeight=28,headerVisible=true},
    tactical={name="Tactical Compact",description="Flat surfaces, fine dividers and reduced background fill.",
        colors={bg={0.012,0.017,0.023,0.90},panel={0.018,0.024,0.031,0.72},
            panelActive={0.040,0.050,0.063,0.90},border={0.18,0.22,0.26,0.62},
            hover={0.062,0.075,0.089,0.94},selected={0.09,0.076,0.052,0.97},
            sidebar={0.012,0.017,0.023,0.92},header={0.02,0.027,0.035,0},
            surface={0.012,0.018,0.026,0.66},accent={0.73,0.41,0.14,0.90}},
        edge=1,windowAccent=1,cardAccent=0,headerHeight=0,headerVisible=false},
    obsidian={name="Obsidian Studio",description="Soft dark cards, quiet borders and strong separation between sections.",
        colors={bg={0.031,0.035,0.043,0.98},panel={0.055,0.063,0.078,0.98},
            panelActive={0.078,0.090,0.110,0.99},border={0.141,0.165,0.200,0.82},
            hover={0.096,0.110,0.137,1},selected={0.160,0.100,0.047,1},
            sidebar={0.031,0.035,0.043,0.99},header={0.122,0.140,0.170,0.35},
            surface={0.051,0.063,0.078,0.97},accent={1.00,0.471,0.094,1}},
        edge=1,windowAccent=2,cardAccent=0,headerHeight=30,headerVisible=true},
}
local bindings=setmetatable({},{__mode="k"})
local surfaces=setmetatable({},{__mode="k"})
local listeners={}
local function Call(control,method,...)
    local fn=control and control[method]
    if type(fn)~="function" then return end
    return pcall(fn,control,...)
end
local function Color(control,color,alpha)
    if type(color)=="string" then color=Theme.colors[color] end
    if type(color)~="table" then return false end
    Call(control,"SetColor",color[1],color[2],color[3],alpha or color[4] or 1)
    return true
end
function Theme.BindColor(control,colorOrRole,alpha)
    if not control or (type(colorOrRole)~="string" and type(colorOrRole)~="table") then return false end
    if type(colorOrRole)=="string" and not Theme.colors[colorOrRole] then return false end
    if alpha~=nil and (type(alpha)~="number" or alpha~=alpha or alpha<0 or alpha>1) then return false end
    bindings[control]={color=colorOrRole,alpha=alpha}
    return Color(control,colorOrRole,alpha)
end
local function Texture(parent,level)
    local manager=WINDOW_MANAGER
    if not manager or type(manager.CreateControl)~="function" or CT_TEXTURE==nil then return nil end
    local ok,texture=pcall(manager.CreateControl,manager,nil,parent,CT_TEXTURE)
    if not ok or not texture then return nil end
    Call(texture,"SetMouseEnabled",false)
    if DL_BACKGROUND~=nil then Call(texture,"SetDrawLayer",DL_BACKGROUND) end
    Call(texture,"SetDrawLevel",level or 1)
    return texture
end
local function Horizontal(control,parent,point,relative,height,y)
    if not control then return end
    Call(control,"ClearAnchors")
    Call(control,"SetAnchor",point,parent,relative,0,y or 0)
    Call(control,"SetAnchor",point==TOPLEFT and TOPRIGHT or BOTTOMRIGHT,parent,
        relative==TOPLEFT and TOPRIGHT or BOTTOMRIGHT,0,y or 0)
    Call(control,"SetHeight",height)
end
local function PaintSurface(parent,surface)
    local preset=presets[Theme.presetId or DEFAULT_PRESET]
    local kind=surface.kind
    local fill=kind=="window" and "bg" or kind=="tile" and "surface" or "panel"
    if surface.background then
        if DL_BACKGROUND~=nil then Call(surface.background,"SetDrawLayer",DL_BACKGROUND) end
        Call(surface.background,"SetDrawLevel",0)
        Theme.BindColor(surface.background,fill)
    end
    local edge=kind=="button" and 1 or preset.edge
    for _,line in ipairs(surface.edges) do Color(line,"border");Call(line,"SetHidden",false) end
    Horizontal(surface.edges[1],parent,TOPLEFT,TOPLEFT,edge)
    Horizontal(surface.edges[2],parent,BOTTOMLEFT,BOTTOMLEFT,edge)
    for index,point in ipairs({TOPLEFT,TOPRIGHT}) do
        local line=surface.edges[index+2]
        if line then
            Call(line,"ClearAnchors");Call(line,"SetAnchor",point,parent,point,0,0)
            Call(line,"SetAnchor",index==1 and BOTTOMLEFT or BOTTOMRIGHT,parent,index==1 and BOTTOMLEFT or BOTTOMRIGHT,0,0)
            Call(line,"SetWidth",edge)
        end
    end
    local accentHeight=kind=="window" and preset.windowAccent or kind=="card" and preset.cardAccent or 0
    Horizontal(surface.accent,parent,TOPLEFT,TOPLEFT,math.max(1,accentHeight))
    Color(surface.accent,"accent");Call(surface.accent,"SetHidden",accentHeight==0)
    local headerVisible=preset.headerVisible and (kind=="window" or kind=="card")
    Horizontal(surface.header,parent,TOPLEFT,TOPLEFT,math.max(1,preset.headerHeight),edge)
    Color(surface.header,"header");Call(surface.header,"SetHidden",not headerVisible)
end
function Theme.RegisterSurface(parent,background,kind)
    if not parent then return false end
    kind=kind or "card"
    if kind~="window" and kind~="card" and kind~="tile" and kind~="button" then return false end
    local surface=surfaces[parent]
    if not surface then
        surface={edges={}}
        for index=1,4 do surface.edges[index]=Texture(parent,3) end
        surfaces[parent]=surface
    end
    if kind=="window" or kind=="card" then
        surface.accent=surface.accent or Texture(parent,4)
        surface.header=surface.header or Texture(parent,1)
    end
    surface.background=background;surface.kind=kind
    PaintSurface(parent,surface)
    return true
end
function Theme.GetPresets()
    local result={}
    for _,id in ipairs(presetOrder) do
        local preset=presets[id]
        result[#result+1]={id=id,name=preset.name,description=preset.description}
    end
    return result
end
function Theme.GetPresetId() return Theme.presetId or DEFAULT_PRESET end
function Theme.OnChanged(callback)
    if type(callback)~="function" then return false end
    listeners[callback]=true
    return function() listeners[callback]=nil end
end
local function ApplyPreset(id,notify)
    local preset=presets[id]
    if not preset then return false end
    local changed=Theme.presetId~=id
    -- Rebinding an unchanged character/account choice must not reset dynamic
    -- hover/selection colors or repaint the entire UI without a change event.
    if not changed then return true end
    Theme.presetId=id
    -- Existing modules capture these array identities during file loading.
    for role,color in pairs(preset.colors) do
        local target=Theme.colors[role] or {};Theme.colors[role]=target
        for channel=1,4 do target[channel]=color[channel] end
    end
    for control,binding in pairs(bindings) do Color(control,binding.color,binding.alpha) end
    for parent,surface in pairs(surfaces) do PaintSurface(parent,surface) end
    if changed and notify then for callback in pairs(listeners) do pcall(callback,id) end end
    return true
end
function Theme.RebindProfile(profile)
    if type(profile)~="table" then return false end
    Theme.sv=profile
    local id=presets[profile.preset] and profile.preset or DEFAULT_PRESET
    profile.preset=id
    return ApplyPreset(id,true)
end
function Theme.Initialize()
    local preferences=AlphaSquadUI.Preferences
    if not Theme.preferenceBound and preferences and type(preferences.Open)=="function" then
        local world=GetWorldName and GetWorldName() or "Default"
        local profile=preferences.Open("Appearance","AlphaSquadUISettingsSavedVariables",tostring(world)..":Appearance",{preset=DEFAULT_PRESET})
        Theme.preferenceBound=true
        return Theme.RebindProfile(profile)
    end
    if not Theme.sv then Theme.sv={preset=DEFAULT_PRESET} end
    return Theme.RebindProfile(Theme.sv)
end
function Theme.SetPreset(id)
    if type(id)~="string" or not presets[id] then return false end
    Theme.Initialize()
    Theme.sv.preset=id
    return ApplyPreset(id,true)
end
ApplyPreset(DEFAULT_PRESET,false)
