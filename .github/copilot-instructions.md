# Ąlpha Şquad UI — Repository Instructions

Read and follow the root `AGENTS.md` before modifying this repository.

Critical rules:
- Never push development changes directly to `main`.
- `main` is stable/release; use feature/fix/test branches and PRs.
- Do not assume `main` contains all active work. Inspect named feature branches first.
- Current active feature branch: `support-coverage`.
- Preserve existing SavedVariables and user settings.
- Favor event-driven ESO code and compact, low-overhead combat UI.
- New settings pages register through `AlphaSquadUI.Settings.RegisterPage`.
- Validate Lua, manifest paths, version consistency and ZIP packaging before PR.
- Gameplay/UI/API changes require in-game ESO testing.
- Support Coverage sharing protocol IDs 507–510 are provisional and must not be treated as public-release-safe until formally reserved/verified.
- Project conversation continuity is stored in `docs/PROJECT_CONTEXT.md`.
