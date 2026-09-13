# Support Coverage catalog — U50 pre-combat checks

Reviewed against Live PC data and the project research on 13 September 2026. This is the feature-branch catalog, not a public release certification.

## Two independent lists

**Trial** starts with Courage, Slayer, Berserk, Force, the four separate U50 class minor buffs, Vulnerability, Breach, Minor Brittle, Crusher, Powerful Assault and resource synergies. **Dungeon** starts with a smaller common core. Optional rows include alternative armor sets, monster sets, support mythics, class masteries, sustain, defense, Champion support stars and specialized damage amplifiers. Enable only the requirements useful for the actual composition; equipping every option at once is neither required nor sensible.

Each list has its own On/Off overrides. Existing custom requirements and old disabled choices remain respected; an explicit switch in the current list takes precedence. Legacy profiles and the original network key positions remain readable for compatibility.

## Evidence and duplicate rules

- Five-piece bonuses qualify when complete on **either** Front or Back bar. A bonus is not required to be complete on both bars. One-piece mythics and two-piece monster/arena effects use their own thresholds.
- Normal and Perfected pieces are combined by native set family. Their common support effect is counted once.
- Equipped capability is a pre-combat source check. It does not assert current targets, active procs, maximum stacks, full strength or live coverage of twelve people.
- Two providers of the same named Major/Minor effect do not produce twice the bonus on one recipient. Limited range, split groups, target caps and Ultimate rotations can justify deliberate duplicates.
- U50 Minor Brutality, Minor Sorcery, Minor Savagery and Minor Prophecy are separate rows. Personal potions, Lotus, Minor Slayer and personal mythics do not establish a group source.
- Class passives require their learned passive and the appropriate trigger skill line when relevant. Masteries require actual committed selection, eligibility and prerequisite ranks; some also require the triggering ability to be slotted.
- A source absent from this finite catalog stays unverified. It is not proof that a player can never provide the effect through another build.

## Known conservative limits

Native set IDs and verified skill/passive/mastery IDs are used for language-independent matching. Some recently reworked or unverified ability identities retain an **English-name fallback**, so a non-English client can show an unverified source until that identity is confirmed. This specifically includes the new Dragonknight passive identities, selected unusual skill morphs and the support Champion star identity map. Their native names and full build information remain available to inspect.

Scribing displays the actual slotted grimoire and scripts. The catalog includes useful Scribing options for planning, but does not infer ally coverage merely from a grimoire or Affix name. Focus-dependent recipient rules require a verified combination; an unrecognized combination stays unverified. A personal Major Heroism from Trample, for example, is not credited to the group.

Crusher excludes an exhausted enchantment or one suppressed by paired poison when that state is known. Its exact reduction, Tremorscale, Alkosh, Dolorous Arena and other scaling effects are not inferred to be at maximum strength from their set names alone.

## Catalog

