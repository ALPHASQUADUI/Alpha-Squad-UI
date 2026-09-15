## Purpose

What problem does this solve, and what changes for the player?

## Affected areas

- [ ] Core / settings / themes / Move HUD
- [ ] ULT Tracker / Overload behavior / Group Ultimates
- [ ] Support Coverage / Builds / catalog
- [ ] Libraries / sharing / standalone companion
- [ ] Documentation / packaging / CI

## Evidence

- [ ] `python3 tooling/validate.py` passes for the proposed commit
- [ ] Relevant data, input or lifecycle regressions are covered
- [ ] Both installable packages are validated; release assets are not rebuilt afterward
- [ ] Player-visible changes and remaining limitations are documented

Describe actual ESO checks separately from automated checks, including any
untested client scenarios. Follow `docs/CLIENT_ACCEPTANCE.md` when applicable.

## Compatibility and resource use

- [ ] Existing saved preferences, including OFF, remain compatible
- [ ] Missing optional libraries and unknown remote data degrade safely
- [ ] Hidden/disabled modules avoid unnecessary work; permitted sharing stays independent
- [ ] No unnecessary polling, control recreation or layout work was introduced
- [ ] New commits use a GitHub noreply address; no personal data, credentials or player builds are included

## Remaining risks

State unresolved limits or follow-up work. Never include private logs, complete
SavedVariables, authentication values or another player's build without consent.
