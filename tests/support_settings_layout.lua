-- The integrated Support page reflows without shrinking its native text.
local assertions,controls=0,{}
local function check(value,message) assertions=assertions+1;assert(value,message) end
TOPLEFT=1
local function Control(name)
    local control={name=name,children={}}
    controls[name]=control
    function control:SetAnchor(_,parent,_,x,y) self.parent=parent;self.x=x;self.y=y end
    function control:ClearAnchors() end
    function control:SetDimensions(w,h) self.width=w;self.height=h end
    function control:SetWidth(w) self.width=w end
    function control:SetText(text) self.text=text end
    return control
end
local C={orange={},muted={},white={},gold={},green={}}
local SC={sv={},UI={colors=C},Catalog={}}
AlphaSquadUI={Modules={SupportCoverage=SC}}
assert(loadfile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageSettings.lua'))()
local ui={}
function ui.CreateLabel(parent,name,font,text)
    local control=Control(name);control.parent=parent;control.font=font;control.text=text;return control
end
function ui.CreateCard(parent,name,x,y,w,h)
    local control=Control(name);control:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);control:SetDimensions(w,h);return control
end
function ui.CreateButton(parent,name,text,x,y,w,h)
    local control=ui.CreateCard(parent,name,x,y,w,h);control.text=text;return control
end
function ui.AddToggleRow() end
function ui.RegisterRefresher() end
function ui.RegisterLayout(page,callback)page.layout=callback end
local page=Control('page')
SC:BuildIntegratedSettingsPage(page,ui)
local overview=controls.AlphaSquadSupportOverview
local preparation=controls.AlphaSquadSupportModule
local appearance=controls.AlphaSquadSupportAppearance
for _,width in ipairs({460,660,859,860,1100}) do
    page.layout(width)
    for _,card in ipairs({overview,preparation,appearance}) do
        check(card.x>=0 and card.x+card.width<=width,'Every card stays within the available settings viewport')
        check(card.y+card.height<=page.contentHeight,'Content height covers all cards without clipped controls')
    end
    local coverage=controls.AlphaSquadSupportSettingsCoverage
    local builds=controls.AlphaSquadSupportSettingsBuilds
    check(coverage.x+coverage.width<builds.x and builds.x+builds.width<=overview.width-14,
        'Coverage and Builds retain distinct complete hit areas at every width')
    check((width<860 and appearance.y>preparation.y+preparation.height) or
        (width>=860 and appearance.y==preparation.y and appearance.x>preparation.x+preparation.width),
        'Cards stack on smaller screens and return to two columns with space')
    check(controls.AlphaSquadSupportLayoutHelp.width==appearance.width-28 and controls.AlphaSquadSupportLayoutHelp.font=='ZoFontGameSmall',
        'Explanations reflow at the native font size instead of global scaling')
end
print(string.format('Support settings layout: %d assertions passed',assertions))
