-- Character-sheet binding and layout regressions, without a rendering/game client.
local checks,created=0,0
local unpack=unpack or table.unpack
local function check(value,message) checks=checks+1;assert(value,message) end
for i,key in ipairs({'CT_CONTROL','CT_TEXTURE','CT_LABEL','TOPLEFT','TEXT_ALIGN_CENTER','TEXT_ALIGN_RIGHT','TEXT_WRAP_MODE_ELLIPSIS'}) do _G[key]=i end
local function Control(name,parent)
    created=created+1
    local c={name=name,parent=parent,children={},handlers={},hidden=false,width=0,height=0}
    if parent then parent.children[#parent.children+1]=c end
    function c:SetDimensions(w,h)self.width=w;self.height=h end
    function c:SetAnchor(_,_,_,x,y)self.x=x;self.y=y end
    function c:SetHidden(value)self.hidden=value end
    function c:SetTexture(value)self.texture=value end
    function c:SetText(value)self.text=value end
    function c:SetColor(...)self.color={...}end
    function c:SetHandler(event,fn)self.handlers[event]=fn end
    function c:GetParent()return self.parent end
    function c:GetName()return self.name end
    function c:SetHeight(value)self.height=value end
    setmetatable(c,{__index=function(_,key)if key:match('^Set') or key:match('^Clear')then return function()end end end})
    return c
end
WINDOW_MANAGER={CreateControl=function(_,name,parent)return Control(name,parent)end}
local C={white={1,1,1,1},muted={.5,.5,.5,1},orange={1,.5,.1,1},gold={1,.8,.3,1},panel={.1,.1,.1,1},green={.3,1,.4,1},red={1,.2,.2,1}}
local hovered
local UI={colors=C,Text=function(t)return tostring(t or '')end,Color=function(c,color)c:SetColor(unpack(color))end}
function UI.Label(parent,name,text)local c=Control(name,parent);c.text=text;return c end
function UI.Solid(parent,name,color)local c=Control(name,parent);c:SetColor(unpack(color));return c end
function UI.Hover(c,fn)c:SetHandler('OnMouseEnter',function()hovered=type(fn)=='function' and fn()or fn end)end
function UI.Tooltip(_,text)hovered=text end
function UI.ItemTooltip(_,item)hovered=item end
function UI.SkillTooltip(_,skill)hovered=skill end
function UI.ChampionTooltip(_,star)hovered=star end
function UI.ClearTooltip()hovered=nil end
AlphaSquadUI={Modules={SupportCoverage={UI=UI,EquipmentSlotDetails={},NowMs=function()return 100000 end}}}
local SC=AlphaSquadUI.Modules.SupportCoverage
function SC:GetChampionSlotLayout()
 local map={}
 for slot=1,12 do map[slot]={discipline=slot<=4 and "WORLD" or slot<=8 and "COMBAT" or "CONDITIONING",index=(slot-1)%4+1}end
 return map
end
GetUnitSilhouetteTexture=function(tag)return 'silhouette:'..tag end
GetAbilityIcon=function(id)return 'ability:'..id end
GetChampionAbilityId=function(id)return id+1000 end
GetItemLinkIcon=function(link)return 'item:'..link end
assert(loadfile('AlphaSquadUI/Modules/SupportCoverage/SupportCoverageBuildView.lua'))()
local V=SC.BuildView
local canvas=V.Create(Control('Parent'))
check(canvas.width==830 and canvas.height==502,'Compact body fits830x502 logical viewport')
check(#V.EquipmentPositions==14,'All fourteen equipment slots are present')
local unique={}
for _,slot in ipairs(V.EquipmentPositions)do
    check(not unique[slot[1]],'Every physical equipment location appears once');unique[slot[1]]=true
    check(slot[3]>=0 and slot[3]+44<=266 and slot[4]>=0 and slot[4]+64<=502,'Each equipment tile and caption stays inside its panel')
end
local head={slotKey='HEAD',name='Head of Lucent Echoes',link='head-exact-trait',icon='head-icon',traitName='Divines',enchantName='Magicka',hasEnchant=true}
local boots={slotKey='FEET',name='Crimson Sabatons',link='boots-exact-trait',icon='boots-icon',traitName='Sturdy',enchantName='Prismatic',hasEnchant=true}
local staff={twoHanded=true,slotKey='BACKUP_MAIN',name='Maelstrom Inferno Staff',link='staff-infused-flame',icon='staff-icon',hasEnchant=true}
local details={equipment={complete=true,glyphs={verified=true},items={head,boots,staff},slots={{slotKey='HEAD',known=true,item=head},{slotKey='FEET',known=true,item=boots},{slotKey='BACKUP_MAIN',known=true,item=staff},{slotKey='RING1',known=true,empty=true},{slotKey='BACKUP_OFF',known=true,empty=true}},setList={
    {name='Lucent Echoes',physicalCount=5,physicalCountKnown=true,mainCount=5,backCount=5},
    {name='Crimson Oath',physicalCount=5,physicalCountKnown=true,mainCount=5,backCount=3},
    {name='Crushing Wall',physicalCount=1,physicalCountKnown=true,mainCount=0,backCount=2}}},
    skills={known=true,championKnown=true,primary={{slot=3,abilityId=100,icon='correct-morph'},{slot=8,ultimate=true,abilityId=200,icon='front-ultimate'}},backup={{slot=4,abilityId=300,icon='back-morph'},{slot=8,ultimate=true,abilityId=400,icon='back-ultimate'}},
        champion={{id=1,slot=5,discipline='COMBAT',points=50,pointsKnown=true,icon='combat-star'},{id=2,slot=9,discipline='CONDITIONING',points=10,pointsKnown=false}}},
    masteries={known=true,eligible=true,selected={{id=900,name='Mastery',icon='mastery-icon'}},passives={},skillLines={}},
    food={verified=true,active=true,name='Food',abilityId=800,icon='food-icon'},potion={known=true,name='Potion',link='potion-link',count=100},mundus={known=true,ids={950},names={'The Thief'}},curse={known=true,kind='NONE'}}
local player={unitTag='group1',displayName='@Player',connected=true}
V.Bind(canvas,player,details)
check(canvas.equipment.slots.HEAD.icon.texture=='head-icon','Head icon matches exact equipped head item')
canvas.equipment.slots.HEAD.handlers.OnMouseEnter()
check(hovered==head and hovered.traitName=='Divines' and hovered.enchantName=='Magicka','Native item hover receives exact head trait and enchant link')
canvas.equipment.slots.FEET.handlers.OnMouseEnter()
check(hovered==boots and hovered.traitName=='Sturdy','Foot hover never reuses prior head tooltip data')
check(canvas.equipment.slots.RING1.empty.text=='—','Verified empty equipment slot differs from unknown')
check(canvas.equipment.slots.BACKUP_OFF.empty.text=='2H','Two-handed staff marks paired off hand occupied without inventing a second item')
check(canvas.equipment.slots.RING2.empty.text=='?','Unshared equipment slot remains unknown')
check(canvas.equipment.silhouette.texture=='silhouette:group1','Native silhouette belongs to inspected unit')
check(canvas.skills.bars.primary.icons[1].icon.texture=='correct-morph','Front skill uses actual morph icon')
check(canvas.skills.bars.primary.icons[6].icon.texture=='front-ultimate','Front ultimate is independently displayed')
check(canvas.skills.bars.backup.icons[6].icon.texture=='back-ultimate','Back ultimate is independently displayed')
check(canvas.skills.bars.backup.icons[1].empty.text=='—' and canvas.skills.bars.backup.icons[2].icon.texture=='back-morph','Skill slots preserve gaps and do not shift abilities')
check(canvas.skills.bars.werewolf.hidden,'Werewolf row is absent for a non-werewolf')
local setRows=V.SetRows(details.equipment)
local arena
for _,row in ipairs(setRows)do if row.name:find('Crushing Wall',1,true)then arena=row end end
check(arena and arena.name=='2× Crushing Wall' and arena.front==0 and arena.back==2,'The arena headline counts two set pieces from one two-handed item')
check(canvas.champion.rows.COMBAT.icons[1].badge.text=='50','Known CP committed points appear on their star')
check(canvas.champion.rows.CONDITIONING.icons[1].badge.text=='','Unknown CP points never display fabricated numeric allocation')
canvas.champion.rows.COMBAT.icons[1].handlers.OnMouseEnter()
check(hovered==details.skills.champion[1],'Champion hover receives sender-specific star allocation')
check(canvas.masteries.icons[1].data.value.id==900,'Mastery icon uses actual selected ability')
check(canvas.consumables.tiles[1].value.text=='Active','Food active is visible at a glance')
local holeMap=V.ChampionMap({{slot=7,discipline='COMBAT',id=25}})
check(holeMap.COMBAT[1]==nil and holeMap.COMBAT[2]==nil and holeMap.COMBAT[3].id==25,'Champion slot positions preserve empty gaps instead of compacting stars')
local originalLayout=SC.GetChampionSlotLayout
SC.GetChampionSlotLayout=function()return nil end
local unknownMap,layoutKnown=V.ChampionMap(details.skills.champion)
check(not layoutKnown and next(unknownMap.COMBAT)==nil,'Unavailable native CP slot layout cannot invent positions')
SC.GetChampionSlotLayout=originalLayout
local before=created
V.Bind(canvas,player,details)
check(created==before,'Repeated build binding reuses all controls without allocating new controls')
details.curse={known=true,kind='WEREWOLF',transformed=true}
details.skills.werewolfKnown=true;details.skills.werewolf={{slot=3,abilityId=999,icon='werewolf-morph'}}
V.Bind(canvas,player,details)
check(not canvas.skills.bars.werewolf.hidden and canvas.skills.bars.werewolf.icons[1].icon.texture=='werewolf-morph','Transformed bar displays its own morph without replacing weapon bars')
check(canvas.skills.bars.primary.icons[1].icon.texture=='correct-morph','Werewolf transformation preserves front bar')
player.externalUltimates={{bar='front',abilityId=600,name='Shared ultimate',updatedAt=100000,icon='shared-ultimate'}}
player.externalSets={fresh=true,sessionValid=true,updatedAt=99000,setList={{name='Shared set',frontKnown=true,backKnown=false,mainCount=5,backCount=0}}}
V.Bind(canvas,player,nil,'Detailed build unavailable')
check(canvas.equipment.slots.HEAD.data.value==nil and canvas.equipment.slots.HEAD.empty.text=='?','Switching to partial build clears prior equipment')
check(canvas.skills.bars.primary.icons[6].icon.texture=='shared-ultimate','Fresh partial ultimate is shown')
check(canvas.skills.bars.primary.icons[1].data.value==nil,'Partial ultimate does not imply knowledge of normal skills')
local shared=V.SetRows(nil,player.externalSets)[1]
check(shared.name=='≥5× Shared set' and shared.front==5 and shared.back==nil,'Partial sets show the known bar as a lower bound and leave the other bar unknown')
check(canvas.champion.rows.COMBAT.icons[1].data.value==nil,'Switching player removes previous CP data')
check(canvas.masteries.icons[1].hidden,'Switching player hides previous mastery icon')
check(canvas.consumables.tiles[4].value.text=='Unknown','Missing curse state does not become uninfected')
player.connected=false
V.Bind(canvas,player,nil)
check(canvas.skills.bars.primary.icons[6].data.value==nil,'Offline player loses partial ultimate display')
check(canvas.sets.rows[1].hidden,'Offline player loses partial set display')
V.Bind(canvas,nil,nil)
check(canvas.equipment.silhouette.hidden,'No selected player never falls back to own silhouette')
details.equipment.complete=false
local incomplete=V.SetRows(details.equipment)
check(incomplete[1].front==nil and incomplete[1].back==nil,'Incomplete item scan does not claim exact per-bar totals')

-- Headline set counts are effective bar totals, never the sum of both weapon pairs.
local mixed=V.SetRows({complete=true,setList={{id=99,name="Mixed bars",physicalCount=6,physicalCountKnown=true,mainCount=5,backCount=5}}})[1]
check(mixed.name=="5× Mixed bars" and mixed.physical==6 and mixed.effective==5,"Body3 + front sword/shield + back staff count as five set pieces, not six")
check(not mixed.warning,"An unknown native threshold cannot fabricate an excess warning")
GetItemSetInfo=function(id)return true,"Known set",id==101 and 1 or 4 end
GetItemSetBonusInfo=function(id,index)return id==101 and 2 or index+1,"Native bonus"end
local extra=V.SetRows({complete=true,setList={{id=100,name="Six pieces",mainCount=6,backCount=5}}})[1]
check(extra.name=="6× Six pieces" and extra.warning=="1 extra piece • front bar","A true sixth piece stays six and identifies the excessive bar")
check(extra.tooltip:find("requires 5 pieces",1,true),"Excess warning explains the actual native set threshold")
local arenaExtra=V.SetRows({complete=true,setList={{id=101,name="Arena",mainCount=2,backCount=0}}})[1]
check(arenaExtra.required==2 and not arenaExtra.warning,"A full two-piece arena weapon is never judged against an assumed five-piece threshold")
local unknown=V.SetRows({complete=false,setList={{id=100,name="Incomplete",mainCount=6,backCount=5}}})[1]
check(unknown.effective==nil and unknown.warning==nil,"Incomplete equipment cannot assert a total or excess warning")
local badNative=GetItemSetBonusInfo
GetItemSetBonusInfo=function()return 0/0 end
check(V.SetRequirement({id=102})==nil,"Malformed native requirements cannot create false excess warnings")
GetItemSetBonusInfo=badNative
check(canvas.equipment.silhouette.width==104 and canvas.equipment.silhouette.height==264,"Native silhouette fills the body panel with a larger static image")
check(canvas.equipment.slots.HEAD.x+22==canvas.equipment.silhouette.x+52,"Head slot aligns with the center of the figure")
check(canvas.equipment.slots.NECK.y==326 and canvas.equipment.slots.MAIN_HAND.y==421 and canvas.equipment.slots.BACKUP_MAIN.y==421,"Jewelry and both weapon sections retain their accepted positions")

details.equipment.complete=true
details.equipment.setList={{id=100,name="Six pieces",mainCount=6,backCount=5},{id=101,name="Arena",mainCount=0,backCount=2}}
V.Bind(canvas,player,details)
local warningRow=canvas.sets.rows[1]
check(not warningRow.warning.hidden and warningRow.warning.text=="1 extra piece • front bar","True excess is explained visibly on the character sheet")
check(warningRow.warning.y+warningRow.warning.height<=warningRow.height and canvas.sets.rows[2].y>=warningRow.y+warningRow.height,"An excess warning does not overlap the next set")
check(warningRow.front.text=="6×" and warningRow.back.text=="5×","Excess warning leaves both exact bar counts readable")

-- A maximally fragmented loadout remains a single sheet, including Werewolf.
details.equipment.complete=true;details.equipment.setList={}
for i=1,14 do details.equipment.setList[i]={name='Distinct set '..i,physicalCount=1,physicalCountKnown=true,mainCount=1,backCount=1} end
V.Bind(canvas,player,details)
local visibleRows=0
for _,row in ipairs(canvas.sets.rows)do
    if not row.hidden then
        visibleRows=visibleRows+1
        check(row.x+row.width<=552 and row.y+row.height<=canvas.sets.height,'Every set remains inside its panel without pagination')
        check(row.front.text=='F 1×' and row.back.text=='B 1×','Both condensed counts identify their weapon bar')
    end
end
check(visibleRows==14 and canvas.skills.y>=canvas.sets.height+12,'All fourteen sets are displayed without overlapping skill bars')
check(canvas.champion.y>=canvas.skills.y+canvas.skills.height+12 and canvas.consumables.y+canvas.consumables.height<=canvas.height,'Werewolf, CP and readiness fit the expanded single sheet')

-- Bind the actual ESO champion visual contract, never an ability-icon lookup.
WINDOW_MANAGER.CreateControlFromVirtual=function(_,name,parent,template)
    check(template=='ZO_ChampionStarVisuals','Champion tiles instantiate the native ESO composite');return Control(name,parent)
end
ZO_CHAMPION_STAR_VISUAL_TYPE={SLOTTABLE=1};ZO_CHAMPION_STAR_STATE={PURCHASED=2};CHAMPION_DISCIPLINE_TYPE_COMBAT=3
local setups,frames=0,0
ZO_ChampionStarVisuals={New=function(_,control)return {
    Setup=function(_,visual,state,discipline,slotted)check(visual==1 and state==2 and discipline==3 and slotted==false,'Champion visual matches the native assignable-bar state');setups=setups+1 end,
    Update=function(_,time)check(time==0,'Champion artwork is held on a static frame');frames=frames+1 end,
    interpolators={1},control=control}
end}
SC.DescribeChampionSkill=function(_,id)return {icon=id==1 and 'native-combat-background' or ''}end
SC.GetChampionDiscipline=function()return 'COMBAT'end
V.Bind(canvas,player,details)
local nativeTile=canvas.champion.rows.COMBAT.icons[1]
check(setups==1 and frames==1 and nativeTile.icon.texture=='native-combat-background','Champion texture comes from its discipline instead of the ability table')
check(not nativeTile.star.hidden and #nativeTile.starVisuals.interpolators==0 and not nativeTile.star.handlers.OnUpdate,'Native star remains visible without an animation loop')
V.Bind(canvas,nil,nil)
check(nativeTile.star.hidden,'Selecting an unknown build clears the previous native star')
print(string.format('Build visual sheet: %d assertions passed',checks))
