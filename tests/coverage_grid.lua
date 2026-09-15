-- Complete real catalog on one page, including all duplicate contributor names.
local total,created=0,0
local unpack=unpack or table.unpack
local function check(value,message)total=total+1;assert(value,message)end
for i,key in ipairs({'CT_CONTROL','CT_TEXTURE','CT_LABEL','TOPLEFT','TOPRIGHT','BOTTOMLEFT','BOTTOMRIGHT','TEXT_WRAP_MODE_ELLIPSIS'})do _G[key]=i end
local function Control(name,parent)
    created=created+1
    local c={name=name,parent=parent,handlers={},width=0,height=0,hidden=false,scale=1}
    function c:SetDimensions(w,h)self.width=w;self.height=h end
    function c:GetWidth()return self.width end
    function c:GetHeight()return self.height end
    function c:SetHeight(h)self.height=h end
    function c:SetAnchor(point,relative,relativePoint,x,y)self.x=x or 0;self.y=y or 0 end
    function c:SetHidden(v)self.hidden=v end
    function c:IsHidden()return self.hidden end
    function c:SetText(v)self.text=v end
    function c:SetTexture(v)self.texture=v end
    function c:SetColor(...)self.color={...}end
    function c:SetHandler(event,fn)self.handlers[event]=fn end
    function c:SetScale(v)self.scale=v end
    setmetatable(c,{__index=function(_,key)if key:match('^Set') or key:match('^Clear')then return function()end end end})
    return c
