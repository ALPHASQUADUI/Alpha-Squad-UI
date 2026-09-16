-- Dashboard pickers must coexist without native XML name collisions or shared styling.
local assertions=0
local function check(value,message) assertions=assertions+1;assert(value,message) end
local created={}
local namedControls={}
GuiRoot={GetScale=function()return 1.25 end}
CT_TEXTURE,DL_BACKGROUND=1,2
local function Control(parent)
    local control={parent=parent}
    function control:SetAnchorFill(target)self.target=target end
    function control:SetMouseEnabled(enabled)self.mouse=enabled end
    function control:SetDrawLayer(layer)self.layer=layer end
    function control:SetDrawLevel(level)self.level=level end
    function control:SetColor(r,g,b,a)self.color={r,g,b,a}end
    function control:SetScale(value)self.scale=value end
    return control
end
WINDOW_MANAGER={}
function WINDOW_MANAGER:CreateControlFromVirtual(name,parent,template)
    local control=Control(parent);control.object={control=control};control.template=template
    control.name=name
    -- ESO expands $(parent) in the template's BG and Scroll child names.
    -- An anonymous template root therefore reserves the global names BG/Scroll.
    local function Register(controlName,value)
        assert(not namedControls[controlName],"Unable to create control ["..controlName.."]. This control already exists.")
        namedControls[controlName]=value
    end
    if name then Register(name,control) end
    for _,suffix in ipairs({"BG","Scroll"}) do
        local child=Control(control)
        Register((name or "")..suffix,child)
        control[suffix]=child
    end
    function control.object:Show(owner,items,minWidth,maxHeight,spacing)
        self.lastShow={owner=owner,items=items,width=minWidth,height=maxHeight,spacing=spacing}
        return "native show"
    end
    created[#created+1]=control;return control
end
function WINDOW_MANAGER:CreateControl(_,parent)
    local control=Control(parent);parent.fill=control;return control
end
AlphaSquadUI={}
assert(loadfile("AlphaSquadUI/Core/Theme.lua"))()
local theme=AlphaSquadUI.Theme
local shared={marker="native singleton"}
local combo={dropdown=shared}
function combo:SetDropdownObject(object)self.dropdown=object end
local ownerScale,renderedWidth=0.75,390
function combo:GetContainer()
    return {GetScale=function()return ownerScale end,GetWidth=function()return renderedWidth end}
end
local dropdown=theme.ConfigureDropdown(combo)
check(dropdown and combo.dropdown==dropdown.object,"The picker owns its native dropdown")
check(dropdown.template=="ZO_ComboBoxDropdown_Keyboard_Template","Native menu behavior and entries are retained")
check(shared.marker=="native singleton" and shared.control==nil,"The shared native singleton is untouched")
check(dropdown.fill.target==dropdown and dropdown.fill.mouse==false,"The fill covers the dropdown without capturing clicks")
check(dropdown.fill.color[4]==1,"The popup fully obscures text behind its choices")
theme.SetPreset("tactical")
check(dropdown.fill.color[4]==1,"Tactical transparency does not make an open menu unreadable")
check(theme.ConfigureDropdown(combo)==dropdown and #created==1,"Refreshing the picker reuses its dropdown")
check(theme.ConfigureDropdown({})==nil and #created==1,"Unavailable native dropdown support leaves the original picker usable")
local choices={"one","two","three"}
check(dropdown.object:Show(combo,choices,135,250,0)=="native show","The private instance retains native Show behavior")
check(dropdown.scale==0.6 and dropdown.object.lastShow.width==520,"Dropdown scale and width match the rendered owner without double scaling")
ownerScale,renderedWidth=1.25,650
dropdown.object:Show(combo,choices,135,250,0)
check(dropdown.scale==1 and dropdown.object.lastShow.width==520,"Reopening after a viewport change preserves logical menu width")
check(dropdown.object.lastShow.items==choices and dropdown.object.lastShow.height==250,"Native entries and height limits pass through unchanged")

local languageCombo={dropdown=shared,SetDropdownObject=combo.SetDropdownObject,GetContainer=combo.GetContainer}
local languageDropdown=theme.ConfigureDropdown(languageCombo)
check(languageDropdown and languageCombo.dropdown==languageDropdown.object,"The language picker can be created beside the theme picker")
check(languageDropdown~=dropdown and languageDropdown.object~=dropdown.object,"Each picker owns an independent native menu")
check(languageDropdown.BG~=dropdown.BG and languageDropdown.Scroll~=dropdown.Scroll,"Native template children belong to their own picker")
check(namedControls.BG==nil and namedControls.Scroll==nil,"Addon pickers do not reserve unprefixed global child names")
check(languageDropdown.fill~=dropdown.fill and languageDropdown.fill.target==languageDropdown,"Each menu has its own opaque fill")
local languages={"English","Français"}
languageDropdown.object:Show(languageCombo,languages,135,250,0)
check(languageDropdown.object.lastShow.items==languages and dropdown.object.lastShow.items==choices,"Opening one picker preserves the other picker's entries")
for _,preset in ipairs({"ember","obsidian","tactical"}) do
    theme.SetPreset(preset)
    check(theme.ConfigureDropdown(combo)==dropdown and theme.ConfigureDropdown(languageCombo)==languageDropdown and #created==2,
        "Refreshing both pickers reuses their existing native controls")
    check(dropdown.fill.color[4]==1 and languageDropdown.fill.color[4]==1,"Both menus remain opaque after a theme change")
end
check(theme.ConfigureDropdown(nil)==nil and #created==2,"An absent picker creates no native controls")
local unrelatedBG,unrelatedScroll={},{}
namedControls.BG,namedControls.Scroll=unrelatedBG,unrelatedScroll
local anotherCombo={SetDropdownObject=combo.SetDropdownObject}
local anotherDropdown=theme.ConfigureDropdown(anotherCombo)
check(anotherDropdown and anotherDropdown~=dropdown and anotherDropdown~=languageDropdown and #created==3,
    "An additional unnamed owner also receives independent native controls")
check(namedControls.BG==unrelatedBG and namedControls.Scroll==unrelatedScroll,"Unrelated global BG and Scroll controls remain untouched")
print(string.format("Native dropdown ownership: %d assertions passed",assertions))
