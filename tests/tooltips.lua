-- Native tooltip ownership, exact identities and layering across addon windows.
local total=0
local function check(value,message) total=total+1;assert(value,message) end
DT_HIGH,DL_OVERLAY,TOPLEFT,TOPRIGHT=2,5,3,9
local function Control(parent)
    local c={parent=parent,tier=1,layer=1,level=12,scale=1,width=384,height=400,hidden=true,lines={},hooks={}}
    function c:GetDrawTier()return self.tier end
    function c:GetDrawLayer()return self.layer end
    function c:GetDrawLevel()return self.level end
    function c:GetScale()return self.scale end
    function c:GetWidth()return self.width end
    function c:GetHeight()return self.height end
    function c:GetRight()return self.right or 150 end
    function c:GetOwningWindow()return self.parent end
    function c:GetOwner()return self.owner end
    function c:SetDrawTier(value)self.tier=value end
    function c:SetDrawLayer(value)self.layer=value end
    function c:SetDrawLevel(value)self.level=value end
    function c:SetScale(value)self.scale=value end
    function c:SetHidden(value)self.hidden=value;if value and self.hooks.OnHide then self.hooks.OnHide() end end
    function c:AddLine(value)self.lines[#self.lines+1]=value end
    return c
end
GuiRoot=Control();GuiRoot.width,GuiRoot.height=1280,720
local infoWindow,itemWindow,abilityWindow=Control(GuiRoot),Control(GuiRoot),Control(GuiRoot)
InformationTooltip,ItemTooltip,AbilityTooltip=Control(infoWindow),Control(itemWindow),Control(abilityWindow)
local owner=Control(GuiRoot)
function ZO_PreHookHandler(control,event,callback)control.hooks[event]=callback end
function InitializeTooltip(tip,control,point,x,y,relative)
    tip.owner,tip.point,tip.offset,tip.relative=control,point,x,relative;tip.lines={};tip:SetHidden(false)
end
function ClearTooltipImmediately(tip)tip.owner=nil;tip.lines={};tip:SetHidden(true) end
function SetTooltipText(tip,text,...)
    assert(select('#',...)==0,'Text must not leak a replacement count into native tooltip color arguments')
    tip:AddLine(text)
end
function ItemTooltip:SetLink(link)self.link=link end
function ItemTooltip:SetBagItem()error('Remote items must never resolve the viewer bag')end
function AbilityTooltip:SetAbilityId(id)self.abilityId=id end
function AbilityTooltip:SetCraftedAbility(id,a,b,c,flags)self.crafted={id,a,b,c,flags} end
local SC={}
AlphaSquadUI={Modules={SupportCoverage=SC}}
assert(loadfile('AlphaSquadUI/Core/Tooltips.lua'))()
local T=AlphaSquadUI.Tooltips
check(T.ShowText(owner,'Coverage'),'Information tooltip is shown')
check(InformationTooltip.level>150 and infoWindow.level>150,'Tooltip AND its top-level parent are raised above every addon panel')
check(infoWindow.tier==DT_HIGH and infoWindow.layer==DL_OVERLAY,'Parent tier and layer match overlay windows')
check(GuiRoot.level==12 and GuiRoot.layer==1,'Never raise the whole game root')
check(InformationTooltip.lines[1]=='Coverage' and InformationTooltip.owner==owner,'Text is bound to the hovered owner')
T.Raise(InformationTooltip);T.Hide()
check(infoWindow.level==12 and InformationTooltip.level==12,'Repeated raise preserves original draw levels for restoration')
check(infoWindow.tier==1 and infoWindow.layer==1 and InformationTooltip.hidden,'Exit restores native styling and hides immediately')
owner.right=1100;T.ShowText(owner,'Right edge')
check(InformationTooltip.point==TOPRIGHT and InformationTooltip.offset<0,'Right-hand icons anchor tooltips to their left')
InformationTooltip.height=1400;T.ShowText(owner,'Tall source list')
check(InformationTooltip.scale*1400<=GuiRoot.height-32,'Long tooltips fit within screen height')
T.Hide();InformationTooltip.height=400
check(InformationTooltip.scale==1,'Native scale is restored after a long tooltip')
T.ShowText(owner,'Close parent');owner.hooks.OnHide()
check(T.active==nil and InformationTooltip.hidden and infoWindow.level==12,'Hiding a hovered owner releases tooltip and draw overrides')
T.ShowText(owner,'Addon tooltip')
local otherOwner=Control(GuiRoot)
InitializeTooltip(InformationTooltip,otherOwner,TOPLEFT,0,0,TOPRIGHT)
T.Hide()
check(not InformationTooltip.hidden and InformationTooltip.owner==otherOwner and infoWindow.level==12,'Reused native tooltip is not cleared when another UI has taken ownership')
ClearTooltipImmediately(InformationTooltip)
local link='|H1:item:1234:364:50:45869:370:50:0:0:0:0:0:0:0:0:0:0:1:0:0:10000:0|h|h'
check(T.ShowItem(owner,{link=link,slot=5,name='Exact sword'},true),'Shared native item tooltip is available')
check(ItemTooltip.link==link,'Native item tooltip receives the exact encoded enchantment/trait link unchanged')
check(ItemTooltip.lines[1]:find("this player's set summary",1,true),'Shared set counters are not presented as sender equipment totals')
check(InformationTooltip.hidden and itemWindow.level>150,'Changing tooltip kind hides the old popup and raises the item parent')
T.ShowItem(owner,{name='Armor',traitName='Divines',traitDescription='Mundus bonus',hasEnchant=false,enchantName='Wrong default'})
local text=InformationTooltip.lines[1]
check(text:find('Divines',1,true) and text:find('No enchantment',1,true) and not text:find('Wrong default',1,true),'Fallback item tooltip preserves the actual trait and explicit missing enchantment')
check(itemWindow.level==12 and ItemTooltip.hidden,'Fallback releases native item popup before showing text')
T.ShowItem(owner,{name='Armor',traitName='Infused',hasEnchant=true,enchantName='Maximum Health',enchantDescription='Adds 868 Maximum Health'})
check(InformationTooltip.lines[1]:find('868 Maximum Health',1,true),'Fallback shows that item exact enchantment text')
T.ShowSkill(owner,{abilityId=40223,name='Aggressive Horn'},true)
check(AbilityTooltip.abilityId==40223 and abilityWindow.level>150,'Native ability tooltip receives the actual slotted morph identity')
check(AbilityTooltip.lines[1]:find("your character's stats",1,true),'Remote native preview discloses the source of calculated numbers')
T.ShowSkill(owner,{abilityId=40223},false)
check(#AbilityTooltip.lines==0,'Local ability tooltip does not claim remote preview')
T.ShowSkill(owner,{abilityId=20000,craftedAbilityId=10,scriptsKnown=true,scripts={{id=11},{id=12},{id=13}}},true)
check(AbilityTooltip.crafted[1]==10 and AbilityTooltip.crafted[2]==11 and AbilityTooltip.crafted[4]==13,'Scribed ability uses all three sender committed scripts')
T.ShowSkill(owner,{abilityId=20000,craftedAbilityId=10,scriptsKnown=false,scripts={{id=11}}},true)
check(InformationTooltip.lines[1]:find('Committed scripts unavailable',1,true) and AbilityTooltip.hidden,'Unknown scribing data never borrows receiver scripts')
local setCrafted=AbilityTooltip.SetCraftedAbility
AbilityTooltip.SetCraftedAbility=nil
T.ShowSkill(owner,{abilityId=20000,craftedAbilityId=10,scriptsKnown=true,scripts={{id=11,name='Focus'},{id=12,name='Signature'},{id=13,name='Affix'}}},true)
check(InformationTooltip.lines[1]:find('Focus',1,true) and AbilityTooltip.hidden,'Missing crafted-tooltip API shows actual script names without substituting receiver scripts')
AbilityTooltip.SetCraftedAbility=setCrafted
T.ShowSkill(owner,{abilityId=0/0})
check(InformationTooltip.lines[1]=='Skill information unavailable.','Malformed ability identity cannot enter native tooltip')
local receivedPoints
function SC:DescribeChampionSkill(id,slot,points,known)
    receivedPoints=points
    return {id=id,name='Master-at-Arms',slot=slot,points=points,pointsKnown=known,description='Increase direct damage.',currentBonus=known and 'Current bonus: 6%' or ''}
end
T.ShowChampion(owner,{id=8,slot=2,points=30,pointsKnown=true})
check(receivedPoints==30,'Champion description gets the inspected player allocation')
check(not InformationTooltip.lines[1]:find('\n\n0\n',1,true),'Champion tooltip has no stray replacement counter')
check(InformationTooltip.lines[1]:find('30 points invested',1,true) and InformationTooltip.lines[1]:find('Current bonus: 6%',1,true),'Champion popup includes verified allocation and resulting bonus')
T.ShowChampion(owner,{id=8,slot=2,points=0,pointsKnown=false})
check(not InformationTooltip.lines[1]:find('0 points',1,true) and not InformationTooltip.lines[1]:find('6%',1,true),'Legacy unknown points do not become a precise zero or invented bonus')
T.ShowText(owner,'Native window hidden');InformationTooltip:SetHidden(true)
check(T.active==nil and infoWindow.level==12,'Native OnHide also restores draw order')
check(not T.ShowText(owner,''),'Empty text closes the current popup')
local original=AbilityTooltip.SetAbilityId
AbilityTooltip.SetAbilityId=function()error('native API temporarily unavailable')end
T.ShowSkill(owner,{abilityId=40223,name='Aggressive Horn',description='The correct fallback description.'})
check(InformationTooltip.lines[1]:find('correct fallback',1,true),'Native failure safely falls back to the correct skill description')
AbilityTooltip.SetAbilityId=original
T.Hide();T.Hide()
check(T.active==nil and infoWindow.scale==1,'Repeated hide is idempotent')
print('Tooltip layering and identities: '..total..' assertions passed')
