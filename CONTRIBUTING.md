# Contributing

Ąlpha Şquad UI is a public repository maintained by SeRuM1.

## Branch / PR workflow

- `main` is stable/release.
- Never develop directly on `main`.
- Use a feature, fix, audit or test branch.
- Open a pull request targeting `main`.
- Do not merge until the change has been validated in ESO when gameplay/UI behavior is affected.

## Development rules

1. Keep modules independent wherever practical.
2. Prefer ESO events over high-frequency polling.
3. Never run fast animation loops while their UI is hidden.
4. Avoid automatic gameplay chat spam.
5. Keep combat HUD elements compact and readable.
6. Keep community promotion inside settings.
7. Preserve SavedVariables compatibility.
8. Test both weapon bars when action slots are relevant.
9. Support subclassing from equipped skills rather than base-class assumptions.
10. Register new settings pages through Core.
11. Update `CHANGELOG.md` and user documentation for user-facing changes.
12. Run the repository validation workflow and test the generated ZIP in ESO before release.
