# ULT Tracker

Personal and group Ultimate readiness for **Ąlpha Şquad UI**.

## Personal view

Design 2 shows both normal weapon-bar Ultimates as compact rows, side by side horizontally or stacked vertically. Each row combines a native icon, actual Ultimate points/native cost, a thin progress bar and a concise localized state. The counter preserves values above the cost while the bar clamps at full; an unknown cost remains `current / ?` and an empty slot shows no fabricated value or readiness. A smooth green arrow immediately to the left marks the actual active bar; the other slot is dimmed. There is no background, Ultimate name, repeated brand or AUTO/FRONT/BACK/BOTH selector. Native transformation and temporary bars show the actual special-bar Ultimate without presenting an ordinary bar as active.

Overload remains optional behavior within the same HUD. Its counter shows actual remaining Ultimate points, never a fabricated cost from the ready-reminder threshold. The progress bar includes a reserve marker; with the default 400-point reminder and 160-point reserve the marker is at 40% of that scale. **INACTIVE** is neutral, **ACTIVE** gold, **READY** pulses green and **STOP** pulses red when the reserve policy calls for deactivation. French uses **INACTIF**, **ACTIF**, **PRÊT** and **STOP**. Mechanics and manual activation/cancellation remain unchanged. Short progression animation only runs while a visible value is moving; hidden HUDs do not retain presentation timers.

The personal HUD never changes the native Ultimate button's visibility, opacity, input or handlers. ESO and installed action-bar addons retain ownership in every tracking, menu, loading and placement state. Hiding only the personal HUD permits group tracking to continue. Native casting/keybinds and library sharing remain independent.

Dashboard offers English and French, seeded once from a supported client language with English fallback. Addon-owned text and verified supported name mappings follow that saved choice. Unmapped names and complete native tooltips retain ESO's client language; item links and player names are never rewritten.

## Group view

Use **Group tracking ON/OFF** on the **GROUP ULTIMATES** card, then open **CONFIGURE** or `/asult group`. Toggle curated support Ultimate families; verified base and morph IDs match automatically without manual player assignments. The view uses the reported morph's icon and actual reported cost. Cryptcanon's dedicated Ultimate is included; wearing the item alone is not evidence of a ready cast. Your own character is excluded because the personal HUD already tracks your Ultimates. Closing configuration returns to the previous Alpha Squad window. A previously hidden group HUD migrates to OFF once; saved layout remains intact.

The crowned native group leader selects the **Raid leader** from current group accounts. Only that designated player changes the group's tracked families. Other grouped players see the shared choice and receive an explanation when a change is not permitted. The authority and filter selection are checked against current group membership; received names do not establish authority by themselves. Local tracking visibility and layout remain personal choices.

The catalog contains nineteen supported families. Defaults enable War Horn, Frozen Colossus, Summon Storm Atronach, Barrier, Cryptcanon, Dragonknight Standard and Vitalizing Glyphic. Optional families cover Consuming Darkness, Negate Magic, Nova, Rite of Passage, Secluded Grove, Sleet Storm, Panacea, Reanimate, Soul Siphon, Gibbering Shelter, Magma Shell and Pack Leader. The exact representative names come from verified native IDs. Only documented ally-support morphs are accepted where a sibling morph has a different purpose; a selected family does not prove the effect has been cast or is reaching every group member.

Each row shows a compact food status before the player's @UserID, the reported Ultimate icon, charge percentage and readiness state. Food distinguishes verified active, verified absent and unknown information; missing or expired evidence is never presented as confirmed absence. The HUD omits repeated ability names and raw Ultimate-point totals. If a player matches multiple selected abilities, it prioritizes a ready Ultimate, otherwise the one closest to ready. READY players sort first; recent resource spends are temporarily dimmed. The same morph on both bars occupies one row and uses the lowest valid reported cost. Charging values stay below 100% until that cost is reached. Group readiness uses visual highlighting without a separate ready sound.

Food uses **green +** for verified active, **red −** for verified absence and **grey ?** for unknown, with a food icon and explanation on hover. It reuses existing Support Coverage evidence for the same account, unit tag and current character; samples older than 75 seconds or past their known expiry become unknown. This adds no food scanner, sender or timer. A fresh summary takes priority over older detailed build evidence.

A spend indicator is inferred from shared resource changes, not a guaranteed remote cast ID. Offline and dead players cannot be treated as actionable ready players. LibGroupCombatStats can stop broadcasting unchanged Ultimate values; their age alone cannot prove they are stale. A connected player who stops sharing may retain their last known value until the library updates or clears it.

## Group data and sharing

Group tracking uses **LibGroupCombatStats** with its declared dependencies, including LibCombat and LibGroupBroadcast. The personal view needs none of these libraries. Alpha Squad requests ULT data, not DPS or HPS streams.

A compatible sender may be Alpha Squad or another addon publishing the same library data. Installing a library alone does not prove every group member is sharing. Ultimate/active-line reports do not establish complete gear, skill bars, CP, passives or masteries; supported full builds use a separate compatible sender.

Raid-leader/filter synchronization uses a separate settings-only LibGroupBroadcast protocol, provisionally **511**. It carries coordination settings, not equipment, food snapshots or Ultimate charge. It respects its native OFF setting and cannot enable build or Ultimate sharing. Matching full-suite clients are required for this coordination; the Build Share companion does not provide the group settings interface. Formal protocol reservation and multiplayer coexistence remain pending.

