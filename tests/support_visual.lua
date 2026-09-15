-- Real Support UI/theme/layout integration; no game client or fake inventory scan.
local total,created,requests,scans=0,0,0,0
local function check(value,message)total=total+1;assert(value,message)end
for i,key in ipairs({'CT_CONTROL','CT_TEXTURE','CT_LABEL','TOPLEFT','TOPRIGHT','BOTTOMLEFT','BOTTOMRIGHT','CENTER',
    'TOP','BOTTOM','LEFT','RIGHT','TEXT_ALIGN_CENTER','TEXT_ALIGN_RIGHT','TEXT_ALIGN_LEFT',
    'TEXT_WRAP_MODE_ELLIPSIS','DT_HIGH','DL_OVERLAY','DL_BACKGROUND','MOUSE_BUTTON_INDEX_LEFT'})do _G[key]=i end
local function Control(name,parent)
    created=created+1
    local c={name=name,parent=parent,children={},handlers={},width=0,height=0,hidden=false,scale=1,x=0,y=0}
    if parent then parent.children[#parent.children+1]=c end
    function c:SetDimensions(w,h)self.width=w;self.height=h end
    function c:GetWidth()return self.width*self:GetScale() end
    function c:GetHeight()return self.height*self:GetScale() end
    function c:SetWidth(w)self.width=w end
    function c:SetHeight(h)self.height=h end
    function c:SetScale(v)self.scale=v end
    function c:GetScale()return self.scale*(self.parent and self.parent:GetScale() or 1) end
    function c:SetAnchor(_,relative,_,x,y)self.x=x or 0;self.y=y or 0;self.relative=relative end
    function c:SetHidden(v)self.hidden=v end
    function c:IsHidden()return self.hidden end
    function c:SetText(v)self.text=v end
    function c:SetTexture(v)self.texture=v end
    function c:SetColor(...)self.color={...}end
    function c:SetFont(v)self.font=v end
    function c:SetHandler(event,fn)self.handlers[event]=fn end
    function c:GetHandler(event)return self.handlers[event]end
    function c:GetParent()return self.parent end
    function c:GetName()return self.name end
    function c:GetLeft()return self.x end
    function c:GetTop()return self.y end
    setmetatable(c,{__index=function(_,key)
        if key:match('^Set') or key:match('^Clear')then return function()end end
    end})
    return c
end
GuiRoot=Control('GuiRoot');GuiRoot:SetDimensions(1920,1080)
WINDOW_MANAGER={CreateControl=function(_,name,parent)return Control(name,parent)end,
    CreateTopLevelWindow=function(_,name)return Control(name)end}
local Settings={RegisterPage=function()end}
function Settings.CreateScrollArea(parent,name)
    local viewport=Control(name,parent);local content=Control(name..'Content',viewport);local slider=Control(name..'Slider',parent)
    viewport.UpdateBounds=function()end;viewport.scrollbar=slider
    return content,viewport,slider
end
local registeredWindows={}
function Settings.RegisterExclusiveWindow(id,control,close,options)
    registeredWindows[id]={control=control,close=close,options=options}
end
local SC={sv={enabled=true,visible=true,locked=true,opacity=94,scale=100,width=410,rowHeight=30,x=20,y=30,problemsOnly=false},
    roster={},coverage={entries={}},EquipmentSlotDetails={}}
function SC.Clamp(value,lo,hi)return math.max(lo,math.min(hi,value))end
function SC:IsGrouped()return true end
function SC:ScanLocalBuild()scans=scans+1 end
function SC:RequestPlayerBuild()requests=requests+1;return true end
function SC.NowMs()return 100000 end
AlphaSquadUI={Modules={SupportCoverage=SC},Settings=Settings}
assert(loadfile('AlphaSquadUI/Core/Theme.lua'))()
assert(loadfile('AlphaSquadUI/Core/Layout.lua'))()
assert(loadfile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageUI.lua'))()
assert(loadfile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageBuildView.lua'))()
assert(loadfile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageInspector.lua'))()
local Theme,Layout=AlphaSquadUI.Theme,AlphaSquadUI.Layout
local function ColorKey(color)return table.concat(color,',')end
local rows={}
for i=1,4 do rows[i]={key='effect'..i,effect={label='Effect '..i},status=i==1 and 'covered' or 'missing'}end
SC.Catalog={GetEffectVisual=function(_,key)return {icon='native-effect:'..key}end}
SC.coverage={entries=rows,requiredCount=4,coveredCount=1,ready=false}
SC:CreateHUD()
check(SC.window.width==410 and SC.window.height==398,'Existing Support width migrates to the shared sizing defaults')
check(Layout.attachments[SC]~=nil,'Support participates in the global placement handles')
SC.sv.hudWidth,SC.sv.hudHeight=630,510
SC:ApplyLayout()
local win=SC.window
check(win.width==630 and win.height==510,'Independent Support width and height are applied without changing font size')
check(win.actions[1].width==301 and win.actions[2].x==317,'Header actions reflow across the resized panel')
check(win.list.rows[1].name.width==432 and win.list.rows[1].name.font=='ZoFontGameSmall','HUD rows use the available width with the original native font')
check(win.list.rows[1].icon.texture=='native-effect:effect1','HUD uses the exact catalog native icon')
SC.coverage.entries={rows[1]};SC:RefreshHUD()
check(win.width==630 and win.height==510 and win.list.rows[2].hidden,'Refreshing fewer issues preserves manual dimensions and hides unused rows')
SC.sv.hudWidth,SC.sv.hudHeight=330,235;SC:ApplyLayout()
check(win.width==330 and win.height==235 and win.actions[2].x+win.actions[2].width<=330,'A narrow panel retains both action buttons inside its bounds')
check(win.list.rows[1].name.width>0,'The minimum panel still reserves readable space for issue names')
check(win.list.rows[1].name.x+win.list.rows[1].name.width<win.list.rows[1].width-118,'Names retain a gap before their right-aligned status')
SC.sv.rowHeight=24;SC:RefreshHUD()
check(win.list.rows[1].icon.height+win.list.rows[1].icon.y<=win.list.rows[1].height,'Migrated compact row heights never clip their native icons')
GuiRoot:SetDimensions(480,320);SC.sv.hudWidth,SC.sv.hudHeight=800,600;SC:ApplyLayout()
check(win.width*win.scale<=460 and win.height*win.scale<=300,'The requested HUD dimensions fit a smaller display')
check(SC.sv.hudWidth==800 and SC.sv.hudHeight==600 and SC.sv.scale==100,'Screen fitting never overwrites saved dimensions or requested scale')
GuiRoot:SetDimensions(1920,1080);SC:ApplyLayout()
check(win.scale==1,'Returning to a large display restores the requested HUD scale')
local pool=created;local before=ColorKey(win.bg.color)
Theme.SetPreset('ember')
check(ColorKey(win.bg.color)~=before and ColorKey(win.status.color)==ColorKey(Theme.colors.gold),'Theme changes repaint the HUD without overwriting its readiness color')
check(created==pool and requests==0 and scans==0,'Changing the HUD theme allocates no controls and performs no scan or build request')

-- Complete player selection remains visible while the shared build stays compact.
ZO_GetClassIcon=function(id)return id==1 and 'native-class-one' or id==2 and 'native-class-two' or nil end
GetUnitSilhouetteTexture=function(unit)return 'native-silhouette:'..unit end
GetItemLinkIcon=function(link)return 'native-item:'..link end
GetAbilityIcon=function(id)return 'native-ability:'..id end
local item={slotKey='HEAD',name='Exact head',link='exact-item-link',icon='native-head',qualityColor={.8,.4,.2,1}}
local details={equipment={complete=true,glyphs={verified=true},items={item},slots={{slotKey='HEAD',known=true,item=item}},setList={}},
    skills={known=true,championKnown=false,primary={{slot=3,abilityId=100,icon='native-morph'}},backup={}},
    food={verified=true,active=true,icon='native-food'},curse={known=true,kind='NONE'}}
for i=1,12 do SC.roster[i]={key='player'..i,displayName='@Player'..i,classId=i%2+1,unitTag='group'..i,food={verified=true,active=true}}end
SC.inspectorPlayerKey='player1'
function SC:GetPlayerBuildDetails()return details end
SC:CreateInspectorWindow();SC.inspectorWindow:SetHidden(false);SC:RefreshInspector()
local inspector=SC.inspectorWindow
local backTarget
Settings.CloseExclusiveWindow=function(id)backTarget=id;return true end
inspector.close.handlers.OnMouseUp(inspector.close,MOUSE_BUTTON_INDEX_LEFT,true)
check(backTarget=='supportBuilds' and inspector.close.label.text=='BACK','Builds exposes an explicit Back action through the shared navigation registry')
check(registeredWindows.supportBuilds.options.fallbackPage=='supportcoverage','Directly opened Builds has a module settings destination')
local requestsBefore=requests
registeredWindows.supportBuilds.options.restore()
check(requests==requestsBefore,'Returning to Builds refreshes its cached view without requesting a new remote build')
check(#inspector.playerList.rows==12 and inspector.playerList.rows[12].y+inspector.playerList.rows[12].height<=inspector.playerList.height,
    'All twelve group members fit in the compact roster without paging or scrolling')
check(inspector.playerList.parent==inspector.playerPanel and inspector.playerBG.parent==inspector.playerPanel,
    'The roster backdrop sits behind its scroll viewport instead of covering its items')
check(inspector.playerList.rows[1].classIcon.texture=='native-class-two' and inspector.playerList.rows[2].classIcon.texture=='native-class-one',
    'Roster class artwork comes from the inspected class through the current native API')
SC.roster[2].classId=0/0;SC:RefreshInspectorRoster()
check(inspector.playerList.rows[2].classIcon.hidden and inspector.playerList.rows[2].classIcon.texture=='','Unknown class data hides prior artwork instead of inventing an icon')
check(inspector.buildSheet.y==92 and inspector.buildSheet.y+inspector.buildSheet.height<=inspector.height-48,'The compact header leaves the complete build above the footer')
local skill=inspector.buildSheet.skills.bars.primary.icons[1]
check(skill.width==44 and skill.height==44 and skill.slotNumber.y==44,'Native skill artwork is square with its slot number below')
check(skill.icon.texture=='native-morph','The larger skill tile preserves its actual morph image')
local head=inspector.buildSheet.equipment.slots.HEAD
local quality=ColorKey(head.frame.color);local gearFill=ColorKey(inspector.buildSheet.equipment.bg.color)
pool=created;Theme.SetPreset('tactical')
check(ColorKey(inspector.buildSheet.equipment.bg.color)~=gearFill and ColorKey(head.frame.color)==quality,
    'Build panels change theme while equipment quality remains semantic')
check(skill.icon.texture=='native-morph' and head.icon.texture=='native-head','Changing theme never substitutes item or skill artwork')
check(ColorKey(inspector.playerList.rows[1].bg.color)==ColorKey(Theme.colors.selected),'The selected group member keeps its themed selection after repaint')
check(created==pool and requests==0 and scans==0,'Theme refresh reuses the build and roster pools without collecting or transmitting data')
inspector:SetHidden(true);Theme.SetPreset('obsidian');inspector:SetHidden(false);SC:RefreshInspector()
check(ColorKey(inspector.playerList.rows[1].bg.color)==ColorKey(Theme.colors.selected),'Opening a previously hidden build restores selection in the current theme')
check(requests==0 and scans==0,'Reopening presentation through refresh uses the cached snapshot only')
-- Repeated refreshes at non-unit native scale never feed rendered child height back into layout.
local setList={}
for i=1,14 do setList[i]={name='Fragmented set '..i,mainCount=1,backCount=1}end
details.equipment.setList=setList;details.curse={known=true,kind='WEREWOLF'}
details.skills.werewolfKnown=true;details.skills.werewolf={{slot=3,abilityId=999}}
for _,size in ipairs({{1280,720},{800,600},{480,320},{2560,1080},{3840,2160}})do
    GuiRoot:SetDimensions(size[1],size[2]);SC:RefreshInspector()
    local expectedHeight=inspector.height
    for i=1,3 do
        SC:RefreshInspector()
        check(inspector.height==expectedHeight,'Repeated scaled sheet fitting preserves logical dimensions')
        check(inspector.buildSheet.y+inspector.buildSheet.height<=inspector.height-48,'All build panels stay above the footer on every refresh')
        check(inspector:GetWidth()<=size[1]-24+.01 and inspector:GetHeight()<=size[2]-24+.01,'Native rendered dimensions fit the display in every window mode')
    end
end
-- Placement samples stay outside the live coverage/roster and preserve real visibility choices.
inspector:SetHidden(true);GuiRoot:SetDimensions(1920,1080)
local liveCoverage,liveRoster=SC.coverage,SC.roster
local mode='mixed'
AlphaSquadUI.Preview={GetMode=function()return mode end}
local actualMoving=Layout.IsMoving;Layout.IsMoving=function(module)return module==SC end
SC.Catalog.effects={}
local demoKeys={}
for i=1,12 do local key='demo'..i;demoKeys[i]=key;SC.Catalog.effects[key]={label='Native effect '..i}end
SC.Catalog.GetAllEffectKeys=function()return demoKeys end
SC.sv.problemsOnly=true
SC:RefreshHUD()
check(#SC.window.list.rows>=12 and not SC.window.list.rows[12].hidden,'Placement fills the support preview even with issues-only enabled')
check(SC.window.list.rows[1].value.text=='COVERED' and SC.window.list.rows[2].value.text=='MISSING' and SC.window.list.rows[3].value.text=='UNKNOWN','Preview includes distinct known ready, missing and unknown states')
check(SC.window.list.rows[4].value.text=='DUPLICATE 3' and SC.window.list.rows[5].value.text=='TRACKING OFF','Preview shows duplicate and optional tracking states')
check(SC.window.summary.text:find('12 players',1,true) and SC.window.note.text:find('Preview only',1,true),'Sample population is clearly identified')
SC.sv.problemsOnly=false
for _,nextMode in ipairs({'ready','missing','overload','live'})do mode=nextMode;SC:SetLayoutPreview(mode)end
check(SC.coverage==liveCoverage and SC.roster==liveRoster and #SC.roster==12,'Cycling previews never replaces live snapshots or membership')
check(SC.window.list.rows[1].data==liveCoverage.entries[1],'Live preview shows the original coverage row')
mode='mixed';Layout.IsMoving=function()return false end;SC:RefreshHUD()
check(SC.window.list.rows[1].data==liveCoverage.entries[1],'Leaving placement restores real data without fake rows escaping')
Layout.IsMoving=actualMoving
check(requests==0 and scans==0,'All layout, screen and preview changes use presentation data without scans or requests')
local nativeVisual=SC.Catalog.GetEffectVisual
SC.Catalog.GetEffectTooltip=function()return 'Effect description' end
SC.Catalog.GetEffectVisual=function()return {icon='native-category',isFallback=true,iconKind='category'}end
check(SC.UI.EffectTooltip('demo1'):find('category symbol',1,true),'Fallback artwork is explicitly distinguished from an exact effect icon')
SC.Catalog.GetEffectVisual=function()return {icon='native-provider',isFallback=false,iconKind='source',sourceName='Exact provider'}end
check(SC.UI.EffectTooltip('demo1'):find('Exact provider',1,true),'A source ability icon is named as a provider, not mislabeled as the effect image')
SC.Catalog.GetEffectVisual=nativeVisual
print(string.format('Support visual integration: %d assertions passed',total))
