# Catalog evidence and compatibility

Review date: **15 September 2026**. Scope: the complete inventory of 159 selectable effects, 76 distinct set families, 56 skill-source rows, six passive-source rows, eleven mastery-source rows and five support Champion mappings. An inventory check verifies references and identity relationships; it does not certify every game's proc, encounter interaction or future patch.

## Sources reviewed

| Source | Revision or date | Used for |
|---|---|---|
| [ESO native API and UI](https://github.com/esoui/esoui/tree/f76cf16c4e5be7b234d15dc7f676febffa64c5bb) | Native UI mirror commit `f76cf16c4e5be7b234d15dc7f676febffa64c5bb`, 10 August 2026 | Function signatures; item collection preview; Scribing definition/recipe APIs; native category and Champion textures |
| [LibSets native name dump](https://github.com/Baertram/LibSets/blob/76f2adab4e495f0b3ddb9884cb10c47f32e9f4b1/LibSets/Data/LibSets_Data_SetNames.lua) | Repository commit `76f2adab4e495f0b3ddb9884cb10c47f32e9f4b1`, 12 July 2026; embedded dump stamped API 101050, 25 May 2026 | All 76 set IDs and exact English names |
| [LibSets public API](https://github.com/Baertram/LibSets/blob/76f2adab4e495f0b3ddb9884cb10c47f32e9f4b1/LibSets/LibSets.lua) | Same revision | Optional `GetSetItemId` and `buildItemLink` for crafted reference items |
| [LuiExtended action-bar identity registry](https://github.com/DakJaniels/LuiExtended/blob/27c16a1ce0ffb64beb66274c5730853d197ef996/LuiData/Effects/BarHighlight/BarHighlightOverride.lua) and [native aura identity dump](https://github.com/DakJaniels/LuiExtended/blob/27c16a1ce0ffb64beb66274c5730853d197ef996/LuiData/Debug/DebugAuras.lua) | Commit `27c16a1ce0ffb64beb66274c5730853d197ef996`, 17 July 2026 | Slot/morph identities, renamed Dragonknight abilities, mastery identities; distinguishes emitted effects from slottable abilities |
| [LuiExtended effect registry](https://github.com/DakJaniels/LuiExtended/blob/27c16a1ce0ffb64beb66274c5730853d197ef996/LuiData/Effects/Override.lua) | Same revision | Native status effect IDs; no LuiExtended artwork is copied into this addon |
| [LibGroupCombatStats producer and cache](https://github.com/m00nyONE/LibGroupCombatStats/blob/c88f69f7d5b970127dd9355377cad22dd1cc9ac5/LibGroupCombatStats.lua) | Commit `c88f69f7d5b970127dd9355377cad22dd1cc9ac5`, 26 July 2026 | Change-driven Ultimate/skill-line reports, zero timestamps before receipt, character-indexed cache and group departure cleanup |
| [Official Update 50 notes](https://forums.elderscrollsonline.com/en/discussion/693682/update-50-live-patch-notes-all-platforms) | Published 8 June 2026, edited 29 June; revisited 15 September | Mastery prerequisites/eligibility and Werewolf Roar/Feeding Frenzy changes |
| [ChampionDumper native export](https://github.com/uberswe/eso-data/blob/3b37ba3960d7c2c6fc591a94a7ea082e4d565f7d/ChampionDumper.lua) | 15 October 2022 export | Historical Champion node identity cross-check; runtime allocation/discipline validation remains authoritative |

The native Scribing definition APIs, called with the reported grimoire and script IDs, establish script positions and legal recipe membership. The native texture identities for Banner and its scripts are independently present in the [maintainer's native texture inventory](https://github.com/DakJaniels/LuiExtended/blob/27c16a1ce0ffb64beb66274c5730853d197ef996/LuiData/PC/IconFrameColorSamples.lua). No guessed numeric Scribing IDs are introduced. The rules are based on the supplied U50 catalog review; unsupported recipes are left unknown rather than generalizing a script's recipient rules to every grimoire.

Community discussions and build guides help identify cases to investigate; they do not override native identity data or establish a proc by themselves. In particular, a discussion of a future patch is not applied to the U50 runtime catalog.

## Confirmed corrections

| Previous mapping or behavior | Corrected evidence |
|---|---|
| Boneyard was mapped to `114860 / 117690 / 117749` | Those are Blastbones-family skills. Boneyard uses `115252`, Unnerving `117805`, Avid `117850`; only Unnerving adds Major Breach. |
| Magma Shell used `17878` | `17878` is Corrosive Armor. Magma Shell is `17874`; Corrosive no longer claims an ally shield. |
| Luminous Shards used `26869` | Luminous is `26858`. `26869` is separately labelled Blazing Spear and retains its actual resource synergy. |
| Lotus Fan used `25484` | Lotus Fan is `25493`. `25484` is separately labelled Ambush; both retain their reported Vulnerability contribution. |
| Lead From the Front used `238232` | That is Inexorable Descent. Lead From the Front is `263247`. Elder Dragon rank-2 ID `44951` is removed from The Storm Voice prerequisite. |
| Several current skill/mastery identities lacked IDs | Added Crystal Weapon `46331`, the Hearthfire family, Deep Fissure `86015`, Veil's Forfeit `263554`, glyphic morphs and Elder Dragon ranks `29460 / 44951`. |
| Scribing derivation was called but absent | Exact legal Banner recipes can provide the appropriate Focus and group Affix; personal scripts and unrelated grimoires cannot. |
| Known Werewolf bar never participated | Its actual abilities participate only while transformation and that bar are verified. Roar/Feeding Frenzy uses `32633 / 39113 / 39114`, not Pounce. |
| External Perfected IDs could miss their sources | Native base-family normalization merges compatible variants while preserving separate weapon-bar counts and library activity flags. |
| Alkosh and Crusher presence added assumed numeric reductions | Variable sources remain tracked, but are excluded from the fixed penetration sum. |
| Group recovery/Aegis auras were marked personal | Confirmed group providers now use group-source semantics; observing personal potions still does not create an ally source. |
| Unchanged LGCS slots and class lines expired after 75 seconds | LGCS sends changes, not a reliable heartbeat. Valid reported slots/lines remain last-reported library evidence while its current-member cache exists; timestamps are never renewed by polling. |
| Missing effect/set icons rendered empty cells | Exact native images, named supplying-skill images, Champion symbols and explicit category fallback cover all entries. Missing lookups retry slowly. |

## Evidence boundaries and open items

- LGCS Ultimate slots and skill lines follow its character-indexed group cache, which removes departed characters. Zero/default, non-finite and future timestamps are rejected; current identity, group membership, online state and alive state are checked before actionable coverage. An unchanged cached slot has no artificial 75-second expiry, and its original library timestamp remains intact. This is last-reported equipment information, not a new confirmation or an observed cast. LibSetDetection separately requires an actual received update in the current group session; full build transfers retain their bounded snapshot lifetime.
- Every set ID/name pair below matches the cited native dump. This does **not** independently remeasure every set's range, target priority, cooldown, scaling or encounter exclusions. Those remain conditional tooltip/catalog information and should be compared with the native client after balance patches.
- Native name and slot IDs outrank received labels. Exact fallback names are retained for the Traumatic Burns passive and The Storm Voice prerequisite because their committed passive identities were not independently confirmed here. Combat bundle IDs are not substituted for learned passive IDs. These paths may remain unverified on non-English clients.
- Banner Focus rules cover Magical, Martial, direct, damage-over-time, area, mitigation and non-Ultimate cost reduction. Group Affix rules cover Minor Berserk, Courage, Heroism, Intellect/Endurance, Protection and Resolve. The personal Immobilize Focus and personal major damage/critical Affixes are not credited to allies.
- Other Scribing grimoire/signature combinations, including Warrior's Opportunity, remain inspectable but do not receive automatic coverage from this adapter. The Class Mastery Scribing script is never treated as selected pure-class mastery.
- Status effect IDs are used for their images. Owning a damage type, an Ice Staff or a class is not proof that Chilled, Off Balance or a related debuff has actually been applied. There is no combat sampler in this readiness module.
- The standard critical-damage budget is a source-planning aid. Personal cap-changing masteries and encounter modifiers still require the individual player's actual build context.
- Source presence and recipient capacity are separate. Known small-target suppliers retain their per-cast limit. Multiple providers are not automatically summed into guaranteed twelve-player coverage.
- Exact set tooltips use verified native item links. A reference item may have different level, quality or trait from the inspected player; it never replaces that player's actual item link.
- Current native IDs and feature detection improve compatibility but cannot guarantee future game versions. Unknown APIs, invalid recipes, unrecognized identities and unavailable images degrade conservatively.

## Verified set identity inventory

| Native base set ID | Exact English name |
|---|---|
| 50 | The Morag Tong |
| 77 | Crusader |
| 110 | Sanctuary |
| 122 | Ebon Armory |
| 123 | Hircine's Veneer |
| 124 | The Worm's Raiment |
| 141 | Healing Mage |
| 147 | Way of Martial Knowledge |
| 164 | Lord Warden |
| 172 | Infallible Mage |
| 180 | Powerful Assault |
| 181 | Meritorious Service |
| 184 | Brands of Imperium |
| 185 | Spell Power Cure |
| 229 | Twilight Remedy |
| 232 | Roar of Alkosh |
| 261 | Gossamer |
| 268 | Sentinel of Rkugamz |
| 276 | Tremorscale |
| 318 | Grand Rejuvenation |
| 330 | Automated Defense |
| 331 | War Machine |
| 332 | Master Architect |
| 333 | Inventor's Guard |
| 341 | Earthgore |
| 346 | Jorvuld's Guidance |
| 349 | Thurvokun |
| 388 | Aegis of Galenwe |
| 391 | Vestment of Olorime |
| 416 | Mender's Ward |
| 436 | Symphony of Blades |
| 446 | Claw of Yolnahkriin |
| 452 | Hollowfang Thirst |
| 455 | Z'en's Redress |
| 471 | Hiti's Hearth |
| 476 | Grave Guardian |
| 492 | Kyne's Wind |
| 494 | Vrol's Command |
| 496 | Roaring Opportunist |
| 516 | Elemental Catalyst |
| 518 | Arkasis's Genius |
| 535 | Lady Thorn |
| 558 | Void Bash |
| 562 | Force Overflow |
| 571 | Drake's Rush |
| 574 | Foolkiller's Ward |
| 577 | Encratis's Behemoth |
| 585 | Saxhleel Champion |
| 588 | Stone-Talker's Oath |
| 602 | Crimson Oath's Rive |
| 609 | Magma Incarnate |
| 622 | Turning Tide |
| 627 | Spaulder of Ruin |
| 633 | Nazaray |
| 634 | Nunatak |
| 641 | Serpent's Disdain |
| 648 | Pearlescent Ward |
| 649 | Pillager's Profit |
| 666 | Archdruid Devyric |
| 672 | Phoenix Moth Theurge |
| 676 | Syrabane's Ward |
| 685 | Apocryphal Inspiration |
| 686 | Abyssal Brace |
| 687 | Ozezan the Inferno |
| 691 | Cryptcanon Vestments |
| 722 | Reawakened Hierophant |
| 729 | Gardener of Seasons |
| 731 | Sluthrug's Hunger |
| 734 | Anthelmir's Construct |
| 738 | The Blind |
| 762 | The Saint and the Seducer |
| 768 | Lucent Echoes |
| 769 | Xoryn's Masterpiece |
| 816 | Dolorous Arena |
| 817 | Recovery Convergence |
| 849 | Glittering Goad |

## Skill-source identity inventory

Multiple IDs on a row identify the documented family or native slot/ground variants. Morph-only contributions have a separate row. Runtime descriptions and artwork come from the relevant native APIs.

| Source row | Native IDs |
|---|---|
| Aggressive Horn | 40223 |
| Ferocious Roar | 39113 |
| Combat Prayer | 40094 |
| Elemental Drain | 39095 |
| Weakness to Elements | 29173 |
| Elemental Susceptibility | 39089 |
| Razor Caltrops | 40242 |
| Magma Fist | 31816 |
| Igneous Weapons | 31874 |
| Molten Armaments | 31888 |
| Frost Cloak | 86122, 86126, 86130 |
| Swarm | 86023, 86027, 86031 |
| Blood Altar | 39489, 41958, 41967 |
| Ring of Preservation | 40169 |
| War Horn | 38563 |
| Sturdy Horn | 40220 |
| Aggressive Horn | 40223 |
| Storm Atronach | 23634, 23492, 23495 |
| Frozen Colossus | 122174, 122395, 122388 |
| Pierce Armor | 38250 |
| Ransack | 38256 |
| Puncture | 28306 |
| Heroic Slash | 38264 |
| Boneyard | 115252, 117805, 117850 |
| Unnerving Boneyard | 117805 |
| Mark Target | 33357, 36968, 36967 |
| Lotus Fan | 25493 |
| Ambush | 25484 |
| Crystal Weapon | 46331 |
| Ice Fortress | 86130 |
| Enchanted Growth | 85862 |
| Regenerative Ward | 29482 |
| Refreshing Path | 36028 |
| Radiant Aura | 26807 |
| Luminous Shards | 26858 |
| Blazing Spear | 26869 |
| Energy Orb | 42038 |
| Dragonknight Standard | 28988, 32958, 32947 |
| Magma Shell | 17874 |
| Obsidian Shield | 29071, 29224, 32673 |
| Purge | 38571, 40232, 40234 |
| Cleansing Ritual | 22265, 22259, 22262 |
| Arcanist's Domain | 183555 |
| Zenas' Empowering Disc | 186229 |
| Reconstructive Domain | 186234 |
| Rune of the Colorless Pool | 183267 |
| Runic Sunder | 183430 |
| Vitalizing Glyphic | 183709 |
| Glyphic of the Tides | 193794 |
| Resonating Glyphic | 193558 |
| Hearthfire | 29059, 33142 |
| Fire Keeper | 20779, 21435 |
| Hearth and Home | 32710, 33099 |
| Roar | 32633, 39113, 39114 |
| Deafening Roar | 39114 |
| Deep Fissure | 86015 |

## Regression verification

`tests/catalog_accuracy.lua` covers catalog reference integrity, all 159 nonempty visual paths, corrected morph exclusions, selected-mastery prerequisites, transformation state and valid/invalid Scribing combinations. `tests/external_sources.lua` checks partial library data, unchanged LGCS reports without fabricated freshness, cache removal, native family normalization and mixed normal/Perfected counts. Dependent preparation, scanner, build and grid suites run on Lua 5.1 and Lua 5.4.

These synthetic checks validate code boundaries and catalog consistency. Real client testing remains necessary for final native rendering, controller interaction, network coexistence and actual combat proc behavior.
