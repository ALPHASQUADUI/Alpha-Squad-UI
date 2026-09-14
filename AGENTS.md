# Engineering guidelines

## Project

**Ąlpha Şquad UI**, maintained by **@SeRuM1**, is a modular ESO addon. The package folder is `AlphaSquadUI/`. Modules are Overload, personal/group ULT Tracker and Support Coverage. `companion/` contains the optional sharing-only sender.

Read the existing implementation and the maintainer's current request before editing. Work only within the explicitly authorized Git scope. Preserve unrelated changes. Do not create a pull request, merge, tag or public release until requested and the required client validation is complete. Do not update a protected release ref as part of development.

## Product and evidence

- Keep the interface and public documentation in English, concise and understandable.
- Module switches belong to Dashboard; sharing belongs to Libraries. Disabling tracking must not revoke sharing consent.
- Native group membership is not permission or an API for arbitrary remote inventory inspection. Missing or stale data remains Unknown.
- Item links and effective morph IDs are authoritative. Never substitute another item's trait/enchant or the viewer's build for a peer.
- Class identity alone does not prove learned passives, eligible masteries or slotted abilities.
- Count front/back set pieces separately. Two-handed weapons contribute two pieces but remain one physical item.
- Champion visuals use native discipline stars; descriptions use the inspected player's allocated points.
- Keep native tooltips in front of addon windows and restore their original draw state afterward.
- Group readiness is a precombat availability check. Do not reintroduce uptime, pull history or a combat-log sampler.

## Architecture and performance

Register settings pages through `AlphaSquadUI.Settings.RegisterPage(id, builder)`. The shell is hosted by Overload but must remain accessible when Overload tracking is disabled.

Use Core event scopes to suspend module subscriptions. Preserve activation events, filter high-volume events, coalesce invalidations, reuse controls and stop animation timers when hidden. A disabled Support module may retain the minimum grouped sender work required by explicit Libraries consent. Pause scans and detail traffic during loading and combat.

Preserve the existing SavedVariables namespaces. Cross-sync defaults to existing account/server settings. Character profiles must be deep copies, retain the current layout on a switch and keep Group ULT's settings reference current. Sharing preferences remain account-wide. Remote snapshots are transient, bounded data, never persistent history.

Use optional libraries defensively. Verify both handler ownership and protocol identity before changing matching library settings. Never modify unrelated protocols, force-enable installed addon files or unregister another library's shared callbacks. A missing/incompatible library must degrade safely without a retry storm.

Active build transport IDs **507/510** are provisional. Keep build exchange opt-in and do not publish stable public sharing with these IDs until formally reserved and coexistence-validated. Legacy **508/509** are retired.

## Validation and delivery

Run `python3 tooling/validate.py`, inspect the CI result and validate the two installable packages. Add meaningful regressions for changed data/lifecycle boundaries. Do not claim runtime rendering, zero FPS impact or zero disconnects from synthetic checks.

Follow the real-client checklist in `docs/SUPPORT_COVERAGE_TESTING.md`. Update README, module docs, CHANGELOG and architecture/performance notes for user-visible changes. Keep personal data, private conversations and credentials out of the repository and deliverables.