Names below are English. Set-specific options help request a specific source; ordinary effect rows combine alternative suppliers. Not every row is enabled by default.

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
| Major Force | critical | Adds 20 percentage points of Critical Damage, subject to each player's critical damage cap. | Saxhleel Champion; aggressive horn; Ink-Scribe's Verve |
| Minor Brittle | critical | The target takes 10 additional percentage points of Critical Damage. Chilled requires an Ice Staff on the active bar; Colorless Pool and compatible Scribing provide alternatives. | Glittering Goad; Rune of the Colorless Pool; Chilled with an active Ice Staff |
| Minor Force | critical | Adds 10 percentage points of Critical Damage. Many damage dealers already provide this to themselves; check the intended recipients before assigning a support source. | Phoenix Moth Theurge; The Blind; Twilight Remedy; Feeding Frenzy |
| Minor Prophecy | critical | +1314 Spell Critical rating for affected group members. | Exploitation |
| Minor Savagery | critical | +1314 Weapon Critical rating for affected group members. | Hemorrhage |
| Nunatak | critical | Frost damage creates an area; four hits on the same target trigger Major Brittle. | Nunatak |
| The Blind | critical | A critical heal grants a shield and Minor Force while it holds, then briefly after it ends. | The Blind |
| Twilight Remedy | critical | An ally must activate a synergy created by the wearer to receive healing and Minor Force. | Twilight Remedy |
| Cutthroat's Focus | debuff | Cutthroat's Focus applies 5% increased damage taken to an attacker after its special dodge succeeds. Against monsters the debuff lasts 20 seconds. | Cutthroat's Focus |
| Encratis's Behemoth | debuff | Encratis's Behemoth improves Flame Damage taken by enemies and reduces Flame Damage taken by allies in its aura. Its value depends on actual Flame Damage in the encounter. | Encratis's Behemoth |
| Heat Shock | debuff | Magma Fist applies Heat Shock, adding 66 damage taken per stack, up to three stacks. This is flat damage per hit, not a percentage damage multiplier. | magma fist |
| Infallible Mage | debuff | A fully charged Heavy Attack applies Minor Vulnerability. The three-piece Minor Slayer is personal. | Infallible Mage |
| Major Vulnerability | debuff | The target takes 10% more damage. Colossus, Turning Tide and Archdruid Devyric are alternative providers of the same debuff. | Archdruid Devyric; Turning Tide; Frozen Colossus |
| Martial Knowledge | debuff | A Light Attack below 50% Stamina applies 8% increased damage taken for 5 seconds, with an 8 second cooldown. | Way of Martial Knowledge |
| Minor Vulnerability | debuff | The target takes 5% more damage. Concussion, Fetcher Infection, Boneyard and Colorless Pool are examples of alternative sources. | Infallible Mage; swarm; Boneyard; Lotus Fan; Rune of the Colorless Pool; Concussion |
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
| Major Cowardice | defense | Reduces the enemy's Weapon and Spell Damage by 430. Its practical value depends on the enemy's attacks. | Inspect source conditions; not automatically inferred |
| Major Evasion | defense | Major Evasion grants 20% area damage taken reduction. | Gossamer |
| Major Maim | defense | Reduces the enemy's damage done by 10%. A defense option for dangerous phases, not a damage amplifier. | Lady Thorn; Void Bash |
| Major Mending | defense | Major Mending grants 16% healing done by the recipient. | Inspect source conditions; not automatically inferred |
| Major Protection | defense | Major Protection grants 10% damage taken reduction. | Lead From the Front |
| Major Resolve | defense | Major Resolve grants 5948 Armor. | frost cloak |
| Major Vitality | defense | Major Vitality grants 12% healing received and shield strength. | Mender's Ward; Erudite's Rigor |
| Mender's Ward | defense | Steadfast Ward grants Major Vitality to the shielded target. | Mender's Ward |
| Meritorious Service | defense | Using a Support ability in combat grants Armor to the wearer and five nearby group members. | Meritorious Service |
| Minor Aegis | defense | Minor Aegis grants 5% damage reduction against PvE instance monsters. | Inspect source conditions; not automatically inferred |
| Minor Cowardice | defense | Reduces the enemy's Weapon and Spell Damage by 215. Its practical value depends on the enemy's attacks. | Healing Mage; Erudite's Rigor |
| Minor Evasion | defense | Minor Evasion grants 10% area damage taken reduction. | Abyssal Brace |
| Minor Maim | defense | Reduces the enemy's damage done by 5%. Chilled, Heroic Slash and several class abilities provide it. | Thurvokun; Heroic Slash; Runic Sunder |
| Minor Mending | defense | Minor Mending grants 8% healing done by the recipient. | Inspect source conditions; not automatically inferred |
| Minor Protection | defense | Minor Protection grants 5% damage taken reduction. | ring of preservation |
| Minor Resolve | defense | Minor Resolve grants 2974 Armor. | Magma Incarnate; combat prayer |
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
| Banner Bearer - Area Damage | offense | The equipped Focus grants 6% Area Damage done to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer. | Inspect source conditions; not automatically inferred |
| Banner Bearer - Cost Reduction | offense | The equipped Focus grants 8% non-Ultimate ability cost reduction to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer. | Inspect source conditions; not automatically inferred |
| Banner Bearer - Damage Reduction | offense | The equipped Focus grants 6% damage taken reduction to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer. | Inspect source conditions; not automatically inferred |
| Banner Bearer - Damage over Time | offense | The equipped Focus grants 6% Damage over Time done to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer. | Inspect source conditions; not automatically inferred |
| Banner Bearer - Direct Damage | offense | The equipped Focus grants 6% Direct Damage done to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer. | Inspect source conditions; not automatically inferred |
| Banner Bearer - Magical Damage | offense | The equipped Focus grants 6% Magical Damage done to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer. | Inspect source conditions; not automatically inferred |
| Banner Bearer - Martial Damage | offense | The equipped Focus grants 6% Martial Damage done to allies in the banner's 8 meter aura. Different Focus effects are distinct; the same effect does not become additive by adding another wearer. | Inspect source conditions; not automatically inferred |
| Bright Harbinger | offense | The selected Templar mastery upgrades Illuminate: 300 Weapon and Spell Damage for allies. The Templar's own larger bonus is personal. | Bright Harbinger |
| Calculated Defense | offense | The selected Sorcerer mastery grants 6% Weapon and Spell Damage to nearby group members if its initial shield survives for 0.5 seconds. | Calculated Defense |
| Claw of Yolnahkriin | offense | Claw of Yolnahkriin supplies Minor Courage after a taunt. It is an alternative source of Minor Courage, not an additional unique damage bonus. | Claw of Yolnahkriin |
| Crusader | offense | An eligible movement or pull attack creates an area supplying Minor Courage. | Crusader |
| Dragonknight Standard | offense | The standard's area improves group Weapon and Spell Damage and reduces damage taken. Standard of Might's extra caster bonuses are personal. | Dragonknight Standard |
| Empower | offense | Improves Heavy Attack damage against monsters. Enable for Heavy Attack builds; it is not an increase to every damage source. | Aegis of Galenwe |
| Feeding Frenzy | offense | The Werewolf synergy gives its user 6% damage done and Minor Force. Each beneficiary must activate the synergy. | Feeding Frenzy |
| Magma Incarnate | offense | A single-target heal starts a bounce granting Minor Courage and Minor Resolve. It is not guaranteed to reach twelve players. | Magma Incarnate |
| Major Berserk | offense | Increases damage done by 10%. Storm Atronach requires its synergy; Lead from the Front requires the selected mastery and its prerequisite. | Storm Atronach; Lead From the Front |
| Major Brutality / Sorcery | offense | Major Brutality adds 20% Weapon Damage; Major Sorcery adds 20% Spell Damage. Igneous Weapons can supply both to allies. Personal potions only supply their user. | igneous weapons; molten armaments |
| Major Courage | offense | Adds 430 Weapon and Spell Damage. Spell Power Cure, Vestment of Olorime and Ferocious Roar are alternative providers of the same named buff. | Spell Power Cure; Vestment of Olorime; ferocious roar |
| Major Savagery / Prophecy | offense | Personal readiness check: Major Savagery / Prophecy add 2629 Weapon / Spell Critical rating. Lotus and personal potions are not automatically distributed to the group. | Inspect source conditions; not automatically inferred |
| Major Slayer | offense | Adds 10% damage done in dungeons, trials and arenas. Roaring Opportunist, Master Architect and War Machine supply the same buff, with limited recipients per application. | Roaring Opportunist; Master Architect; War Machine |
| Minor Berserk | offense | Increases damage done by 5%. Combat Prayer and the matching Banner Bearer Affix provide it to allies; personal skills do not prove group coverage. | combat prayer |
| Minor Brutality | offense | +10% Weapon Damage for affected group members. | Elder Dragon |
| Minor Brutality / Sorcery | offense | Legacy combined view. In U50, Minor Brutality and Minor Sorcery are different effects with different class providers. Use the separate entries in Trial and Dungeon. | Inspect source conditions; not automatically inferred |
| Minor Courage | offense | Adds 215 Weapon and Spell Damage. Arcanist's Domain, Claw of Yolnahkriin and other sources replace one another for the same recipient. | Claw of Yolnahkriin; Magma Incarnate; Phoenix Moth Theurge; Crusader; Arcanist's Domain; Zenas' Empowering Disc; Reconstructive Domain |
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
| Major Breach | penetration | Reduces enemy Physical and Spell Resistance by 5948. Avoid buying a second source solely to stack the same named debuff. | elemental drain; weakness to elements; elemental susceptibility; razor caltrops; Pierce Armor; Ransack; Puncture; Unnerving Boneyard; Mark Target |
| Minor Breach | penetration | Reduces enemy Physical and Spell Resistance by 2974. Pierce Armor, Deep Fissure and Sundered are common sources. | Pierce Armor; Sundered |
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
| Minor Endurance | sustain | Minor Endurance grants 15% Stamina Recovery. | Enchanted Growth; Regenerative Ward; Refreshing Path; Radiant Aura; Arcanist's Domain; Zenas' Empowering Disc; Reconstructive Domain |
| Minor Fortitude | sustain | Minor Fortitude grants 15% Health Recovery. | Radiant Aura; Arcanist's Domain; Zenas' Empowering Disc; Reconstructive Domain; Hearthfire; Fire Keeper; Hearth and Home |
| Minor Heroism | sustain | Minor Heroism grants 1 Ultimate every 1.5 seconds. | Hearthfire; Fire Keeper; Hearth and Home; Hope Infusion |
| Minor Intellect | sustain | Minor Intellect grants 15% Magicka Recovery. | Enchanted Growth; Regenerative Ward; Refreshing Path; Radiant Aura; Arcanist's Domain; Zenas' Empowering Disc; Reconstructive Domain |
| Minor Lifesteal | sustain | Attackers heal for 600 Health, at most once per second. It does not replace healing for a lethal mechanic. | blood altar |
| Minor Magickasteal | sustain | Attackers restore 168 Magicka, at most once per second. This is direct resource return, distinct from Recovery. | elemental drain; Overcharged |
| Pillager's Profit | sustain | Spending Ultimate distributes Ultimate to other nearby group members. It does not restore the wearer's own Ultimate and has a recipient cooldown. | Pillager's Profit |
| Recovery Convergence | sustain | Reach the overheal threshold in combat and activate Convergence Release to restore Magicka and Stamina to nearby group members. | Recovery Convergence |
| Resource Synergy | sustain | Healing Orb or Luminous Shards provides an activatable resource return. A synergy must be activated by its intended recipient. | Luminous Shards; Energy Orb |
| Sentinel of Rkugamz | sustain | Healing summons an area restoring Health, Magicka and Stamina. The effective area is small. | Sentinel of Rkugamz |
| Share the Spoils | sustain | The selected Nightblade mastery upgrades Transfer: 250 Magicka, 250 Stamina and 2 Ultimate for the group per eligible trigger. | Share the Spoils |
| Sphere of Influence | sustain | The selected Sorcerer mastery adds a shield and resource Recovery to the allies actually affected by its shield trigger. | Sphere of Influence |
| Stone-Talker's Oath | sustain | A fully charged Heavy Attack places a mark; its explosion restores resources based on stored damage to allies in range. | Stone-Talker's Oath |
| Symphony of Blades | sustain | Healing another group member below 50% of their dominant resource restores that resource over time, subject to a per-recipient cooldown. | Symphony of Blades |
| The Worm's Raiment | sustain | Grants 145 Magicka Recovery to the wearer and up to eleven nearby group members. | The Worm's Raiment |
| Xoryn's Masterpiece | sustain | An aura increases group Max Magicka and Max Stamina by 1667. It is a maximum-resource bonus, not direct resource recovery. | Xoryn's Masterpiece |

## References

- [Official U50 Live patch notes](https://forums.elderscrollsonline.com/en/discussion/693682/update-50-live-patch-notes-all-platforms): live class mastery rules and current class changes.
- [LibSets source](https://github.com/Baertram/LibSets): native set family IDs and English set names; runtime matching does not require LibSets.
- [ESO-Hub buffs and debuffs](https://eso-hub.com/en/buffs-debuffs): effect terminology and supplier tooltips.
- [ESO-Hub sets](https://eso-hub.com/en/sets): individual set proc conditions, recipient limitations and descriptions.
- [U50 healer set analysis](https://hyperioxes.com/eso/healer/sets) and [tank set analysis](https://hyperioxes.com/eso/tank/sets): practical limitations and dynamic scaling, including Tremorscale.

The catalog deliberately preserves the original 76 v1 and 81 v2 capability positions. Additional effects require compatible full-build sharing; old compact clients cannot represent new entries.
