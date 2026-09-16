-- Real group settings controls: authority guards, named dropdown, bounded tiles.
local checks=0
local function check(value,message) checks=checks+1;assert(value,message) end
TOPLEFT,TOPRIGHT,LEFT,RIGHT,CENTER=1,2,3,4,5
TEXT_ALIGN_LEFT,TEXT_ALIGN_RIGHT,TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP=1,2,3,4
CT_TEXTURE,CT_CONTROL,CT_LABEL=1,2,3
MOUSE_BUTTON_INDEX_LEFT=1
local controls={}
local function Control(name,parent)
    local c={name=name,parent=parent,hidden=false,handlers={},width=0,height=0}
    function c:SetDimensions(w,h)self.width,self.height=w,h end
    function c:SetWidth(w)self.width=w end
    function c:SetHeight(h)self.height=h end
    function c:SetHidden(h)self.hidden=h end
    function c:IsHidden()return self.hidden end
    function c:SetText(t)self.text=t end
    function c:SetAlpha(a)self.alpha=a end
    function c:SetMaxLineCount(n)self.lines=n end
    function c:SetAnchor(_,_,_,x,y)self.x,self.y=x or 0,y or 0 end
    function c:SetHandler(event,callback)self.handlers[event]=callback end
    for _,key in ipairs({'SetColor','SetAnchorFill','SetFont','SetVerticalAlignment','SetHorizontalAlignment',
        'SetMouseEnabled','SetTextureCoords','SetTexture','SetWrapMode','ClearAnchors','SetClampedToScreen',
        'SetMovable','SetDrawTier','SetDrawLayer','SetDrawLevel','StartMoving','StopMovingOrResizing'})do c[key]=function()end end
    controls[name]=c;return c
end
GuiRoot=Control('Root')
WINDOW_MANAGER={CreateControl=function(_,name,parent)return Control(name,parent)end,
    CreateTopLevelWindow=function(_,name)return Control(name)end,
    CreateControlFromVirtual=function(_,name,parent,template)
        check(name=='AlphaSquadULTGroupLeaderChoice' and template=='ZO_ComboBox','Leader choice owns a unique named native combo root')
        return Control(name,parent)
    end}
function ZO_ComboBox_ObjectFromContainer(container)
    local combo={entries={},container=container,clearCount=0}
    function combo:SetSortsItems()end
    function combo:ClearItems()self.entries={};self.clearCount=self.clearCount+1 end
    function combo:CreateItemEntry(text,callback)return{name=text,callback=callback}end
    function combo:AddItem(entry)self.entries[#self.entries+1]=entry end
    function combo:SetSelectedItemByEval(predicate)for _,entry in ipairs(self.entries)do if predicate(entry)then self.selected=entry.name;return end end end
    function combo:SetSelectedItem(value)self.selected=value end
    function combo:SetEnabled(value)self.enabled=value end
    return combo
end
local editable,appointable,chosen=true,true,'@Crown'
local members={{account='@Crown',isCrown=true},{account='@RaidLead'},{account='@Member'}}
local selected,mutations={},0
local families={}
for index=1,18 do families[index]={id=100+index,key='family'..index,name='Support Ultimate '..index,icon='native.dds',users=2}end
local Group={libraryAvailable=true,sv={},GetAvailableAbilities=function()return families end,
    GetSharingCount=function()return 2,3 end,GetTrackedAbilityCount=function()return 2 end,
    ApplyConfigWindowScale=function()end,CanEditFilters=function()return editable,'Only the designated raid leader can change Ultimate filters.'end,
    IsAbilityTracked=function(_,key)return selected[key]==true end,
    SetAbilityTracked=function(_,key,value)mutations=mutations+1;selected[key]=value;return true end,
    SetAllTracked=function(_,value)mutations=mutations+1;for _,f in ipairs(families)do selected[f.key]=value end;return true end}
Group.Sync={GetMembers=function()return members end,GetLeader=function()return chosen end,
    CanAssignLeader=function()return appointable,'Only the group crown can appoint the raid leader.'end,
    SetLeader=function(_,account)mutations=mutations+1;chosen=account;return true end,
    GetStatus=function()return 'Settings sync unavailable'end}
AlphaSquadUI={Modules={ULTTracker={Group=Group}},Settings={CreateScrollArea=function(parent,name,x,y,w,h)
    local c=Control(name,parent);c:SetDimensions(w,h);c:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);return c,c end},
    Preferences={sv={language='en'},Initialize=function()end}}
