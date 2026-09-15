-- The theme picker must not repaint ESO's shared menu or leak transparency.
local assertions=0
local function check(value,message) assertions=assertions+1;assert(value,message) end
local created={}
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
function WINDOW_MANAGER:CreateControlFromVirtual(_,parent,template)
    local control=Control(parent);control.object={control=control};control.template=template
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
print(string.format("Native dropdown ownership: %d assertions passed",assertions))
