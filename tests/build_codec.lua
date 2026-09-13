-- Binary builds must retain exact native identity and reject malformed/truncated records.
local count=0
local function check(value,message) count=count+1;assert(value,message) end
local SC={Catalog={effects={major_courage={},crusher={},minor_toughness={}}}}
AlphaSquadUI={Modules={SupportCoverage=SC}}
function GetAbilityName(id) return "Ability "..id end
function GetAbilityIcon() return "skill.dds" end
function GetItemLinkName() return "Translated item" end
function GetChampionSkillName(id) return "Champion "..id end
function GetSkillLineNameById(id) return "Line "..id end
function GetItemSetName() return "Translated set" end
function GetFrameTimeSeconds() return 100 end
function SC:DescribeEquipmentItem(slot,link)
    if link=="" then return nil end
    return {slot=slot,link=link,name="Translated item",slotName="Feet",slotKey="feet",bar="BOTH",order=1,setId=30,setName="Translated set"}
end
SC.EquipmentSlotDetails={[2]={slotName="Legs",slotKey="legs",bar="BOTH",order=2}}
SC.GetChampionDiscipline=function() return "COMBAT" end
dofile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageBuildCodec.lua")
local link="|H1:item:123456:364:50:0:0:0:0:0:0:0:0:0:0:0:0:-1:0:0:0:0:0:0:0:0|h|h"
local item={slot=1,link=link,enchantHasCharges=false,enchantSuppressedByPoison=true}
local input={classId=1,equipment={complete=true,slots={{slot=1,known=true,item=item},{slot=2,known=true,empty=true}},
    setList={{id=30,mainCount=4,backCount=5}}},
    skills={known=true,primary={{slot=3,abilityId=123,boundAbilityId=456}},
        backup={{slot=4,abilityId=789,boundAbilityId=9,craftedAbilityId=9,scriptsKnown=true,scripts={{id=11},{id=12},{id=13}}}},
        championKnown=true,champion={{slot=1,id=33,points=50}}},
    masteries={known=true,eligible=true,selected={{id=1200,rank=1}},learnedIds={[100]=2,[101]=1},
        skillLines={{id=20,classId=1,rank=50,active=true,mastery=false,native=true}},
        passives={{id=100,rank=2,lineId=20}}},
    food={verified=true,active=true,abilityId=440,timeEnds=200},
    potion={known=true,selectionKnown=true,isPotion=true,link=link,count=200},
    poisons={known=true,items={{slot=15,link=link}}},
    capabilities={major_courage={mainBar=false,backBar=true,conditional=true}}}
local body,errorText=SC.BuildCodec.Encode(input)
check(body and #body<500,"Typical exact build stays compact: "..tostring(errorText))
local output=SC.BuildCodec.Decode(body)
check(output~=nil,"Exact build decodes")
check(output.equipment.items[1].link==link,"Signed numeric item-link fields roundtrip without lost glyph identity")
check(output.equipment.items[1].enchantHasCharges==false and output.equipment.items[1].enchantSuppressedByPoison==true,
    "Depleted and poison-suppressed enchantment evidence survives sharing")
check(#output.equipment.slots==2 and output.equipment.slots[2].empty and output.equipment.slots[2].slotName=="Legs",
    "Empty slots stay explicit and retain user-facing slot labels")
check(output.equipment.setList[1].mainCount==4 and output.equipment.setList[1].backCount==5,"Independent bar set counts survive")
check(output.skills.primary[1].abilityId==123 and output.skills.primary[1].boundAbilityId==456
    and output.skills.primary[1].craftedAbilityId==nil,"Normal ability stays normal; numeric zero must not become a crafted skill")
check(output.skills.backup[1].craftedAbilityId==9 and #output.skills.backup[1].scripts==3,"Scribing choices remain exact")
check(output.skills.champion[1].points==50 and output.masteries.learnedIds[100]==2,"Champion and purchased passive ranks survive")
check(output.masteries.passives[1].lineId==20 and output.masteries.skillLines[1].native,"Class line/passive identity remains available")
check(output.food.verified and output.food.active and output.potion.count==200,"Consumable readiness survives")
check(output.capabilities.major_courage.backBar and not output.capabilities.major_courage.mainBar,"Expanded capability bar hints survive")
local before=SC.BuildCodec.Hash(body)
input.food.timeEnds=190
check(SC.BuildCodec.Hash(assert(SC.BuildCodec.Encode(input)))==before,"A running food timer cannot invalidate the equipment fingerprint")
for index=1,#body-1 do check(SC.BuildCodec.Decode(body:sub(1,index))==nil,"Truncated build rejected at byte "..index) end
check(SC.BuildCodec.Decode(body.."x")==nil,"Trailing payload rejected")
SC.Catalog.effects.new_effect={}
output=SC.BuildCodec.Decode(body)
check(output and not output.catalogCompatible and next(output.capabilities)==nil,"Different catalog never reinterprets capability indices")
input.equipment.slots[3]={slot=1,known=true,item=item}
check(SC.BuildCodec.Decode(assert(SC.BuildCodec.Encode(input)))==nil,"Duplicate equipment position rejected")
input.equipment.slots[3]=nil
input.equipment.slots[1].item.link="|H1:item:1:0|hInjected text|h"
check(SC.BuildCodec.Encode(input)~=nil,"Item display text is not serialized; only native numeric item fields leave the client")
input.equipment.slots[1].item.link="not an item link"
check(SC.BuildCodec.Encode(input)==nil,"Unsupported links fail closed without executing arbitrary text")
print("Build codec: "..count.." assertions passed")