assert(loadfile('AlphaSquadUI/Core/Localization.lua'))()
assert(loadfile('AlphaSquadUI/Localization/fr.lua'))()
AlphaSquadUI.Localization.Initialize()
assert(loadfile('AlphaSquadUI/Modules/ULTTracker/ULTGroupSettings.lua'))()
Group:CreateConfigWindow();Group.configWindow:SetHidden(false);Group:RefreshConfig()
local win,combo=Group.configWindow,Group.configWindow.leaderCombo
check(combo.enabled and #combo.entries==3 and combo.selected=='@Crown (crown)','Crown sees the native-group accounts and current selected raid leader')
local clearCount=combo.clearCount
Group:RefreshConfig();check(combo.clearCount==clearCount,'Unchanged roster refresh does not rebuild the dropdown')
for index=1,18 do
    local row=win.abilityRows[index]
    check(not row.hidden and row.x>=0 and row.x+row.width<=736 and row.y+row.height<=win.abilityContent.height,
        'Curated family tile '..index..' stays inside scrollable content')
end
check(win.abilityRows[19].hidden,'Unused controls stay hidden')
combo.entries[2].callback();check(chosen=='@RaidLead','The crown can appoint another current group account')
appointable=false;Group:RefreshConfig();local before=mutations
combo.entries[3].callback()
check(mutations==before and chosen=='@RaidLead' and not combo.enabled,'A stale dropdown callback cannot bypass crown authority')
check(win.permission.text=='Only the group crown can appoint the raid leader.','A denied selection gives an inline explanation')
editable=false;Group:RefreshConfig();before=mutations
win.abilityRows[1].handlers.OnMouseUp(nil,MOUSE_BUTTON_INDEX_LEFT,true)
controls.AlphaSquadULTGroupSelectAll.handlers.OnMouseUp(nil,MOUSE_BUTTON_INDEX_LEFT,true)
controls.AlphaSquadULTGroupClearAll.handlers.OnMouseUp(nil,MOUSE_BUTTON_INDEX_LEFT,true)
check(mutations==before,'Read-only members cannot change a family, select all or clear all')
check(win.permission.text=='Only the designated raid leader can change Ultimate filters.','Unauthorized filter clicks explain the raid leader rule')
editable=true;win.abilityRows[1].handlers.OnMouseUp(nil,MOUSE_BUTTON_INDEX_LEFT,true)
check(selected.family1 and mutations==before+1,'The raid leader toggles the stable family key')
controls.AlphaSquadULTGroupClearAll.handlers.OnMouseUp(nil,MOUSE_BUTTON_INDEX_LEFT,true)
check(mutations==before+2 and not selected.family1,'Bulk changes use one domain operation')
AlphaSquadUI.Localization.SetLanguage('fr');Group:RefreshConfig()
check(controls.AlphaSquadULTGroupLeaderLabel.text=='RESPONSABLE DE RAID','The existing authority label follows the selected addon language')
check(win.abilityRows[1].name.lines==2 and win.permission.height==38,'Names and authority explanations retain bounded multiline space')
members={};Group:RefreshConfig()
check(#combo.entries==0 and not combo.enabled and combo.selected==AlphaSquadUI.L('No group'),'Leaving the group clears stale account choices')
print('Group settings authority and layout: '..checks..' assertions passed')
