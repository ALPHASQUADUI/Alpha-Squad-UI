# Support Coverage catalog

Reviewed 15 September 2026 for the U50 catalog. There are **159 selectable entries** covering group effects, useful set sources, class passives, selected masteries and support Champion stars. Trial and Dungeon choose small default lists; every entry can be enabled or disabled independently.

Coverage means an available, reported build source. It does not mean that a buff is active on every player. [Catalog evidence and remaining verification work](CATALOG_EVIDENCE.md) records what was checked and what remains conditional.

## How sources are counted

- A set must reach its actual threshold on Front or Back. Normal and Perfected variants are grouped using the native family API. Front and Back weapon counts are never added together.
- Native ability identities distinguish skills and morphs. A native name takes priority over a reported label. An English fallback is an exact name, not a substring match.
- Learned passives use reported native ability IDs and require their relevant slotted trigger line. Selected class masteries require their exact ability ID, eligibility and prerequisite rank; class identity or a received display name alone is insufficient.
- The Werewolf bar supplies capabilities only while the character is confirmed transformed and that bar is known. Human-form slots do not imply that Roar can currently be cast.
- Scribing requires all three reported script IDs in their native slots, available in the grimoire's definition and forming a legal combination. Banner and eleven other grimoires have explicit rules. The same Affix can be Major on one grimoire and Minor on another; an allied buff requires a suitable Focus or link. Personal scripts and the Scribing Class Mastery script do not become group class-masteries.
- Remote library data stays explicitly partial. LibSetDetection's last report is valid within the same group session; it supplies sets, not inventory, traits, skills or Champion allocations.
- A duplicate identifies multiple holders. Range, target limits, split groups and cast rotations can justify deliberate duplicates.
- Variable penetration from Crusher and Alkosh is excluded from the fixed numeric budget. Their presence is still tracked. Tremorscale and other scaling effects likewise do not receive invented maximum values.

## Visuals and native tooltips

Every row has an image. Exact native effect, script, mastery or item textures are preferred. A real supplying skill can represent a source, and the tooltip identifies it. Champion stars use the native slottable star symbol; the game does not provide a distinct image for every star.

Set previews use the native collection piece and verify its set identity. An already loaded LibSets can supply a crafted-set reference item through its public API. If an exact image is unavailable, a native category symbol remains visible and is explicitly described as a category symbol. It is never labelled as the missing item's actual artwork. Reference set tooltips are not a player's exact equipped item; Builds uses that player's item link.

## Conservative limits

The verified ID/name inventory is broader than the set of game interactions reproduced by offline tests. The automatic source catalog is finite. An unlisted source is unverified, not proof that the player cannot provide the effect.

Traumatic Burns uses the native learned IDs of the passive renamed from Warmth. The Storm Voice prerequisite resolves the reported learned ID through the native passive definition, Draconic Power line, rank and exact native texture. Its similarly named combat-effect bundles cannot establish the prerequisite. Neither path depends on an English display name. Missing native definition APIs leave The Storm Voice unverified. Support Champion node identities are recorded explicitly and allocation is checked with native APIs.

Scribing covers the documented Affixes and ally shields below, plus Traveling Knife's Warrior's Opportunity Signature. Other scripts remain inspectable without assigning undocumented group capabilities. Personal Trample Heroism/Protection, Shield Throw's returning buffs and Traveling Knife Berserk/Force do not cover allies. Enemy-targeting and ally-targeting recipes remain distinct. Future balance updates require a fresh catalog review.

## Scribing recipient rules

All entries below also require native recipe validation. These describe potential sources before combat, not an observed cast or a promise that every group member receives the effect.

