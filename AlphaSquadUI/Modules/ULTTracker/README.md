# ULT Tracker

Personal and group Ultimate readiness for **Ąlpha Şquad UI**.

## Personal view

Choose AUTO, FRONT, BACK or BOTH to follow the actual Ultimate and morph slotted on either weapon bar. Class, guild, weapon, Vampire, Werewolf and subclassed abilities use their native identity; there is no fixed list of supported personal Ultimates. A native transformation or temporary hotbar replaces the weapon cards while active, then restores the saved Front/Back/Both choice. The current native slot supplies its morph, texture and cost; an empty special slot remains empty.

The compact panel shows the native ability icon/name, current Ultimate resource, active bar and charging/READY/ACTIVE state. The native ability tooltip supplies the full skill details and cost. Crossing into READY can play a sound and show a pulse. Spending Ultimate clears readiness while native resource state settles. Toggle Ultimates use their actual toggled state. Timed Ultimates use the native action-slot effect duration for ACTIVE, so an ongoing transformation does not falsely flash READY when sufficient resource remains.

**AUTO**, the new-installation default, follows the active weapon bar. Enabled, applicable Overload behavior can prioritize a slotted Overload morph on either bar in AUTO, FRONT or BACK. **BOTH** always retains both cards. Existing saved display choices are preserved.

Overload now uses this same personal HUD and lifecycle. Open **OVERLOAD SETTINGS** for the **Use Overload behavior** toggle, reserve warnings, ready reminder and PvP preference. Disabling that behavior retains standard Ultimate tracking; disabling ULT Tracker stops both. Group Ultimate tracking stays independent of personal display mode. **Warning starts** controls the low-reserve notification; the player retains control of Overload activation through the normal Ultimate binding. The addon does not stop Overload or expose a clickable cancellation action. Existing warning and sound preferences survive the removal of the old cutoff.

## Group view

Use the **Group tracking ON/OFF** switch directly on the **GROUP ULTIMATES** card, then open **CONFIGURE** or `/asult group`. Select Ultimate abilities to monitor; matching teammates appear automatically, without manual player assignments. **SELECT ALL** and **CLEAR ALL** are available. Up to 24 selected Ultimate filters are retained. Your own character is excluded; the personal HUD already tracks your Ultimates. The separate group Show/Hide, Self and Ready Sound controls are removed. Closing configuration returns to the previous Alpha Squad window. A previously hidden group HUD migrates to OFF once; later switch changes, saved filters and layout remain intact.

Each row shows the player's @UserID, native ability icon, charge percentage and readiness state. The HUD omits repeated ability names and raw Ultimate-point totals. If a player matches multiple selected abilities, it prioritizes a ready Ultimate, otherwise the one closest to ready. READY players sort first; recent resource spends are temporarily dimmed. The same morph on both bars occupies one row and uses the lowest valid reported cost. Charging values stay below 100% until that cost is reached. Group readiness uses visual highlighting without a separate ready sound.

A spend indicator is inferred from shared resource changes, not a guaranteed remote cast ID. Offline and dead players cannot be treated as actionable ready players. LibGroupCombatStats can stop broadcasting unchanged Ultimate values; their age alone cannot prove they are stale. A connected player who stops sharing may retain their last known value until the library updates or clears it.

## Group data and sharing

Group tracking uses **LibGroupCombatStats** with its declared dependencies, including LibCombat and LibGroupBroadcast. The personal view needs none of these libraries. Alpha Squad requests ULT data, not DPS or HPS streams.

A compatible sender may be Alpha Squad or another addon publishing the same library data. Installing a library alone does not prove every group member is sharing. Ultimate/active-line reports do not establish complete gear, skill bars, CP, passives or masteries; supported full builds use a separate compatible sender.

Open **Libraries** for dependency status and **Share group Ultimates**. A new installation keeps sharing OFF until an explicit choice; existing saved choices and native OFF states are preserved. The switch reads and changes the actual native protocol settings without opening another addon page. Other addons using those same protocols follow that library setting; unrelated protocols remain unchanged.

## Placement and saved settings

Use **MOVE HUD** in the main sidebar or `/asmove` outside combat. Position the personal and group panels against the normal game interface. Choose **Horizontal** or **Vertical** for the selected Ultimate panel. Personal BOTH cards sit side by side horizontally or stack vertically; the orientation stays fixed while resizing. The group horizontal layout uses four columns for up to twelve players, while its vertical layout uses one list. Each orientation keeps its own size. Drag corners to scale proportionally and edges to add space. The placement toolbar controls scale, background opacity, fit and reset for the selected panel. Choose **DONE** or press Escape to save and lock. Disabled modules stay disabled and normal visibility choices are preserved. Placement defaults to clearly labelled examples even when no abilities are slotted and no group is present. Mixed examples show ready and charging Ultimates, recently spent resources, disabled sharing, missing slots, offline and dead players. The group preview always includes twelve fictional accounts. Ready, Missing, Overload and Live preview modes are available; Live shows only real data. The examples never change the roster, tracking choices, sharing payloads or alert state.

A new personal HUD starts at 300 × 116 logical UI units. Existing saved sizes and bar choices are retained. ESO applies screen and interface scaling once; automatic fitting preserves the requested dimensions, scale and saved position for a larger viewport.

Sizing and opacity are centralized in MOVE HUD. Group rows keep the height chosen using the twelve-player layout as players enter or leave. The visible panel contracts around the live roster without enlarging the remaining rows; icons stay square. Cross-sync ON shares settings and positions across characters on the same account/server; OFF keeps native character profiles separate. Existing SavedVariables and group selections survive reloads and travel. Dashboard's Ember Classic, Tactical Compact and Obsidian Studio styles update both personal and group panels without changing status meanings.

Dashboard owns the module switch. Disabling tracking releases its gameplay work while Libraries sharing remains independent. The group view also respects its single tracking switch and the parent's state.

## Performance

Native events drive personal slot/resource and Overload effect changes. Ultimate slot events coalesce into one refresh per burst; ordinary skill-slot changes do not trigger Ultimate rescans. Resource-only HUD changes reuse unchanged geometry. Group ability identity is cached in a bounded table, with unsupported native lookups handled safely. A shared 1.5-second safety refresh runs only while the tracker is enabled, visible and unobscured. Alert animation exists only while its output is visible and needed. Overload does not create a second personal HUD, resource poll or recovery heartbeat.

Incoming group updates affect the relevant cached player. Membership changes and a two-second visible-state safety check rebuild the roster as needed. Up to twelve pooled rows are reused. Hidden/disabled group panels do not rebuild continuously; alerts and safety timers stop during placement or loading. No combat-log parsing is required.

Transformation morphs are accepted through the same native ID lookup as every other shared Ultimate. LibGroupCombatStats reports front/back Ultimate slots; those reports do not independently prove that a teammate is currently transformed or expose a separate transformed action bar. Unknown costs remain unknown when a slot identity changes.

LibGroupCombatStats owns its shared callbacks and sender timer. Disabling the matching sharing protocol blocks that traffic without removing registrations belonging to other addons; the library's own timer may remain until reload.

## Commands

| Command | Action |
| --- | --- |
| `/asui` or `/alphasquad` | Main settings |
| `/asult` | ULT settings |
| `/asult auto`, `/asult main`, `/asult back`, `/asult both` | Select the personal display mode |
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
