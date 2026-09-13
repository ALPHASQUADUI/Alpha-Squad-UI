# Changelog

All notable changes to Ąlpha Şquad UI are documented here.


## 2.7.0-support-coverage-test.5 — Unreleased

Precombat-focused branch candidate. Requires in-game validation before an explicit maintainer PR request; no public sharing release is claimed.

### Support Coverage
- Replaced the active pull-report, uptime, history and loadout-planning workflow with precombat Trial/Dungeon support checks.
- Added independent effect ON/OFF controls, source explanations and duplicate-provider inspection by account.
- Added group Builds and Food views with scrolling lists and named equipment, skill, Champion, mastery and consumable evidence where available.
- Preserved separate weapon-bar set thresholds; a qualifying set on either bar can supply a source without requiring both bars.
- Kept source availability distinct from active effect application, proc conditions and recipient coverage; unsupported and stale data remains UNKNOWN.
- Added compatible detailed build sharing and a lightweight AlphaSquadBuildShare companion for players who do not install the full UI suite.
- Added optional LibSetDetection set-source integration and conservative LibGroupCombatStats evidence for group members using compatible third-party sharing.
- Retired the plan/live protocols and kept experimental build protocols provisional and opt-in.
- Suspended Support scans and build sends during combat; used cached precombat snapshots, bounded transport and lightweight recovery updates.

### Suite and documentation
- Updated settings branding to Ąlpha Şquad UI with the accented letters and ESO's standard interface font.
- Improved responsive windows, scrolling and dependency/setup guidance.
- Documented native remote-inspection limits, LibGroupCombatStats ULT-only scope, companion setup and the current in-game checklist.
- Preserved existing SavedVariables namespaces and relevant tracker preferences.


## 2.7.0-support-coverage-test.4 — Superseded development candidate

Historical record of the previous candidate. Its report/planner features are superseded by test.5; this entry is not the current feature list.

### Support Coverage
- Added evidence-aware readiness, build expectations, per-target live coverage, a bounded planner and recoverable pull history.
- Added committed Class Mastery, Champion slottable, equipment, enchantment, food, potion, poison and Mundus inspection without turning unavailable data into a pass.
- Corrected native ESO API usage for group roles, enchant identities, active quickslots and Class Mastery eligibility.
- Replaced pre-release Class Mastery identities with the live U50 names, ability IDs and rank-two prerequisite checks.
- Kept quickslot selection updates on the lightweight readiness path and prevented an empty quickslot from falling back to an unrelated hotbar.
- Preserved separate weapon-bar set counts, native normal/Perfected families and distinct unknown-ID set names; compact sharing now encodes native set IDs before any name fallback.
- Removed a misleading fixed Tremorscale penetration value and excluded personal critical buffs from the reported group critical-damage bonus.
- Hardened all received group payloads, SavedVariables and persisted history with type, range, membership, leader, freshness and size checks.
- Replaced raw build-detail sharing with bounded signatures; prevented detail message kinds from replacing one another in the LibGroupBroadcast queue.
- Bound signature frames to the advertised build fingerprint so a loadout change immediately invalidates stale audit details.
- Added plan and pull heartbeats with bounded frequency so late joiners recover state without permanent fast loops.
- Recovered local sharing after joining an already formed group and started pull collection when a group forms after local combat has already begun.
- Scoped saved encounter templates to the active profile so loading a boss context cannot erase newer damage/trash/progression templates.
- Kept experimental sharing off by default. Protocol IDs 507–510 remain unreserved and block a public sharing release.

### ULT Tracker
- Stopped safety and animation updates while the relevant tracker is disabled, hidden or obscured.
- Kept dead and offline players visible but non-actionable, purged departed-player state and bounded tracked Ultimate IDs.
- Cleared stale spend-transition state when a present member stops sharing and reused power-event values instead of immediately re-reading the native resource.
- Hardened group payload and SavedVariables handling without changing existing namespaces.
- Rejected non-finite native Ultimate values, costs and ability IDs before they reach readiness or UI calculations.

### Overload Tracker
- Preserved active tracking behavior while stopping its recovery heartbeat whenever the HUD is disabled, hidden, obscured, PvP-suppressed or dormant.
- Hardened migrated booleans, thresholds, position, scale and opacity against malformed SavedVariables.
- Normalized non-finite native Ultimate values without changing valid Overload state, reserve or cancellation behavior.

### Validation
- Added deterministic Support Coverage, ULT Tracker and Overload lifecycle regression suites for Lua 5.1 and 5.4.
- Added pull-request CI coverage, dual-version syntax checks, version consistency checks and installable ZIP integrity validation.
- Documented branch-only test-build downloads, safe installation, validation limits and the requirement to complete ESO testing before any PR.

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
- Replaced branch-specific validation with repository-wide PR/main validation.
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