| Grimoire | Tracked enemy effects | Tracked allied effects |
|---|---|---|
| Banner Bearer | None | Existing seven Focus auras and selected group Affixes while the banner is active and allies are in range |
| Shield Throw | Major Cowardice, Major Maim, Off Balance | None; returning buffs are personal |
| Smash | Minor Breach, Minor Maim | Minor Berserk, Force, Vitality with Healing or Damage Shield Focus; ally shield with its shield Focus |
| Trample | Minor Vulnerability, Minor Cowardice, Off Balance | None; Heroism and Protection are personal |
| Vault | Minor Vulnerability, Minor Maim, Minor Lifesteal, Off Balance | Minor Berserk, Force, Intellect/Endurance with Healing Focus |
| Traveling Knife | Minor Vulnerability, Minor Maim, Minor Lifesteal, Off Balance; Warrior's Opportunity Signature | None |
| Torchbearer | Minor Breach, Minor Cowardice | Minor Heroism, Resolve, Vitality with Healing Focus |
| Ulfsild's Contingency | Minor Breach, Minor Vulnerability, Minor Magickasteal | Minor Force, Protection, Resolve, Intellect/Endurance with Healing or Damage Shield Focus; ally shield |
| Wield Soul | Major Breach, Major Cowardice, Major Maim | Major Resolve, Vitality, Intellect/Endurance or Empower with Healing or Damage Shield Focus; shield can target an ally |
| Soul Burst | Minor Breach, Minor Maim, Minor Magickasteal | Minor Courage, Resolve, Intellect/Endurance with Healing or Damage Shield Focus; ally shield |
| Elemental Explosion | Minor Brittle, Minor Cowardice, Minor Lifesteal, Minor Magickasteal, Off Balance | None |
| Mender's Bond | Minor Breach, Brittle, Maim, Vulnerability on enemies in the link | Minor Courage, Force, Heroism, Protection, Vitality, Intellect/Endurance or Empower on allies in the link; shield Focus protects linked allies |

The native definition decides whether a particular Focus/Signature/Affix combination is legal. An unlisted Focus does not inherit target rules from another grimoire. Range, target caps, immunities and actual application still need to be considered when assigning a player.

## Catalog

