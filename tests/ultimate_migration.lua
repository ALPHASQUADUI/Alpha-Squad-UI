-- Profile-scoped migration into the one personal Ultimate HUD.
local total=0
local function check(value,message) total=total+1;assert(value,message) end
EVENT_ADD_ON_LOADED=1;HOTBAR_CATEGORY_PRIMARY=1;HOTBAR_CATEGORY_BACKUP=2
EVENT_MANAGER={RegisterForEvent=function() end,UnregisterForEvent=function() end}
SLASH_COMMANDS={}
function GetWorldName() return "TestWorld" end
local account,character={},{}
ZO_SavedVars={NewAccountWide=function() return account end,NewCharacterIdSettings=function() return character end}
AlphaSquadUI={Modules={},Preferences={sv={crossSync=true}}}
assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTTracker.lua"))()
assert(loadfile("AlphaSquadUI/Modules/ULTTracker/ULTOverload.lua"))()
local ULT=AlphaSquadUI.Modules.ULTTracker;local O=ULT.Overload
local function Reset(specific)
    ULT.sv={enabled=false,visible=false,trackMode="both",x=500,y=100,scale=100}
    for key,value in pairs(specific or {}) do ULT.sv[key]=value end
    ULT.bars.primary={abilityId=30366,icon="native/icon",category=1}
    ULT.bars.backup={abilityId=101,icon="native/other",category=2}
end
account={addonEnabled=true,visible=true,x=123,y=456,scale=115,positionSaved=true,
    reserveThreshold=140,reserveWarningThreshold=175,readyReminderThreshold=420,reserveSound=false}
Reset();O:Migrate()
check(ULT.sv.enabled and ULT.sv.visible,"An actively used legacy Overload HUD survives an old disabled standard tracker")
check(ULT.sv.x==123 and ULT.sv.y==456 and ULT.sv.scale==115,"A used slotted Overload position and size become the common personal layout")
check(ULT.sv.trackMode=="both","An existing explicit Both choice is preserved")
check(ULT.sv.overload.reserveThreshold==140 and ULT.sv.overload.reserveWarningThreshold==175 and not ULT.sv.overload.reserveSound,"Legacy reserve values and an explicit silent preference are copied")
check(account.x==123 and account.reserveThreshold==140 and account.addonEnabled,"Migration never deletes or mutates the legacy profile")
ULT.sv.enabled=false;ULT.sv.visible=false;ULT.sv.x=850;ULT.sv.overload.enabled=false
O:Migrate()
check(not ULT.sv.enabled and not ULT.sv.overload.enabled and ULT.sv.x==850,"Later OFF and placement choices are never overwritten by repeated migration")
Reset();ULT.bars.primary.abilityId=101;O:Migrate()
check(ULT.sv.x==500 and ULT.sv.y==100 and not ULT.sv.enabled,"A non-Overload build retains its existing Ultimate profile")
account={addonEnabled=false,visible=true,x=123,y=456,reserveThreshold=150}
Reset();O:Migrate()
check(not ULT.sv.overload.enabled and not ULT.sv.enabled and ULT.sv.x==500,"An explicitly disabled legacy Overload module is not re-enabled")
AlphaSquadUI.Preferences.sv.crossSync=false
character={crossSyncSeeded=true,addonEnabled=true,visible=true,x=800,y=240,scale=90,positionSaved=true,reserveThreshold=125}
Reset();O:Migrate()
check(ULT.sv.x==800 and ULT.sv.y==240 and ULT.sv.overload.reserveThreshold==125,"Cross-sync OFF migrates this character's legacy profile")
AlphaSquadUI.Preferences.sv.crossSync=true
Reset();O:Migrate()
check(not ULT.sv.overload.enabled and ULT.sv.overload.reserveThreshold==150,"A fresh account profile uses the account-wide legacy settings independently")
account={addonEnabled=true,visible=true,x=0/0,y=math.huge,scale=-999,reserveThreshold=0/0,reserveWarningThreshold=-math.huge}
Reset();O:Migrate()
check(ULT.sv.x==500 and ULT.sv.y==100 and ULT.sv.scale>=40,"Non-finite legacy geometry cannot corrupt the common HUD")
check(ULT.sv.overload.reserveThreshold==130 and ULT.sv.overload.reserveWarningThreshold>=130,"Corrupt legacy reserve values recover to safe bounded defaults")
account={addonEnabled=true,visible=true,x=222,y=333,scale=110}
Reset();ULT.bars.primary.abilityId=0;ULT.bars.primary.icon=""
O:Migrate(false)
check(ULT.sv.unifiedUltimateVersion~=1 and not ULT.sv.enabled,"Unavailable startup bars cannot finalize the old HUD selection")
ULT.bars.primary.abilityId=30366
check(O:Migrate() and ULT.sv.enabled and ULT.sv.x==222 and ULT.sv.unifiedUltimateVersion==1,"Readable activation bars finalize and preserve the formerly active Overload HUD")
account={}
Reset({enabled=true,visible=true,trackMode="auto"});O:Migrate()
check(ULT.sv.enabled and ULT.sv.overload.enabled and ULT.sv.trackMode=="auto","Fresh installations retain AUTO and enabled behavior without a legacy Overload profile")
print(string.format("PASS: %d assertions; Lua %s. No ESO-runtime certification.",total,_VERSION))
