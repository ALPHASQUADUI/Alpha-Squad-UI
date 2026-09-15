-- Exercise the actual module page builders across changing logical viewports.
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
TOPLEFT,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP,CT_TEXTURE=1,2,3,4
local controls,cards={},{}
local function Control(name,parent)
    local control={name=name,parent=parent,width=0,height=0,scale=1}
    function control:SetAnchor(_,_,_,x,y)self.x,self.y=x or 0,y or 0 end
    function control:SetDimensions(w,h)self.width,self.height=w,h end
    function control:SetWidth(w)self.width=w end
    function control:SetHeight(h)self.height=h end
    function control:GetScale()return self.scale*(self.parent and self.parent:GetScale() or 1)end
    function control:GetWidth()return self.width*self:GetScale()end
    function control:SetText(text)self.text=text end
    for _,method in ipairs({'SetHorizontalAlignment','SetVerticalAlignment','SetColor','SetHandler','SetMouseEnabled',
        'ClearAnchors','SetHidden','SetTexture'})do control[method]=function()end end
    controls[#controls+1]=control
    return control
end
WINDOW_MANAGER={CreateControl=function(_,name,parent)return Control(name,parent)end}
local ULT={sv={trackMode='auto'},GetLiveBar=function()return nil end,HasSpecialActiveBar=function()return false end}
local builders={}
AlphaSquadUI={Modules={ULTTracker=ULT},Settings={RegisterPage=function(id,builder)builders[id]=builder end}}
assert(loadfile('AlphaSquadUI/Modules/ULTTracker/ULTTrackerSettings.lua'))()
local ui={}
ui.CreateLabel=function(parent,name,_,text)
    local label=Control(name,parent);label:SetText(text);return label
end
ui.CreateCard=function(parent,name,x,y,w,h)
    local card=Control(name,parent);card:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);card:SetDimensions(w,h)
    cards[#cards+1]=card;return card
end
ui.CreateButton=function(parent,name,text,x,y,w,h)
    local button=Control(name,parent);button:SetAnchor(TOPLEFT,parent,TOPLEFT,x,y);button:SetDimensions(w,h)
    button.label=Control(name..'Label',button);button.bg=Control(name..'BG',button);return button
end
ui.AddToggleRow=function()end
ui.AddStepperRow=function()end
ui.RegisterRefresher=function()end
ui.RegisterLayout=function(page,callback)page.ApplyLayout=callback end
local function Overlaps(a,b)
    return a.x<b.x+b.width and b.x<a.x+a.width and a.y<b.y+b.height and b.y<a.y+a.height
end
for _,id in ipairs({'ulttracker','ultoverload'})do
    controls,cards={},{}
    local page=Control(id);page:SetDimensions(1078,600);page.scale=1.25
    builders[id](page,ui)
    check(type(page.ApplyLayout)=='function',id..' registers an adaptive page layout')
    for _,width in ipairs({1078,962,844,764,604,1078})do
        page:SetWidth(width);page.ApplyLayout(width,520,width<1000)
        local valid=true
        for _,card in ipairs(cards)do
            valid=valid and card.x>=0 and card.y>=0 and card.x+card.width<=width and card.y+card.height<=page.contentHeight
            for _,other in ipairs(cards)do if card~=other and Overlaps(card,other)then valid=false end end
        end
        check(valid,id..' cards remain aligned, contained and separate at width '..width)
        local childrenInside=true
        for _,control in ipairs(controls)do
            if control.parent and control.x then
                childrenInside=childrenInside and control.x>=0 and control.width>0
                    and control.x+control.width<=control.parent.width+0.001
            end
        end
        check(childrenInside,id..' labels, native icons and buttons stay within resized parent controls at '..width)
        check((cards[1].width>width*0.8)==(width<860),id..' changes columns instead of shrinking text at '..width)
    end
end
print('Ultimate settings layout: '..checks..' assertions passed')
