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
function SC:DescribeChampionSkill(id,slot,points,known)
    return {id=id,slot=slot,points=points,pointsKnown=known,icon="champion.dds",description=known and ("Allocation "..points) or nil}
end
dofile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageBuildCodec.lua")
local link="|H1:item:123456:364:50:26588:370:50:0:0:0:0:0:0:0:0:0:-1:0:0:0:0:0:0:0:0|h|h"
local item={slot=1,link=link,enchantHasCharges=false,enchantSuppressedByPoison=true}
local input={classId=1,equipment={complete=true,slots={{slot=1,known=true,item=item},{slot=2,known=true,empty=true}},
    setList={{id=30,mainCount=4,backCount=5}}},
    skills={known=true,primary={{slot=3,abilityId=123,boundAbilityId=456,rank=4}},
        backup={{slot=4,abilityId=789,boundAbilityId=9,craftedAbilityId=9,scriptsKnown=true,scripts={{id=11},{id=12},{id=13}}}},
        championKnown=true,champion={{slot=1,id=33,points=50}}},
    masteries={known=true,eligible=true,selected={{id=1200,rank=1}},learnedIds={[100]=2,[101]=1},
        skillLines={{id=20,classId=1,rank=50,active=true,mastery=false,native=true}},
        passives={{id=100,rank=2,lineId=20}}},
    food={verified=true,active=true,abilityId=440,timeEnds=200},
    potion={known=true,selectionKnown=true,isPotion=true,link=link,count=200},
    poisons={known=true,items={{slot=15,link=link}}},
    curse={known=true,kind="WEREWOLF",transformed=true},
    capabilities={major_courage={mainBar=false,backBar=true,conditional=true}}}
input.skills.werewolfKnown=true
input.skills.werewolf={{slot=3,abilityId=101,boundAbilityId=101},{slot=8,abilityId=102,boundAbilityId=102}}
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
check(output.skills.primary[1].rank==4 and output.skills.backup[1].rank==nil,
    "Exact morph progression rank survives; unreadable rank does not become rank four")
check(output.skills.backup[1].craftedAbilityId==9 and #output.skills.backup[1].scripts==3,"Scribing choices remain exact")
check(output.skills.champion[1].points==50 and output.masteries.learnedIds[100]==2,"Champion and purchased passive ranks survive")
check(output.skills.champion[1].pointsKnown and output.skills.champion[1].description=="Allocation 50"
    and output.skills.champion[1].icon=="champion.dds","Remote Champion details use sender allocation through the shared descriptor")
check(output.curse.known and output.curse.kind=="WEREWOLF" and output.curse.transformed,
    "Verified Werewolf identity and transformed status survive")
check(output.skills.werewolfKnown and #output.skills.werewolf==2 and output.skills.werewolf[2].ultimate
    and output.skills.primary[1].abilityId==123 and output.skills.backup[1].abilityId==789,
    "Werewolf skills and ultimate remain separate from both normal morph bars")
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
local legacyBody=string.char(1,1)..string.rep(string.char(0),3)
    ..string.char(0,0,0,1,1,1,33,50)..string.rep(string.char(0),6+4+5+2+2)
local legacy=SC.BuildCodec.Decode(legacyBody)
check(legacy and legacy.buildSchemaVersion==1 and not legacy.curse.known and not legacy.skills.werewolfKnown,
    "Previous build schema remains readable without inventing curse or Werewolf data")
check(legacy and legacy.skills.champion[1].points==50 and legacy.skills.champion[1].pointsKnown==false
    and not legacy.skills.champion[1].description,"Legacy allocations remain unverified: previous senders encoded unknown as zero")
check(SC.BuildCodec.Decode(string.char(7)..body:sub(2))==nil,"Unknown build schema fails closed")
input.curse.transformed=false
output=assert(SC.BuildCodec.Decode(assert(SC.BuildCodec.Encode(input))))
check(output.curse.transformed==false,"Known untransformed Werewolf is distinct from missing status")
input.curse={known=true,kind="VAMPIRE",stage=4}
output=assert(SC.BuildCodec.Decode(assert(SC.BuildCodec.Encode(input))))
check(output.curse.kind=="VAMPIRE" and output.curse.stage==4 and output.curse.transformed==nil,"Vampire stage is shared without pretending Werewolf form")
input.curse.stage=5
check(SC.BuildCodec.Encode(input)==nil,"Impossible Vampire stage is rejected")
input.curse={known=true,kind="INVALID"}
check(SC.BuildCodec.Encode(input)==nil,"Unknown curse category cannot become verified human")
input.curse={known=true,kind="NONE"}
input.skills.champion[1].points=nil
output=assert(SC.BuildCodec.Decode(assert(SC.BuildCodec.Encode(input))))
check(output.skills.champion[1].pointsKnown==false and output.skills.champion[1].description==nil,
    "An unreadable Champion allocation never becomes an exact zero-point tooltip")
input.skills.champion[1].points=3601
check(SC.BuildCodec.Encode(input)==nil,"Impossible Champion allocation is rejected before sharing")
input.skills.champion[1].points=0
output=assert(SC.BuildCodec.Decode(assert(SC.BuildCodec.Encode(input))))
check(output.skills.champion[1].pointsKnown and output.skills.champion[1].description=="Allocation 0",
    "A verified zero-point allocation remains exact")
input.skills.werewolf[3]={slot=8,abilityId=103}
check(SC.BuildCodec.Decode(assert(SC.BuildCodec.Encode(input)))==nil,"Duplicate Werewolf ultimate slot is rejected")
input.skills.werewolf[3]=nil
input.equipment.slots[3]={slot=1,known=true,item=item}
check(SC.BuildCodec.Decode(assert(SC.BuildCodec.Encode(input)))==nil,"Duplicate equipment position rejected")
input.equipment.slots[3]=nil
input.equipment.slots[1].item.link="|H1:item:1:0|hInjected text|h"
check(SC.BuildCodec.Encode(input)~=nil,"Item display text is not serialized; only native numeric item fields leave the client")
input.equipment.slots[1].item.link="not an item link"
check(SC.BuildCodec.Encode(input)==nil,"Unsupported links fail closed without executing arbitrary text")

-- Verify the actual capability engine cannot turn contradictory wire metadata
-- into a covered set. The fixture has three body pieces, sword/shield on the
-- front and a perfected-family staff on the back: five pieces on either bar.
SC.Catalog.setSources={{setId=30,label="Support set",requiredPieces=5,provides={"major_courage"}}}
SC.Try=function(fn,...)
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,...);if ok then return value end
end
function GetItemSetUnperfectedSetId(id) return id==31 and 30 or 0 end
SC.EquipmentSlotOrder={};SC.EquipmentSlotDetails={}
for slot=1,14 do
    SC.EquipmentSlotOrder[slot]=slot
    SC.EquipmentSlotDetails[slot]={slotKey="slot"..slot,slotName="Slot "..slot,
        bar=slot<=10 and "BOTH" or slot<=12 and "PRIMARY" or "BACKUP"}
