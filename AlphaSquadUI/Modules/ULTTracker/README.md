# ULT Tracker

Personal and group Ultimate readiness for **Ąlpha Şquad UI**.

## Personal view

Choose AUTO, FRONT, BACK or BOTH to follow the actual Ultimate and morph slotted on either weapon bar. Class, guild, weapon and subclassed abilities use their native identity; there is no fixed list of supported personal Ultimates.

The panel shows the ability icon/name, cost, current Ultimate resource, active bar and charging/READY/ACTIVE state. Crossing into READY can play a sound and show a pulse. Spending Ultimate clears readiness while native resource state settles. Toggle Ultimates use their actual toggled state instead of continuing to flash READY while active.

**AUTO**, the new-installation default, follows the active weapon bar. Enabled, applicable Overload behavior can prioritize a slotted Overload morph on either bar in AUTO, FRONT or BACK. **BOTH** always retains both cards. Existing saved display choices are preserved.

Overload now uses this same personal HUD and lifecycle. Open **OVERLOAD SETTINGS** for the **Use Overload behavior** toggle, reserve warnings, optional safe cancellation, ready reminder and PvP preference. Disabling that behavior retains standard Ultimate tracking; disabling ULT Tracker stops both. Group Ultimate tracking stays independent of personal display mode.

## Group view

Open **ULT Tracker → CONFIGURE GROUP** or `/asult group`. Select Ultimate abilities to monitor; matching group accounts appear automatically, without manual player assignments. **SELECT ALL** and **CLEAR ALL** are available. Up to 24 selected Ultimate filters are retained.

Each row shows the player's @UserID, native ability icon, charge percentage and readiness state. The HUD omits repeated ability names and raw Ultimate-point totals. If a player matches multiple selected abilities, it prioritizes a ready Ultimate, otherwise the one closest to ready. READY players sort first; recent resource spends are temporarily dimmed.

A spend indicator is inferred from shared resource changes, not a guaranteed remote cast ID. Offline, dead, disconnected and stale records cannot be treated as actionable ready players.

## Group data and sharing

Group tracking uses **LibGroupCombatStats** with its declared dependencies, including LibCombat and LibGroupBroadcast. The personal view needs none of these libraries. Alpha Squad requests ULT data, not DPS or HPS streams.

A compatible sender may be Alpha Squad or another addon publishing the same library data. Installing a library alone does not prove every group member is sharing. Ultimate/active-line reports do not establish complete gear, skill bars, CP, passives or masteries; supported full builds use a separate compatible sender.

Open **Libraries** for dependency status and **Share group Ultimates**. A new installation enables supported sharing once, while existing saved OFF choices are preserved. The switch reads and changes the actual native protocol settings without opening another addon page. Other addons using those same protocols follow that library setting; unrelated protocols remain unchanged.

## Placement and saved settings

Use **MOVE HUD** in the main sidebar or `/asmove` outside combat. Position the personal and group panels against the normal game interface. Drag corners to scale proportionally and edges to reshape content; BOTH cards stack when the personal panel becomes narrow. The placement toolbar controls scale, background opacity, fit and reset for the selected panel. Click **DONE** or press Escape to save and lock. Disabled modules stay disabled and normal visibility choices are preserved. Group placement remains possible with no current matching members by showing its placement guide.

Sizing and opacity are centralized in MOVE HUD. Group rows adapt to the available panel space while keeping their icons square. Cross-sync ON shares settings and positions across characters on the same account/server; OFF keeps native character profiles separate. Existing SavedVariables and group selections survive reloads and travel. Dashboard's Ember Classic, Tactical Compact and Obsidian Studio styles update both personal and group panels without changing status meanings.

Dashboard owns the module switch. Disabling tracking releases its gameplay work while Libraries sharing remains independent. The group view also respects its own enabled/visible settings and the parent's state.

## Performance

Native events drive personal slot/resource and Overload effect changes. A shared 1.5-second safety refresh runs only while the tracker is enabled, visible and unobscured. Alert animation exists only while its output is visible and needed. Overload does not create a second personal HUD, resource poll or recovery heartbeat.

Incoming group updates affect the relevant cached player. Membership changes and a two-second visible-state safety check rebuild the roster as needed. Up to twelve pooled rows are reused. Hidden/disabled group panels do not rebuild continuously; alerts and safety timers stop during placement or loading. No combat-log parsing is required.

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
| `/asult group show`, `/asult group hide` | Change group visibility |
| `/asult group reset` | Reset group placement |

See the [ESO acceptance checklist](../../../docs/SUPPORT_COVERAGE_TESTING.md) for actual-client verification. Automated results do not certify native rendering or measured frame time.
