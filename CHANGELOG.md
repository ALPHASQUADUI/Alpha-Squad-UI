# Changelog

All notable changes to Ąlpha Şquad UI are documented here.

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