The crown is the default raid leader and can reclaim the role. Edits and settings sends pause during combat/loading. When transport is missing, incompatible or disabled, the status exposes the limitation rather than claiming group agreement; unauthorized grouped edits remain locked. Received filters are transient, and leaving the group restores local preferences. Changes coalesce instead of broadcasting on every row refresh, with bounded retries and no idle synchronization heartbeat.

Open **Libraries** for dependency status and **Share group Ultimates**. A new installation keeps sharing OFF until an explicit choice; existing saved choices and native OFF states are preserved. The switch reads and changes the actual native protocol settings without opening another addon page. Other addons using those same protocols follow that library setting; unrelated protocols remain unchanged.

## Placement and saved settings

Use **MOVE HUD** in the main sidebar or `/asmove` outside combat. Drag anywhere on the selected personal or group panel, including over its rows and icons, to position it against the normal game interface. Use the orientation icon beside the selected Ultimate panel. Personal slots sit side by side horizontally or stack vertically; the orientation stays fixed while resizing. The group horizontal layout uses four columns for up to twelve players, while its vertical layout uses one list. Each orientation keeps its own size. Drag corners to scale proportionally and edges to add space. The placement toolbar controls scale, supported background opacity, fit and reset for the selected panel. Choose **DONE** or press Escape to save, lock and select Alpha Squad in native Settings. Transparent Ultimate HUDs hide the background opacity controls. Disabled modules stay disabled and normal visibility choices are preserved. Placement defaults to clearly labelled examples even when no abilities are slotted and no group is present. Mixed examples show ready and charging Ultimates, recently spent resources, disabled sharing, missing slots, offline and dead players. The group preview always includes twelve fictional accounts. Ready, Missing, Overload and Live preview modes are available; Live shows only real data. The examples never change the roster, tracking choices, sharing payloads or alert state.

New personal layouts start at 316 × 48 logical UI units horizontally and 152 × 108 vertically. Existing saved dimensions and placement are retained. ESO applies screen and interface scaling once; automatic fitting preserves the requested dimensions, scale and saved position for a larger viewport.

Sizing and opacity are centralized in MOVE HUD. Group rows keep the height chosen using the twelve-player layout as players enter or leave. The visible panel contracts around the live roster without enlarging the remaining rows; icons stay square. Cross-sync ON shares settings and positions across characters on the same account/server; OFF keeps native character profiles separate. Existing SavedVariables and group selections survive reloads and travel. Dashboard's Ember Classic, Tactical Compact and Obsidian Studio styles update both personal and group panels without changing status meanings.

Dashboard owns the module switch. Disabling tracking releases its gameplay work while Libraries sharing remains independent. The group view also respects its single tracking switch and the parent's state.

## Performance

Native events drive personal slot/resource and Overload effect changes. Ultimate slot events coalesce into one refresh per burst; ordinary skill-slot changes do not trigger Ultimate rescans. Resource-only HUD changes reuse unchanged geometry. Group ability identity is cached in a bounded table, with unsupported native lookups handled safely. A shared 1.5-second safety refresh runs only while the tracker is enabled, visible and unobscured. Alert animation exists only while its output is visible and needed. Overload does not create a second personal HUD, resource poll or recovery heartbeat.

Incoming group updates affect the relevant cached player. Membership changes and a two-second visible-state safety check rebuild the roster as needed. Up to twelve pooled rows are reused. Hidden/disabled group panels do not rebuild continuously; alerts and safety timers stop during placement or loading. No combat-log parsing is required.

Only curated support transformation morphs, such as Pack Leader, match group filters through their verified native identity. LibGroupCombatStats reports front/back Ultimate slots; those reports do not independently prove that a teammate is currently transformed or expose a separate transformed action bar. Unknown costs remain unknown when a slot identity changes.

LibGroupCombatStats owns its shared callbacks and sender timer. Disabling the matching sharing protocol blocks that traffic without removing registrations belonging to other addons; the library's own timer may remain until reload.

## Commands

| Command | Action |
| --- | --- |
| `/asui` or `/alphasquad` | Main settings |
| `/asult` | ULT settings |
| `/asoverload settings` | Optional Overload behavior settings |
| `/asult group` | Group Ultimate configuration |
| `/asmove` | Position all enabled HUD panels |
| `/asult show`, `/asult hide` | Change personal visibility |
| `/asult enable`, `/asult disable` | Change personal/group parent activation |
| `/asult reset`, `/asult status` | Reset placement or inspect status |
| `/asult group show`, `/asult group hide` | Legacy aliases for the group tracking ON/OFF switch |
| `/asult group reset` | Reset group placement |

The active-hotbar and effect-duration behavior follows the [native action bar](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/esoui/ingame/actionbar/actionbar.lua) and [ESO API contracts](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/ESOUIDocumentation.txt), including `GetActiveHotbarCategory`, `GetEffectiveAbilityIdForAbilityOnHotbar`, `GetActionSlotEffectTimeRemaining` and `EVENT_ACTION_SLOT_EFFECT_UPDATE`.

See the [ESO acceptance checklist](../../../docs/SUPPORT_COVERAGE_TESTING.md) for actual-client verification. Automated results do not certify native rendering or measured frame time.
