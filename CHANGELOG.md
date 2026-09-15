# Changelog

All notable changes to Ąlpha Şquad UI are documented here.

## 3.2.0 — 2026-09-15

Repaired MOVE HUD entry across native scene transitions and restored return navigation from secondary windows. Widened Workspace navigation, gave the style dropdown an opaque native backdrop, and replaced the separate Discord page with a direct invitation in About. Overload keeps reserve warnings and manual activation without automatic cancellation. Group Ultimate controls are consolidated in the parent page and the group view excludes the local player. Support Coverage coalesces resize bursts into one deferred refresh. See [release notes](releases/3.2.0.md) and the [video review](docs/VIDEO_REVIEW_3.2.0.md).

## 3.1.0 — 2026-09-15

Corrected inherited-scale calculations across HUD placement, Builds, settings and tooltips. Added compact personal Ultimate defaults, stable horizontal/vertical layouts, isolated twelve-player editor previews, and scoped keyboard/gamepad navigation with a native gamepad Settings entry. Coverage artwork has native fallbacks, equipment alignment preserves the mannequin's proportions, and catalog and incoming-build validation reject additional false source matches. See [release notes](releases/3.1.0.md) and the [engineering audit](docs/AUDIT_3.1.0.md).

## 3.0.1 — 2026-09-15

Fixed the truncated name in ESO's Add-Ons menu by keeping title and author color markup within a compact metadata budget. The expanded entry now lists all seven group-feature libraries with green installed states and red missing, disabled, outdated or dependency warnings. Native character filters and other addons remain unchanged. See [release notes](releases/3.0.1.md).

## 3.0.0 — 2026-09-14

Unified personal Ultimate and optional Overload behavior in one HUD, added three saved interface styles, moved the settings shell into Core, and expanded MOVE HUD with proportional corner scaling, edge reflow and centralized opacity/reset controls. Group Ultimate and Support panels resize through the same placement workflow. Community and Discord use native pages and external-link confirmation. Existing display modes and supported preferences migrate. See [complete release notes](releases/3.0.0.md).

## 2.9.0 — 2026-09-14

Restored extended brand characters, added global HUD placement, configured sharing automatically on new installations with truthful native switches, and kept link dialogs in front. Coverage now fits on one compact page. Build set totals use effective per-bar counts with native excess-piece warnings, alongside a larger equipment silhouette. Remote equipment and Champion-source validation are stricter. See [complete release notes](releases/2.9.0.md).

## 2.8.0 — 2026-09-14

Dashboard and Cross-sync, independent library sharing, four visual Coverage columns, native Champion artwork, complete equipped-set summaries, foreground tooltips and lower idle module work. Food/potion readiness is integrated into Builds. See [complete release notes](releases/2.8.0.md).

## 2.7.0

### Visual build inspection
- Added a compact character-style build view with armor positioned around a body silhouette, jewelry and separate front/back weapons.
- Added named set summaries with independent front/back bonus-piece counts, including two-handed weapons.
- Added skill and Ultimate icons for both bars, Champion star icons and available class, mastery and consumable information.
- Bound equipment details to the equipped item link so trait and enchantment descriptions belong to that item.
- Used the identified skill or Ultimate for its icon and description, preserving the actual morph instead of substituting a base skill.
- Added separate Werewolf-bar and supported Vampire/Werewolf state, ability rank and verified Champion-allocation fields while retaining a conservative reader for older build snapshots.
- Kept unsupported, incomplete and stale remote details visibly unavailable.
- Centralized foreground tooltip behavior for addon windows.

### Support Coverage
- Replaced pull reports, uptime, history and loadout planning with precombat Trial/Dungeon support checks.
- Added independent effect ON/OFF controls, source explanations and duplicate-provider inspection by account.
- Added a group Food check that distinguishes missing food from missing information.
- Preserved separate weapon-bar set thresholds: a qualifying source on either bar can count without requiring both bars.
- Kept available sources distinct from active application, proc conditions, range and recipient coverage.
- Added compatible detailed build sharing and the lightweight AlphaSquadBuildShare companion for players who do not install the full UI suite.
- Integrated optional LibSetDetection set reports and conservative LibGroupCombatStats Ultimate/active-line information.
- Retired plan/live protocols. Full build sharing remains opt-in; active LibGroupBroadcast IDs are provisional pending reservation and coexistence validation.
- Paused Support scans and build sends during combat; kept snapshots, payloads, retries and recovery updates bounded.

### Existing trackers and settings
- Preserved Overload, personal ULT and Group Ultimate behavior and SavedVariables namespaces.
- Stopped unnecessary recovery and animation updates when tracker windows are hidden, disabled or dormant.
- Kept dead/offline players non-actionable and invalidated inappropriate state on group or character changes.
- Hardened native and shared values against malformed input before readiness or display calculations.
- Refined the shared Ąlpha Şquad UI settings shell, scrolling, window visibility and library/setup guidance using ESO's standard fonts.

### Validation and documentation
- Added deterministic coverage for scanner accuracy, build transport, lifecycle, settings and presentation contracts under Lua 5.1 and Lua 5.4.
- Validated Lua syntax, manifest paths/version consistency and installable full-suite/companion archives.
- Documented installation, supported third-party data, remote-inspection limits and in-game verification.

## 2.6.0 — 2026-09-12

### Suite / Core
- Added a real shared settings page registry and shell bridge in Core.
- ULT Tracker now registers its integrated page through Core instead of being directly wired by Overload.
- Reused shared Core clamp/theme infrastructure where safe.
- Unified the stable 2.6.0 version across suite metadata.
- Normal `/asult` settings use the shared Ąlpha Şquad settings shell.

### ULT Tracker
- Generic MAIN/BACK/BOTH Ultimate tracking for all slotted Ultimate abilities and morphs.
- READY sound and subtle pulse.
- Active-bar indication.
- Responsive movable HUD with persistent settings.

### Group Ultimate Tracker
- Added optional LibGroupCombatStats ULT-only integration.
- Added ability-driven raidlead filters.
- Automatically tracks @UserIDs who currently slot selected Ultimates.
- READY players sort to the top; charging players sort by percentage.
- Recently spent Ultimates are dimmed.
- Added persistent configurable HUD scale, width, row height, opacity, position and lock state.
- Removed retired per-player FRONT/BACK assignment SavedVariables.
- Group ULT updates now update the affected cached player instead of rescanning the complete roster every callback.
- Uses lightweight `GetUnitULT()` reads during full roster rebuilds.

### Repository
- Added repository-wide validation and installable packages.
- Updated README, architecture and performance documentation.
- Removed the stale committed Overload-only ZIP from the active release path.

## 2.5.0

### Architecture
- Introduced a modular Ąlpha Şquad settings suite.
- Added an internal module sidebar with Overload as the first module.
- Separated community / website information from gameplay settings.

### Performance
- Refactored tracking toward event-driven updates.
- Reduced permanent safety polling frequency.
- Uses slower dormant checks when no Overload is equipped.
- Alert animation loops only run while needed.

### Overload
- Tracks Overload, Energy Overload and Power Overload.
- Supports Primary and Backup ultimate slots.
- Supports subclassing use cases.
- Automatically hides and becomes dormant when no Overload is slotted.
- Added Ultimate counter in normal HUD state.
- Added configurable emergency reserve warnings.
- Added ready-to-activate reminder.
- Added optional PvP suppression.
- Added automatic hiding while ESO full-screen menus are open.
- Background opacity no longer fades text or icons.

### Community
- Added Ąlpha Şquad website promotion to the settings interface.