end
WINDOW_MANAGER={CreateControl=function(_,name,parent)return Control(name,parent)end}
GuiRoot=Control('GuiRoot');GuiRoot:SetDimensions(1920,1080)
local C={white={1,1,1,1},muted={.5,.5,.5,1},orange={1,.5,.1,1},gold={1,.8,.3,1},panel={.1,.1,.1,1},green={.3,1,.4,1},red={1,.2,.2,1}}
local UI={colors=C,Text=function(text)return tostring(text or '')end,Color=function(c,color)c:SetColor(unpack(color))end}
function UI.Label(parent,name,text)local c=Control(name,parent);c.text=text;return c end
function UI.Solid(parent,name)local c=Control(name,parent);return c end
function UI.Button(parent,name,text,w,h,fn)local c=Control(name,parent);c:SetDimensions(w,h);c.label=UI.Label(c,name..'Label',text);c.click=fn;return c end
function UI.Window(name)local c=Control(name);c.title=UI.Label(c,name..'Title','');c.subtitle=UI.Label(c,name..'Sub','');c.footer=UI.Label(c,name..'Footer','');return c end
function UI.RegisterWindow()end
function UI.ClearTooltip()end
function UI.ShowWindow(id,win) win:SetHidden(false);UI.shown=id end
function UI.Hover(c,fn)c.hover=fn end
function UI.Status(row)if row.status=='covered'then return 'COVERED',C.green elseif row.unverified then return 'UNKNOWN',C.gold end return 'MISSING',C.red end
local SC={UI=UI,sv={activeProfile='trial',profileOverrides={trial={}}}}
AlphaSquadUI={Modules={SupportCoverage=SC},Theme={}}
assert(loadfile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageCatalog.lua'))()
assert(loadfile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageSettings.lua'))()
function SC:GetCapabilityOwners()return {}end
function SC:IsEffectTracked(key)for _,entry in ipairs(self.Catalog:GetRequirements(self.sv.activeProfile,self.sv))do if entry==key then return true end end return false end
function SC:SetEffectTracking(key,value)self.lastTracking={key=key,value=value}end
function SC:OpenInspector()self.openedInspector=self.inspectorPlayerKey end
SC:CreateMatrixWindow()
local win=SC.matrixWindow
local totalKeys=#SC.Catalog:GetAllEffectKeys()
local pool
for _,size in ipairs({{1920,1080},{1366,768},{1280,720},{800,600}})do
    GuiRoot:SetDimensions(size[1],size[2]);SC:RefreshMatrix()
    local layout=win.gridLayout;local shown,inside,iconsInside,iconsVisible,unique,distinct=0,true,true,true,true,{}
    for _,row in ipairs(win.list.rows)do
        if not row.hidden then
            shown=shown+1
            iconsInside=iconsInside and row.icon.y>=0 and row.icon.y+row.icon.height<=row.height
            iconsVisible=iconsVisible and not row.icon.hidden and type(row.icon.texture)=='string' and row.icon.texture~=''
            inside=inside and row.x>=0 and row.x+row.width<=win.list.width+.01 and row.y>=0 and row.y+row.height<=win.list.height+.01
            local position=tostring(row.x)..':'..tostring(row.y)
            unique=unique and not distinct[position];distinct[position]=true
        end
    end
    check(shown==totalKeys,'Every catalog effect is visible without scrolling or pagination')
    check(unique,'Catalog entries never share a grid cell')
    check(inside,'Every compact tile fits inside its grid at the current viewport')
    check(iconsInside,'Every native icon stays inside its own dense grid row')
    check(iconsVisible,'Every catalog row has a native icon or explicit category glyph even without optional libraries')
    check(win.list.y+win.list.height<=win.height-48,'Coverage grid never overlaps its footer')
    check(win.width*win.scale<=size[1]-24+.01 and win.height*win.scale<=size[2]-24+.01,'Full page fits within the current display')
    local panelsFit=true
    for index,panel in ipairs(win.categoryPanels)do
        panelsFit=panelsFit and panel.x>=0 and panel.x+panel.width<=win.width and panel.y+panel.height<=win.height-48
        if index>1 then local previous=win.categoryPanels[index-1];panelsFit=panelsFit and previous.x+previous.width<panel.x end
    end
    check(panelsFit,'Each category keeps a separate panel inside the page without footer overlap')
    check(win.legend.hidden or win.legend.y>=win.list.y+layout.rows[4]*layout.pitch and win.legend.y+win.legend.height<=win.height-48,
        'The status legend uses free mythic space without hiding entries or footer text')
    if pool then check(created==pool,'Viewport changes reanchor pooled controls without new allocation')end
    pool=created
end
check(win.list.content==nil and not win.list.handlers.OnMouseWheel,'Coverage contains no scroll container or wheel handlers')
local owners={}
for i=1,12 do owners[i]={key='player'..i,displayName='@Player'..i,capabilities={major_courage={sources={['Exact source '..i]=true},mainBar=true}}}end
local entry={key='major_courage',effect=SC.Catalog.effects.major_courage,owners=owners,duplicatePlayers=owners,status='covered'}
SC.coverage={entries={entry}}
SC:RefreshMatrix()
local target
for _,row in ipairs(win.list.rows)do if row.data and row.data.key=='major_courage'then target=row end end
check(target and target.status=='DUPLICATE' and target.contributors.label.text=='×12','Duplicate count is clearly visible in the compact tile')
local tooltip=target.contributors.hover()
for i=1,12 do check(tooltip:find('@Player'..i,1,true) and tooltip:find('Exact source '..i,1,true),'Hover preserves each duplicate contributor and their real source')end
check(tooltip:find('front bar',1,true),'Contributor hover preserves known bar availability')
target.contributors.click()
check(not SC.openedInspector and UI.shown=='supportContributors','Duplicate click offers a compact choice instead of opening the first player')
SC.roster=owners
function SC:GetCapabilityOwners(key)return key=='major_courage' and owners or {}end
SC:RefreshContributorPicker()
check(#SC.contributorWindow.rows==12,'The compact chooser includes all twelve contributors')
SC.contributorWindow.rows[7].click(SC.contributorWindow.rows[7])
check(SC.openedInspector=='player7','Choosing a contributor opens exactly that player build')
SC.openedInspector=nil;SC.roster={owners[1]}
SC.contributorWindow.rows[7].click(SC.contributorWindow.rows[7])
check(not SC.openedInspector,'A departed player cannot silently open the default or another player build')
SC:OpenContributorPicker({key='major_courage',owners={owners[1]}})
check(SC.openedInspector=='player1','A single contributor opens directly without an unnecessary chooser')
SC.openedInspector=nil
SC:OpenContributorPicker({key='major_courage',owners={owners[2]}})
check(not SC.openedInspector,'A stale single contributor cannot open another player as a fallback')
local wasTracked=SC:IsEffectTracked('major_courage')
target.toggle.click()
check(SC.lastTracking.key=='major_courage' and SC.lastTracking.value==not wasTracked,'Compact ON/OFF only changes its own effect')
SC.matrixFilter='DUPLICATES';SC:RefreshMatrix()
local shown=0
for _,row in ipairs(win.list.rows)do if not row.hidden then shown=shown+1;check(row.data.key=='major_courage','Filtering hides unrelated pooled rows')end end
check(shown==1,'Duplicate filter retains its matching effect without another page')
print(string.format('Coverage grid: %d assertions passed',total))
