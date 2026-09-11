# Contributing

Ąlpha Şquad UI is currently a private project maintained by SeRuM1.

## Development rules

1. Keep modules independent wherever possible.
2. Prefer ESO events over high-frequency polling.
3. Never run animation update loops when their UI is hidden.
4. Avoid chat spam from automatic gameplay events.
5. Keep combat HUD elements compact and readable.
6. Keep community promotion inside settings, never over the combat HUD.
7. Preserve SavedVariables compatibility when migrating existing modules.
8. Test Primary and Backup action bars when working with slotted abilities.
9. Subclassing compatibility should be based on equipped skills rather than base class assumptions.
10. Add user-facing changes to `CHANGELOG.md`.
