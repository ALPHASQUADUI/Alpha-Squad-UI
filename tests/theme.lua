-- Branding preserves native UTF-8 glyphs without depending on pattern semantics.
local total=0
local function check(value,message) total=total+1;assert(value,message) end
AlphaSquadUI={}
local original=string.gmatch
string.gmatch=function() error("Branding must not depend on byte-range pattern matching in the ESO client") end
assert(loadfile("AlphaSquadUI/Core/Theme.lua"))()
string.gmatch=original
local theme=AlphaSquadUI.Theme
local function Plain(value) return value:gsub("|c%x%x%x%x%x%x",""):gsub("|r","") end
check(Plain(theme.brandText)=="Ąlpha Şquad UI","Extended Latin brand initials survive exact UTF-8 color markup")
check(theme.brandText:find("|cFF6F0CĄ|r",1,true)==1,"The first gradient color encloses the complete initial glyph")
check(theme.brandText:find("|cFFFFFFUI|r",1,true)~=nil,"UI retains explicit white markup")
check(Plain(theme.Gradient("Aé雪😀",{0,0,0},{255,255,255}))=="Aé雪😀","One through four byte glyphs remain unchanged")
check(Plain(theme.authorText)=="@SeRuM1" and theme.PlayerName("@SeRuM1")==theme.authorText,"Author styling retains only the public account name")
check(theme.PlayerName("|cFFFFFF@Player|r |Hbad")=="@Player ||Hbad","Other player text cannot inject color or hyperlink markup")
check(Plain(theme.Brand("Builds"))=="Ąlpha Şquad UI  •  Builds","Window titles retain both branded initials and their section")

local kinds={"TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT","CT_TEXTURE","DL_BACKGROUND"}
for index,name in ipairs(kinds) do _G[name]=index end
local created,repaints=0,0
local function Control()
    local control={children={},anchors={},alpha=1}
    function control:SetColor(r,g,b,a) self.color={r,g,b,a};repaints=repaints+1 end
    function control:SetAlpha(alpha) self.alpha=alpha end
    function control:SetMouseEnabled(enabled) self.mouse=enabled end
    function control:SetDrawLayer(value) self.layer=value end
    function control:SetDrawLevel(value) self.level=value end
    function control:ClearAnchors() self.anchors={} end
    function control:SetAnchor(...) self.anchors[#self.anchors+1]={...} end
    function control:SetHeight(height) self.height=height end
    function control:SetWidth(width) self.width=width end
    function control:SetHidden(hidden) self.hidden=hidden end
    return control
end
WINDOW_MANAGER={CreateControl=function(_,_,parent)
    created=created+1;local control=Control();parent.children[#parent.children+1]=control;return control
end}
theme.Initialize()
check(theme.GetPresetId()=="obsidian","New appearance profiles default to Obsidian Studio")
local presets=theme.GetPresets()
check(#presets==3 and presets[1].id=="ember" and presets[2].id=="tactical" and presets[3].id=="obsidian",
    "Theme picker has exactly the three named design presets in stable order")
presets[3].name="Changed"
check(theme.GetPresets()[3].name=="Obsidian Studio","Picker metadata cannot mutate the engine's preset definitions")
local panel,hover,green=theme.colors.panel,theme.colors.hover,theme.colors.green
local greenBefore=table.concat(green,",")
local label,hoverFill=Control(),Control()
check(theme.BindColor(label,panel) and theme.BindColor(hoverFill,"hover",0.4),"Controls can bind either captured palette arrays or role names")
local card,background=Control(),Control();background:SetAlpha(0.37)
check(theme.RegisterSurface(card,background,"card"),"Card surfaces register using native texture controls")
check(created==6 and card.children[6].height==30 and not card.children[6].hidden,
    "Obsidian uses a separated card header and a reusable static edge set")
check(background.layer==DL_BACKGROUND and background.level==0
    and card.children[6].layer==DL_BACKGROUND and card.children[6].level>background.level,
    "Opaque native background is explicitly below its themed header and edges")
for _,texture in ipairs(card.children) do check(texture.mouse==false,"Decorative theme textures never intercept mouse input") end
local obsidianFill=table.concat(background.color,",")
local changes=0
local function Changed() changes=changes+1 end
local unsubscribe=theme.OnChanged(Changed)
theme.OnChanged(Changed)
theme.OnChanged(function() error("An optional consumer failure must not break the rest of the theme") end)
check(theme.SetPreset("tactical"),"Tactical theme applies without invoking event or animation APIs")
check(theme.colors.panel==panel and theme.colors.hover==hover,"Captured palette arrays keep their identity after a theme switch")
check(label.color[1]==panel[1] and hoverFill.color[1]==hover[1] and hoverFill.color[4]==0.4,
    "Bound controls repaint from changed tokens and retain explicit alpha")
check(card.children[6].hidden and card.children[5].hidden and background.color[4]<0.8,
    "Tactical removes header and card accents and uses lower background fill")
check(theme.SetPreset("ember") and card.children[1].height==1.5 and card.children[5].height==2
    and not card.children[5].hidden,"Ember has thicker warm framing and a visible orange card accent")
check(table.concat(background.color,",")~=obsidianFill,"Distinct surface colors complement the different preset geometry")
check(background.alpha==0.37,"Theme changes preserve the user's independent native background opacity")
check(changes==2,"The same repaint listener registers once and other listener failures stay isolated")
check(theme.colors.green==green and table.concat(green,",")==greenBefore
    and Plain(theme.brandText)=="Ąlpha Şquad UI" and Plain(theme.authorText)=="@SeRuM1",
    "Theme presets preserve semantic status colors and all branding")
theme.RegisterSurface(card,background,"card")
check(created==6,"Rebinding an existing surface reuses its textures rather than creating controls")
local tile=Control();theme.RegisterSurface(tile,Control(),"tile")
check(created==10,"Small tiles allocate only their four static edges")
theme.RegisterSurface(tile,Control(),"card")
check(created==12,"Promoting a tile to a card lazily creates only the missing header and accent")
local previous=theme.GetPresetId()
check(not theme.SetPreset("unrecognized") and theme.GetPresetId()==previous,"Invalid preset choices leave the live theme unchanged")
check(not theme.BindColor(label,"unknown") and not theme.BindColor(label,"panel",0/0),"Unknown roles and invalid opacity are rejected")
local broken={preset={}}
theme.RebindProfile(broken)
check(broken.preset=="obsidian" and theme.GetPresetId()=="obsidian","Malformed saved preset values normalize to the default")
unsubscribe();local before=changes;theme.SetPreset("ember")
check(changes==before,"Consumers can retire a theme-change callback")
local painted=repaints
theme.Initialize();theme.SetPreset("ember")
check(repaints==painted,"Repeated initialization or choosing the current preset causes no redundant repaint")
label:SetColor(0.1,0.8,0.2,1)
theme.RebindProfile({preset="ember"})
check(label.color[1]==0.1 and label.color[2]==0.8,"Unchanged profile switches preserve current hover and semantic presentation")
print(string.format("PASS: %d assertions; Lua %s. No ESO-runtime certification.",total,_VERSION))
