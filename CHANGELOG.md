# Changelog

All notable changes to Ąlpha Şquad UI will be documented here.

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