| Effect or source | Category | Contribution | Catalog suppliers |
|---|---|---|---|
| Burning | advanced | A Flame damage status. It can enable status-dependent builds, but is not itself a group damage amplifier. | Inspect source conditions; not automatically inferred |
| Chilled | advanced | Applies Minor Maim. Minor Brittle additionally requires an active Ice Staff; Tundra's Maw can add Major Brittle. | Inspect source conditions; not automatically inferred |
| Concussion | advanced | Applies Minor Vulnerability and enables Off Balance with a Lightning Wall. | Inspect source conditions; not automatically inferred |
| Diseased | advanced | Applies Minor Defile, which matters only when the enemy's healing or shields are relevant. | Thurvokun |
| Hemorrhaging | advanced | A Bleed damage status. It can enable status-dependent builds, but is not itself a group damage amplifier. | Inspect source conditions; not automatically inferred |
| Off Balance | advanced | Useful for Exploiter, Heavy Attacks and resource return. Bosses have an immunity interval; owning a source does not mean permanent availability. | Inspect source conditions; not automatically inferred |
| Overcharged | advanced | Applies Minor Magickasteal. | Inspect source conditions; not automatically inferred |
| Poisoned | advanced | A Poison damage status. It can enable status-dependent builds, but is not itself a group damage amplifier. | Inspect source conditions; not automatically inferred |
| Sundered | advanced | Applies Minor Breach. Its extra offensive benefit for the attacker is personal. | Inspect source conditions; not automatically inferred |
| Elemental Catalyst | critical | Flame, Frost and Shock damage from the wearer produce three separate weaknesses. Full strength requires all three: up to 15 percentage points of Critical Damage taken. | Elemental Catalyst |
| Glittering Goad | critical | A Bash or Heavy Attack starts a damage effect. Completion applies Minor Brittle; early target death instead restores nearby group resources. | Glittering Goad |
| Lucent Echoes | critical | Above 50% wearer Health, other eligible allies gain 11 percentage points of Critical Damage and Healing. Other wearers do not receive the bonus. | Lucent Echoes |
| Major Brittle | critical | The target takes 20 additional percentage points of Critical Damage. Tundra's Maw requires Chilled; Nunatak requires its sequence of hits. Check each damage dealer's cap. | Nunatak; Tundra's Maw |
| Major Force | critical | Adds 20 percentage points of Critical Damage, subject to each player's critical damage cap. | Saxhleel Champion; Aggressive Horn; Ink-Scribe's Verve |
| Minor Brittle | critical | The target takes 10 additional percentage points of Critical Damage. Chilled requires an Ice Staff on the active bar; Colorless Pool and compatible Scribing provide alternatives. | Glittering Goad; Rune of the Colorless Pool; Chilled with an active Ice Staff |
| Minor Force | critical | Adds 10 percentage points of Critical Damage. Many damage dealers already provide this to themselves; check the intended recipients before assigning a support source. | Phoenix Moth Theurge; The Blind; Twilight Remedy; Roar |
| Minor Prophecy | critical | +1314 Spell Critical rating for affected group members. | Exploitation |
| Minor Savagery | critical | +1314 Weapon Critical rating for affected group members. | Hemorrhage |
| Nunatak | critical | Frost damage creates an area; four hits on the same target trigger Major Brittle. | Nunatak |
| The Blind | critical | A critical heal grants a shield and Minor Force while it holds, then briefly after it ends. | The Blind |
| Twilight Remedy | critical | An ally must activate a synergy created by the wearer to receive healing and Minor Force. | Twilight Remedy |
| Cutthroat's Focus | debuff | Cutthroat's Focus applies 5% increased damage taken to an attacker after its special dodge succeeds. Against monsters the debuff lasts 20 seconds. | Cutthroat's Focus |
| Encratis's Behemoth | debuff | Encratis's Behemoth improves Flame Damage taken by enemies and reduces Flame Damage taken by allies in its aura. Its value depends on actual Flame Damage in the encounter. | Encratis's Behemoth |
| Heat Shock | debuff | Magma Fist applies Heat Shock, adding 66 damage taken per stack, up to three stacks. This is flat damage per hit, not a percentage damage multiplier. | Magma Fist |
| Infallible Mage | debuff | A fully charged Heavy Attack applies Minor Vulnerability. The three-piece Minor Slayer is personal. | Infallible Mage |
| Major Vulnerability | debuff | The target takes 10% more damage. Colossus, Turning Tide and Archdruid Devyric are alternative providers of the same debuff. | Archdruid Devyric; Turning Tide; Frozen Colossus |
| Martial Knowledge | debuff | A Light Attack below 50% Stamina applies 8% increased damage taken for 5 seconds, with an 8 second cooldown. | Way of Martial Knowledge |
| Minor Vulnerability | debuff | The target takes 5% more damage. Concussion, Fetcher Infection, Boneyard and Colorless Pool are examples of alternative sources. | Infallible Mage; Swarm; Boneyard; Lotus Fan; Ambush; Rune of the Colorless Pool; Concussion |
| Nazaray | debuff | Spending Ultimate extends existing Major and Minor debuffs on nearby enemies. It creates none of them and does not extend every unique debuff. | Nazaray |
| Serpent's Disdain | debuff | Extends Status Effects applied by the wearer. The U50 Tundra's Maw interaction is conditional; this set is not a general Major/Minor debuff extender. | Serpent's Disdain |
| Sluthrug's Hunger | debuff | Heal allies to grant Blood Hungry and deal direct damage to apply Bloodied. The 4% damage relationship requires both effects. | Sluthrug's Hunger |
| The Morag Tong | debuff | Direct damage makes the enemy take 10% more Poison and Disease Damage for 5 seconds. | The Morag Tong |
| The Saint and the Seducer | debuff | Cycles through a personal Major buff and its associated enemy Minor debuff. Random rotation cannot guarantee a specific required debuff. | The Saint and the Seducer |
| Traumatic Burns | debuff | The enemy takes 5% more Flame Damage after direct damage from an Ardent Flame ability. | Traumatic Burns |
| Turning Tide | debuff | Block, then Bash with Flowing Water to apply Major Vulnerability in a cone. | Turning Tide |
| Veil's Forfeit | debuff | This Necromancer mastery extends Major Vulnerability applied by its owner by 50%. It does not create Vulnerability by itself. | Veil's Forfeit |
| Warrior's Opportunity | debuff | Traveling Knife with this Signature increases the enemy's Martial Damage taken by 8% for 5 seconds. | Inspect source conditions; not automatically inferred |
| Z'en's Redress | debuff | Touch of Z'en amplifies damage taken by up to 5%, requiring five qualifying damage-over-time effects belonging to its wearer. | Z'en's Redress |
| Abyssal Brace | defense | While blocking, grants Minor Evasion to group members within twelve meters. | Abyssal Brace |
| Automated Defense | defense | An Ultimate grants Major Aegis to the wearer and five nearby allies. | Automated Defense |
| Brands of Imperium | defense | Taking damage can create a group shield in a small nearby area. | Brands of Imperium |
| Cleansing Revival | defense | This slotted Champion star removes eligible negative effects when healing an ally below 25% Health. | Cleansing Revival |
| Earthgore | defense | Healing an ally below 50% Health creates emergency healing and removes eligible ground effects. It cannot cleanse arbitrary boss mechanics. | Earthgore |
| Ebon Armory | defense | Adds 1000 Max Health to the wearer and nearby group members. Useful only when that Health threshold is needed. | Ebon Armory |
| Foolkiller's Ward | defense | Blocking grants a short direct-damage shield to the wearer and three group members; breaking it restores resources. | Foolkiller's Ward |
| From the Brink | defense | This slotted Champion star shields an ally healed below 25% Health; each target has a cooldown. | From the Brink |
| Gossamer | defense | Healing an ally supplies short-duration Major Evasion. | Gossamer |
| Grave Guardian | defense | Blocking provides an Armor aura to nearby allies. Additional Armor can exceed the recipient's mitigation cap. | Grave Guardian |
| Group Cleanse | defense | A skill or Champion star can remove eligible negative effects from allies. Boss mechanics may be unpurgeable. | Purge; Cleansing Ritual; Cleansing Revival |
| Group Damage Shield | defense | An equipped skill, set or Champion star can protect allies with a damage shield. Recipient limits and shield conditions differ. | The Blind; Mender's Ward; Brands of Imperium; Foolkiller's Ward; Magma Shell; Obsidian Shield; From the Brink |
| Healing Mage | defense | Area healing applies Minor Cowardice to nearby enemies. This is not the old unique Mending debuff. | Healing Mage |
| Hiti's Hearth | defense | Healing abilities create a healing aura that reduces the recipients' Sprint, Block and Roll Dodge costs. | Hiti's Hearth |
| Inventor's Guard | defense | An Ultimate grants Major Aegis to the wearer and five nearby allies. | Inventor's Guard |
| Lady Thorn | defense | A Health-cost skill creates a synergy; activating it applies Major Maim to nearby enemies. | Lady Thorn |
| Lord Warden | defense | Taking damage can create a nearby group Armor area. Allies must remain in its area. | Lord Warden |
| Major Aegis | defense | Major Aegis grants 10% damage reduction against PvE instance monsters. | Vrol's Command; Inventor's Guard; Automated Defense |
| Major Cowardice | defense | Reduces the enemy's Weapon and Spell Damage by 430. Its practical value depends on the enemy's attacks. | Deafening Roar |
| Major Evasion | defense | Major Evasion grants 20% area damage taken reduction. | Gossamer |
| Major Maim | defense | Reduces the enemy's damage done by 10%. A defense option for dangerous phases, not a damage amplifier. | Lady Thorn; Void Bash; Deafening Roar |
| Major Mending | defense | Major Mending grants 16% healing done by the recipient. | Inspect source conditions; not automatically inferred |
| Major Protection | defense | Major Protection grants 10% damage taken reduction. | Lead From the Front |
| Major Resolve | defense | Major Resolve grants 5948 Armor. | Frost Cloak |
| Major Vitality | defense | Major Vitality grants 12% healing received and shield strength. | Mender's Ward; Erudite's Rigor |
| Mender's Ward | defense | Steadfast Ward grants Major Vitality to the shielded target. | Mender's Ward |
| Meritorious Service | defense | Using a Support ability in combat grants Armor to the wearer and five nearby group members. | Meritorious Service |
| Minor Aegis | defense | Minor Aegis grants 5% damage reduction against PvE instance monsters. | Inspect source conditions; not automatically inferred |
| Minor Cowardice | defense | Reduces the enemy's Weapon and Spell Damage by 215. Its practical value depends on the enemy's attacks. | Healing Mage; Erudite's Rigor |
| Minor Evasion | defense | Minor Evasion grants 10% area damage taken reduction. | Abyssal Brace |
| Minor Maim | defense | Reduces the enemy's damage done by 5%. Chilled, Heroic Slash and several class abilities provide it. | Thurvokun; Heroic Slash; Runic Sunder |
| Minor Mending | defense | Minor Mending grants 8% healing done by the recipient. | Inspect source conditions; not automatically inferred |
| Minor Protection | defense | Minor Protection grants 5% damage taken reduction. | Ring of Preservation; Banner Bearer Affix |
| Minor Resolve | defense | Minor Resolve grants 2974 Armor. | Magma Incarnate; Combat Prayer; Banner Bearer Affix |
| Minor Toughness | defense | Minor Toughness grants 10% Max Health. | Maturation |
| Minor Vitality | defense | Minor Vitality grants 6% healing received and shield strength. | Ozezan the Inferno; Hollowfang Thirst |
| Ozezan the Inferno | defense | Healing grants Minor Vitality; overhealing grants an additional Armor bonus. Both are short effects tied to actual healed recipients. | Ozezan the Inferno |
| Reawakened Hierophant | defense | Non-Ultimate Curative Runeforms supplies a shield, Minor Heroism or Major Protection according to Crux. These are alternative results. | Reawakened Hierophant |
| Salve of Renewal | defense | This slotted Champion star heals around an ally after removing a negative effect. | Salve of Renewal |
| Sanctuary | defense | Nearby group members receive 10% stronger incoming healing. The aura has a short range. | Sanctuary |
| Syrabane's Ward | defense | Blocking creates an allied defensive zone and immobilizes the wearer. The Recovery benefit does not apply to the wearer. | Syrabane's Ward |
| Thurvokun | defense | Taking damage creates a bile area that applies Minor Maim and Diseased to enemies. | Thurvokun |
| Void Bash | defense | Power Bash pulls eligible enemies and applies Major Maim. Pull immunity still applies. | Void Bash |
| Vrol's Command | defense | A fully charged Heavy Attack grants Major Aegis to the wearer and eleven nearby allies. | Vrol's Command |
| Weakening Enchantment | defense | A weapon enchantment lowers the enemy's Weapon and Spell Damage. Its strength depends on the weapon and enchantment. | Inspect source conditions; not automatically inferred |
| Aegis of Galenwe | offense | Blocking grants Empower to nearby allies. Most useful for Heavy Attack builds without a personal source. | Aegis of Galenwe |
| Banner Bearer - Area Damage | offense | The equipped Focus grants 6% Area Damage done to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer. | Banner Bearer |
| Banner Bearer - Cost Reduction | offense | The equipped Focus grants 8% non-Ultimate ability cost reduction to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer. | Banner Bearer |
| Banner Bearer - Damage Reduction | offense | The equipped Focus grants 6% damage taken reduction to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer. | Banner Bearer |
| Banner Bearer - Damage over Time | offense | The equipped Focus grants 6% Damage over Time done to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer. | Banner Bearer |
| Banner Bearer - Direct Damage | offense | The equipped Focus grants 6% Direct Damage done to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer. | Banner Bearer |
| Banner Bearer - Magical Damage | offense | The equipped Focus grants 6% Magical Damage done to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer. | Banner Bearer |
| Banner Bearer - Martial Damage | offense | The equipped Focus grants 6% Martial Damage done to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer. | Banner Bearer |
| Bright Harbinger | offense | The selected Templar mastery upgrades Illuminate: 300 Weapon and Spell Damage for allies. The Templar's own larger bonus is personal. | Bright Harbinger |
| Calculated Defense | offense | The selected Sorcerer mastery grants 6% Weapon and Spell Damage to nearby group members if its initial shield survives for 0.5 seconds. | Calculated Defense |
| Claw of Yolnahkriin | offense | Claw of Yolnahkriin supplies Minor Courage after a taunt. It is an alternative source of Minor Courage, not an additional unique damage bonus. | Claw of Yolnahkriin |
| Crusader | offense | An eligible movement or pull attack creates an area supplying Minor Courage. | Crusader |
| Dragonknight Standard | offense | The standard's area improves group Weapon and Spell Damage and reduces damage taken. Standard of Might's extra caster bonuses are personal. | Dragonknight Standard |
| Empower | offense | Improves Heavy Attack damage against monsters. Enable for Heavy Attack builds; it is not an increase to every damage source. | Aegis of Galenwe |
| Feeding Frenzy | offense | The Werewolf synergy gives its user 6% damage done and Minor Force. Each beneficiary must activate the synergy. | Roar |
| Magma Incarnate | offense | A single-target heal starts a bounce granting Minor Courage and Minor Resolve. It is not guaranteed to reach twelve players. | Magma Incarnate |
| Major Berserk | offense | Increases damage done by 10%. Storm Atronach requires its synergy; Lead from the Front requires the selected mastery and its prerequisite. | Storm Atronach; Lead From the Front |
| Major Brutality / Sorcery | offense | Major Brutality adds 20% Weapon Damage; Major Sorcery adds 20% Spell Damage. Igneous Weapons can supply both to allies. Personal potions only supply their user. | Igneous Weapons; Molten Armaments |
| Major Courage | offense | Adds 430 Weapon and Spell Damage. Spell Power Cure, Vestment of Olorime and Ferocious Roar are alternative providers of the same named buff. | Spell Power Cure; Vestment of Olorime; Ferocious Roar |
| Major Savagery / Prophecy | offense | Personal readiness check: Major Savagery / Prophecy add 2629 Weapon / Spell Critical rating. Lotus and personal potions are not automatically distributed to the group. | Inspect source conditions; not automatically inferred |
| Major Slayer | offense | Adds 10% damage done in dungeons, trials and arenas. Roaring Opportunist, Master Architect and War Machine supply the same buff, with limited recipients per application. | Roaring Opportunist; Master Architect; War Machine |
| Minor Berserk | offense | Increases damage done by 5%. Combat Prayer and the matching Banner Bearer Affix provide it to allies; personal skills do not prove group coverage. | Combat Prayer; Banner Bearer Affix |
| Minor Brutality | offense | +10% Weapon Damage for affected group members. | Elder Dragon |
| Minor Brutality / Sorcery | offense | Legacy combined view. In U50, Minor Brutality and Minor Sorcery are different effects with different class providers. Use the separate entries in Trial and Dungeon. | Inspect source conditions; not automatically inferred |
| Minor Courage | offense | Adds 215 Weapon and Spell Damage. Arcanist's Domain, Claw of Yolnahkriin and other sources replace one another for the same recipient. | Claw of Yolnahkriin; Magma Incarnate; Phoenix Moth Theurge; Crusader; Arcanist's Domain; Zenas' Empowering Disc; Reconstructive Domain; Banner Bearer Affix |
| Minor Savagery / Prophecy | offense | Legacy combined view. In U50, Minor Savagery and Minor Prophecy remain distinct. Use their separate entries to evaluate the actual composition. | Inspect source conditions; not automatically inferred |
| Minor Slayer | offense | Adds 5% damage done in PvE instances to the wearer. Another player's three-piece bonus does not cover your damage dealers. | Inspect source conditions; not automatically inferred |
| Minor Sorcery | offense | +10% Spell Damage for affected group members. | Illuminate |
| Pearlescent Ward | offense | Up to 180 Weapon and Spell Damage for the group, based on living members. Its defensive benefit grows as group members die. | Pearlescent Ward |
| Phoenix Moth Theurge | offense | Healing grants Minor Courage and Minor Force to the recipient, with a per-target cooldown. | Phoenix Moth Theurge |
| Powerful Assault | offense | An Assault ability used in combat provides 307 Weapon and Spell Damage to the wearer and up to five allies within 12 meters per application. | Powerful Assault |
| Spaulder of Ruin | offense | Aura of Pride grants 260 Weapon and Spell Damage to up to six allies within 12 meters. The wearer pays a resource Recovery penalty and must toggle the aura on. | Spaulder of Ruin |
| Vitalizing Glyphic | offense | The glyphic provides healing and up to 200 Weapon and Spell Damage, depending on its Health. | Vitalizing Glyphic; Glyphic of the Tides; Resonating Glyphic |
| War Horn - Max Resources | offense | +10% Max Magicka and Max Stamina. This benefit is separate from Major Force. | War Horn; Sturdy Horn; Aggressive Horn |
| Anthelmir's Construct | penetration | A fully charged Heavy Attack triggers an axe and scaling Armor reduction. Retrieving the axe changes the cooldown. | Anthelmir's Construct |
| Crimson Oath's Rive | penetration | Applying an eligible Major or Minor buff in combat triggers 3541 Armor reduction on nearby enemies. Check remaining penetration needs before adding another source. | Crimson Oath's Rive |
| Crusher Enchantment | penetration | Reduces enemy Armor through an unsuppressed, charged weapon enchantment. Weapon size, Infused and Torug's Pact change the reduction; the baseline value is not every tank's final contribution. | Inspect source conditions; not automatically inferred |
| Crystal Weapon - Armor Reduction | penetration | The triggered attack reduces the target's Armor by 1000 for 5 seconds. | Crystal Weapon |
| Dolorous Arena | penetration | Block near the enemy to build up to three Armor reduction stacks, 1843 each. Full strength is conditional. | Dolorous Arena |
| Major Breach | penetration | Reduces enemy Physical and Spell Resistance by 5948. Avoid buying a second source solely to stack the same named debuff. | Elemental Drain; Weakness to Elements; Elemental Susceptibility; Razor Caltrops; Pierce Armor; Ransack; Puncture; Unnerving Boneyard; Mark Target; Deep Fissure |
| Minor Breach | penetration | Reduces enemy Physical and Spell Resistance by 2974. Pierce Armor, Deep Fissure and Sundered are common sources. | Pierce Armor; Deep Fissure; Sundered |
| Roar of Alkosh | penetration | A synergy activation triggers Armor reduction, scaling with the wearer's Weapon Damage up to 6000. Equipping five pieces does not prove the maximum value. | Roar of Alkosh |
| Runic Sunder | penetration | Steals 2200 Armor from the enemy. The resistance reduction benefits attacks against that enemy; the Armor gained belongs to the Arcanist. | Runic Sunder |
| Tremorscale | penetration | Taunting triggers an Armor reduction that scales with the wearer's higher resistance. No fixed value is assumed from set presence alone. | Tremorscale |
| Apocryphal Inspiration | sustain | Provides Major Intellect, Endurance and Fortitude in an aura. Many players already obtain these buffs from personal potions. | Apocryphal Inspiration |
| Arkasis's Genius | sustain | Drink a potion in combat to grant Ultimate to the wearer and up to three group members; subject to its cooldown. | Arkasis's Genius |
| Cryptcanon Vestments | sustain | Replaces the wearer's Ultimate cast with Ultimate sharing among other living group members. Its Minor Heroism is personal. | Cryptcanon Vestments |
| Drake's Rush | sustain | Bash to grant Major Heroism to the wearer and up to three nearby group members. Useful for four-player groups. | Drake's Rush |
| Enlivening Overflow | sustain | This slotted Champion star grants resource Recovery after overhealing an ally; the amount scales with the healer's Max Magicka. | Enlivening Overflow |
| Force Overflow | sustain | Force Siphon at short range creates a link restoring resources to allies inside the link. | Force Overflow |
| Gardener of Seasons | sustain | Green Balance abilities trigger seasonal effects. Spring supplies Minor Heroism on overheal; Fall supplies different defensive effects. | Gardener of Seasons |
| Grand Rejuvenation | sustain | The initial Grand Healing heal supplies repeated Magicka and Stamina returns to its recipients. The restoration staff must complete its two-piece bonus on a usable bar. | Grand Rejuvenation |
| Hircine's Veneer | sustain | Grants 145 Stamina Recovery to the wearer and up to eleven nearby group members. | Hircine's Veneer |
| Hollowfang Thirst | sustain | A critical heal or hit creates a delayed blood ball; nearby allies gain Magicka and Minor Vitality. | Hollowfang Thirst |
| Jorvuld's Guidance | sustain | Extends Major and Minor buffs and damage shields applied by the wearer in combat. It does not extend all unique effects or enemy debuffs. | Jorvuld's Guidance |
| Kyne's Wind | sustain | Overhealing creates a short-lived area restoring Magicka and Stamina. Allies must stand in the area. | Kyne's Wind |
| Major Endurance | sustain | Major Endurance grants 30% Stamina Recovery. | Apocryphal Inspiration |
| Major Fortitude | sustain | Major Fortitude grants 30% Health Recovery. | Apocryphal Inspiration |
| Major Heroism | sustain | Major Heroism grants 3 Ultimate every 1.5 seconds. | Drake's Rush; Bountiful Harvest |
| Major Intellect | sustain | Major Intellect grants 30% Magicka Recovery. | Apocryphal Inspiration |
| Minor Endurance | sustain | Minor Endurance grants 15% Stamina Recovery. | Enchanted Growth; Regenerative Ward; Refreshing Path; Radiant Aura; Arcanist's Domain; Zenas' Empowering Disc; Reconstructive Domain; Banner Bearer Affix |
| Minor Fortitude | sustain | Minor Fortitude grants 15% Health Recovery. | Radiant Aura; Arcanist's Domain; Zenas' Empowering Disc; Reconstructive Domain; Hearthfire; Fire Keeper; Hearth and Home |
| Minor Heroism | sustain | Minor Heroism grants 1 Ultimate every 1.5 seconds. | Hearthfire; Fire Keeper; Hearth and Home; Hope Infusion; Banner Bearer Affix |
| Minor Intellect | sustain | Minor Intellect grants 15% Magicka Recovery. | Enchanted Growth; Regenerative Ward; Refreshing Path; Radiant Aura; Arcanist's Domain; Zenas' Empowering Disc; Reconstructive Domain; Banner Bearer Affix |
| Minor Lifesteal | sustain | Attackers heal for 600 Health, at most once per second. It does not replace healing for a lethal mechanic. | Blood Altar |
| Minor Magickasteal | sustain | Attackers restore 168 Magicka, at most once per second. This is direct resource return, distinct from Recovery. | Elemental Drain; Overcharged |
| Pillager's Profit | sustain | Spending Ultimate distributes Ultimate to other nearby group members. It does not restore the wearer's own Ultimate and has a recipient cooldown. | Pillager's Profit |
| Recovery Convergence | sustain | Reach the overheal threshold in combat and activate Convergence Release to restore Magicka and Stamina to nearby group members. | Recovery Convergence |
| Resource Synergy | sustain | Energy Orb or a Spear Shards morph provides an activatable resource return. A synergy must be activated by its intended recipient. | Luminous Shards; Blazing Spear; Energy Orb |
| Sentinel of Rkugamz | sustain | Healing summons an area restoring Health, Magicka and Stamina. The effective area is small. | Sentinel of Rkugamz |
| Share the Spoils | sustain | The selected Nightblade mastery upgrades Transfer: 250 Magicka, 250 Stamina and 2 Ultimate for the group per eligible trigger. | Share the Spoils |
| Sphere of Influence | sustain | The selected Sorcerer mastery adds a shield and resource Recovery to the allies actually affected by its shield trigger. | Sphere of Influence |
| Stone-Talker's Oath | sustain | A fully charged Heavy Attack places a mark; its explosion restores resources based on stored damage to allies in range. | Stone-Talker's Oath |
| Symphony of Blades | sustain | Healing another group member below 50% of their dominant resource restores that resource over time, subject to a per-recipient cooldown. | Symphony of Blades |
| The Worm's Raiment | sustain | Grants 145 Magicka Recovery to the wearer and up to eleven nearby group members. | The Worm's Raiment |
| Xoryn's Masterpiece | sustain | An aura increases group Max Magicka and Max Stamina by 1667. It is a maximum-resource bonus, not direct resource recovery. | Xoryn's Masterpiece |

The original 76 v1 and 81 v2 capability positions remain frozen. Further entries require compatible full-build sharing. See [catalog evidence](CATALOG_EVIDENCE.md) for the reviewed source revisions and exact identity corrections.

Compatible-library evidence preserves its producer’s meaning: LibGroupCombatStats slots and class lines are last-reported values in its current-character group cache, with their original timestamps. Unchanged values do not expire merely because no heartbeat is sent; removed or invalid library data is cleared. LibSetDetection requires a received update in the current group session, and detailed build snapshots retain their separate expiry.
