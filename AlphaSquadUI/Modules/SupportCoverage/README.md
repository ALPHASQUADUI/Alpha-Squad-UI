# Support Coverage

Precombat group support checks for **Ąlpha Şquad UI**, version **2.7.0-support-coverage-test.5** (`20705`) on `support-coverage`.

## Workflow

1. Group with the players you want to check.
2. Open Support Coverage and choose **Trial** or **Dungeon**.
3. Turn the relevant effects **ON/OFF**. Filter the list by **ALL**, **MISSING** or **DUPLICATES**. Hover an effect's information icon for its description, known sources and conditions.
4. Review known providers, missing coverage and duplicates. Hover `@UserID` to inspect the identified skill/set/mastery source.
5. Open **Builds**, choose a player to request its current snapshot and inspect available equipment and build details. Use **REFRESH BUILD** to request a new snapshot. Equipment is listed by body slot from feet toward head, with jewelry and weapons separately.
6. Open **Food** to review the group's known food/drink status.

A source counted on one weapon bar can cover its catalog entry even if it is absent from the other bar. Thresholds still apply: two-handed weapons count as two pieces, and one item from a five-piece set is insufficient.

## Meaning of coverage

`COVERED` describes available build evidence, not live effect application. It does not guarantee an effect is active, that its proc condition will be met, that a target is in range or that all twelve players can receive it. Source tooltips explain these limits where known.

A duplicate means multiple identified providers, not automatically a bad build. Two limited-target sources may be intentional. Sources contributing the same named Major/Minor effect do not imply that effect stacks. A known equipped group set is distinct from an observed active buff.

Unverified, unsupported, stale and incomplete fields remain `UNKNOWN`. Class identity alone does not prove purchased passives, selected masteries or slotted abilities. Selected potion details do not prove the potion was consumed. No role-specific loadout is forced.

## Build evidence

The local scanner reads equipment links/sets, separate front/back bars, Champion slottables, committed Class Masteries and prerequisites, glyph information, food, selected potion and other available local readiness fields.

Peer details require a compatible sender. Native grouping alone does not provide remote gear, full skill bars, CP or mastery selections. LibGroupCombatStats supplies compatible Ultimate identities and supported active class-line data, not complete skill/passive/CP/mastery inspection. LibSetDetection v5 optionally supplies shared set identities and per-bar activation without requiring Alpha Squad on the sender; hidden or unavailable sets remain unknown.

A sender may use the full **Ąlpha Şquad UI** or the lightweight **AlphaSquadBuildShare** companion. Both need LibGroupBroadcast plus its required LibAddonMenu-2.0 and LibDebugLogger dependencies for the compatible experimental build protocol. LibFoodDrinkBuff optionally improves food-buff identification on supported player/group units; missing remote observations still do not prove absence. Install the relevant libraries on the sending clients as well as the receiver.

## Dependencies and sharing

Open **Libraries** for status and setup. Library installation does not by itself publish a build. For full build details, each participant must explicitly enable a compatible sender, join the group and opt into experimental sharing. In the full suite, enable both **Share my build** and **Experimental sharing**. LibSetDetection set sharing uses its own library controls and does not require enabling Alpha Squad's experimental full-build protocol. Missing or incompatible senders leave remote fields unknown.

Experimental sharing defaults OFF. Provisional protocol IDs require formal reservation and coexistence validation before a public sharing release. Use matching test versions and do not claim support for arbitrary unrelated addons' equipment protocols.

Compact capability summaries are automatic while compatible precombat sharing is enabled. Detailed builds are requested on demand; a valid response is cached for 120 seconds and invalidated when the advertised build changes. Transfer delays do not justify guessing missing details.

The build viewer displays names and available details; internal identities are implementation details. Delayed snapshots must not be blended with an old build to invent a complete current loadout.

## Scope and persistence

This version removes pull reports, live uptime, combat history and recorded-loadout planning from the active Support Coverage workflow. Checks are useful before combat; they do not need a pull to populate shared builds.

Supported UI and effect preferences remain persistent in `AlphaSquadSupportCoverageSavedVariables`. Remote build snapshots are bounded transient group data. The addon never equips items, changes another player's role, consumes a potion or posts group messages automatically.

## Validation

Use the repository [test checklist](../../../docs/SUPPORT_COVERAGE_TESTING.md). Automated Lua checks are necessary but cannot certify ESO's runtime UI, real frame time or multi-client transport. No PR is authorized until the maintainer completes in-game testing and explicitly requests it.
