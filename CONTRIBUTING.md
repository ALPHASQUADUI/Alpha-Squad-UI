# Contributing

Ąlpha Şquad UI is maintained by **@SeRuM1**. Contributions should make the addon clearer, more reliable and cheaper to run.

## Changes and review

Keep each change focused, explain the user problem and document the resulting behavior. Preserve existing gameplay features and SavedVariables. Follow the maintainer's requested Git scope, use reviewable commits and never merge or publish a release without approval. Interface and gameplay changes require a real ESO check before release; automated checks alone cannot establish rendering, FPS or network coexistence.

Update the README, module documentation and changelog when behavior changes. Use English in the addon and public documentation. Keep personal identities, private conversations, credentials and player snapshots out of commits and screenshots.

## Engineering rules

- Prefer filtered events, coalesced work and bounded caches to frequent polling.
- Keep module tracking independent of library sharing. Disabled modules must release their subscriptions and timers; shared library events belong to their library.
- Keep Cross-sync account and character settings separate, preserve existing namespaces and use deep copies for nested settings.
- Use real ESO item links, skill/morph IDs, Champion allocation and native visual resources. Do not invent missing remote data or substitute the viewer's equipment for a sender's.
- Validate incoming sizes, identities, versions, ranges and freshness before mutation. Keep network payloads and retry state bounded.
- Keep native tooltips above addon windows and restore their state when closed.
- Register pages through Core and reuse controls. Put module switches in Dashboard and sharing switches in Libraries.
- Use only the targeted library protocol settings after verifying ownership and identity. An unsupported integration must degrade safely.

## Local validation

From the repository root:

```sh
python3 tooling/validate.py
```

The validator runs every regression suite with Lua 5.1 and 5.4, checks Lua syntax, manifest/version consistency and whitespace, and validates the full and companion packages. Use `LUA51` and `LUA54` environment variables when the runtimes have different executable names. CI runs the same checks with standard Lua interpreters.

Meaningful regressions should cover the affected boundary: exact item traits/enchantments, CP allocation, profile isolation, module lifecycle, tooltip ownership or malformed/stale packets. Avoid tests that only duplicate implementation details.

For client validation, use the [ESO checklist](docs/SUPPORT_COVERAGE_TESTING.md). Include enabled/disabled states, both weapon bars, character changes, `/reloadui`, travel and instance transitions. Reproduce a defect with the smallest relevant addon/library combination and attach the exact error and steps.

## Release preparation

Keep manifest/Core versions aligned and increment the numeric AddOnVersion. Build installable full-suite and companion archives, inspect the CI result and publish concise notes describing the user-visible changes. Reserve the active LibGroupBroadcast protocol identifiers before a public full-build-sharing release. Preserve the maintainer's final approval step.