end
function SC:DescribeEquipmentItem(slot,link)
    if link=="" then return nil end
    local id=tonumber(link:match("|H%d+:item:(%d+):"))
    local descriptor=self.EquipmentSlotDetails[slot] or {}
    return {slot=slot,link=link,slotKey=descriptor.slotKey,slotName=descriptor.slotName,bar=descriptor.bar,
        setId=id==204 and 31 or 30,setName="Support set",hasSet=true,setVerified=true,
        isWeapon=descriptor.bar~="BOTH",twoHanded=id==204}
end
dofile("AlphaSquadUI/Modules/SupportCoverage/SupportCoverageSources.lua")
local function EquippedBuild()
    local equipment={complete=true,slots={},setList={{id=30,mainCount=5,backCount=5}}}
    for slot=1,14 do
        local id=slot<=3 and 101 or slot==11 and 202 or slot==12 and 203 or slot==13 and 204 or nil
        local item=id and {link="|H1:item:"..id..":0|h|h"} or nil
        equipment.slots[#equipment.slots+1]={slot=slot,known=true,empty=not item,item=item}
    end
    return {equipment=equipment}
end
local function DecodeBuild(build) return assert(SC.BuildCodec.Decode(assert(SC.BuildCodec.Encode(build)))) end
local consistent=DecodeBuild(EquippedBuild())
check(consistent.equipment.complete and consistent.equipment.countsVerified,
    "Complete native slots verify front/back totals with perfected-family two-handed weight")
check(consistent.capabilities.major_courage and consistent.capabilities.major_courage.mainBar
    and consistent.capabilities.major_courage.backBar,"Consistent real items prove support-set coverage on both bars")
local invalid=EquippedBuild();table.remove(invalid.equipment.slots,14)
check(not DecodeBuild(invalid).equipment.complete,"A missing empty off-hand record cannot establish a complete equipment scan")
invalid=EquippedBuild();invalid.equipment.slots[14].known=false
check(not DecodeBuild(invalid).equipment.complete,"An explicitly unknown slot blocks claimed equipment completeness")
invalid=EquippedBuild();invalid.equipment.setList[1].mainCount=6
local inconsistent=DecodeBuild(invalid)
check(not inconsistent.equipment.complete and not inconsistent.capabilities.major_courage,
    "Inflated set totals remain unverified and do not become a covered capability")
invalid=EquippedBuild();invalid.equipment.slots={}
check(not DecodeBuild(invalid).capabilities.major_courage,"A set claim without any linked equipment cannot produce coverage")
invalid=EquippedBuild();invalid.equipment.setList={}
check(not DecodeBuild(invalid).equipment.complete,"Omitting a set present in linked equipment invalidates the totals")
invalid=EquippedBuild();invalid.equipment.slots[11].item.link="|H1:item:204:0|h|h"
invalid.equipment.setList[1].mainCount=6
check(not DecodeBuild(invalid).equipment.complete,"A two-handed front weapon plus an occupied off-hand cannot establish valid coverage")
invalid=EquippedBuild();invalid.equipment.setList[2]={id=31,mainCount=5,backCount=5}
check(not DecodeBuild(invalid).equipment.complete,"Perfected and normal variants cannot duplicate the same family claim")
local verifiedDescriptor=SC.DescribeEquipmentItem
function SC:DescribeEquipmentItem(slot,link)
    local item=verifiedDescriptor(self,slot,link);if item then item.setVerified=false end;return item
end
check(not DecodeBuild(EquippedBuild()).equipment.complete,"Unreadable native set identity cannot become verified equipment")
SC.DescribeEquipmentItem=verifiedDescriptor
print("Build codec: "..count.." assertions passed")
