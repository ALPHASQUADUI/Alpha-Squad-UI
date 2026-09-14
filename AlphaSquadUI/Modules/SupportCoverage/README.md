# Support Coverage

Precombat group support checks for **Ąlpha Şquad UI**, version **2.8.0** (`20800`).

## Workflow

1. Group with the players you want to check.
2. Open Support Coverage and choose **Trial** or **Dungeon**.
3. Turn the relevant effects **ON/OFF**. Filter the list by **ALL**, **MISSING** or **DUPLICATES**. Hover an effect's information icon for its description, known sources and conditions.
4. Review known providers, missing coverage and duplicates. Hover `@UserID` to inspect the identified skill/set/mastery source.
5. Open **Builds** and choose a player. The compact character view shows armor at its body position, jewelry, both weapon bars, skill/Ultimate icons and Champion stars. Hover an icon for details. Use **REFRESH BUILD** to request a new snapshot.
6. Review food and selected potions in **Builds**.

A source counted on one weapon bar can cover its catalog entry even if it is absent from the other bar. Thresholds still apply: two-handed weapons count as two pieces, and one item from a five-piece set is insufficient.

## Reading a build

The selected account stays visible while you inspect the snapshot. Equipment icons are arranged by body slot around a silhouette, with accessories and the two weapon bars in their own groups. The silhouette identifies slots; it is not a remote 3D character preview.

Set summaries show the physical item count beside each readable set name, with separate bonus-piece counts for the front and back bars. A two-handed weapon occupies one equipped-item slot but contributes two bonus pieces. The view does not add the two bars together to manufacture an active five-piece bonus.

Each normal weapon bar shows five skills and its Ultimate, with a separate Werewolf row when available. Skill icons and tooltips use the identified ability, including its morph. Champion icons preserve four slotted-star positions per discipline. Supported food, potion, Mundus, curse, passive and mastery details remain available without opening a separate report.

Hover an equipment icon for the corresponding item, trait and enchantment. Native item-link descriptions keep the trait and glyph associated with the same item. Their built-in set counters use the viewing player's equipment; the inspected player's own totals are in the **FRONT / BACK** set summary. Skill descriptions come from the identified ability; the receiving client's tooltip cannot certify a remote player's stat-scaled damage or healing values. All these tooltips appear above addon windows.

An empty slot and an unavailable slot are different states. Missing or stale remote evidence does not become a made-up icon, trait, enchantment or successful readiness check. Werewolf/Vampire information is shown only where the snapshot establishes it; an unavailable transformed bar does not replace the normal front/back bars. Vampire stage remains unspecified when no verified stage information is available.

## Meaning of coverage

`COVERED` describes available build evidence, not live effect application. It does not guarantee an effect is active, that its proc condition will be met, that a target is in range or that all twelve players can receive it. Source tooltips explain these limits where known.

A duplicate means multiple identified providers, not automatically a bad build. Two limited-target sources may be intentional. Sources contributing the same named Major/Minor effect do not imply that effect stacks. A known equipped group set is distinct from an observed active buff.

Unverified, unsupported, stale and incomplete fields remain `UNKNOWN`. Class identity alone does not prove purchased passives, selected masteries or slotted abilities. Selected potion details do not prove the potion was consumed. No role-specific loadout is forced.

## Build evidence

The local scanner reads equipment links/sets, separate front/back bars, Champion slottables, committed Class Masteries and prerequisites, glyph information, food, selected potion and other available local readiness fields.

Peer details require a compatible sender. Native grouping alone does not provide remote gear, full skill bars, CP or mastery selections. LibGroupCombatStats supplies compatible Ultimate identities and supported active class-line data, not complete skill/passive/CP/mastery inspection. LibSetDetection v5 optionally supplies shared set identities and per-bar activation without requiring Alpha Squad on the sender; hidden or unavailable sets remain unknown.

A sender may use the full **Ąlpha Şquad UI** or the lightweight **AlphaSquadBuildShare** companion. Both need LibGroupBroadcast plus its required LibAddonMenu-2.0 and LibDebugLogger dependencies for the compatible build protocol. LibFoodDrinkBuff optionally improves food-buff identification on supported player/group units; missing remote observations still do not prove absence. Install the relevant libraries on the sending clients as well as the receiver.

## Dependencies and sharing

Open **Libraries** for status and setup. Library installation does not by itself publish a build. For full build details, each participant must explicitly enable a compatible sender, join the group and opt into build sharing. In the full suite, enable **Share equipped build** in Libraries. LibSetDetection set sharing uses the **Share equipped sets** switch in Libraries and does not require enabling Alpha Squad's full-build protocol. Missing or incompatible senders leave remote fields unknown.

Full build sharing defaults OFF. Provisional protocol IDs require formal reservation and coexistence validation before a public sharing release. Use compatible versions and do not claim support for arbitrary unrelated addons' equipment protocols.

Compact capability summaries are automatic while compatible precombat sharing is enabled. Detailed builds are requested on demand; a valid response is cached for 120 seconds and invalidated when the advertised build changes. Transfer delays do not justify guessing missing details.

The build viewer displays names and available details; internal identities are implementation details. Delayed snapshots must not be blended with an old build to invent a complete current loadout.

## Scope and persistence

This version removes pull reports, live uptime, combat history and recorded-loadout planning from the active Support Coverage workflow. Checks are useful before combat; they do not need a pull to populate shared builds.

Supported UI and effect preferences remain persistent in `AlphaSquadSupportCoverageSavedVariables`. Remote build snapshots are bounded transient group data. The addon never equips items, changes another player's role, consumes a potion or posts group messages automatically.

## Validation

Use the repository [test checklist](../../../docs/SUPPORT_COVERAGE_TESTING.md). Automated Lua checks are necessary but cannot certify ESO's runtime UI, real frame time or multi-client transport. No PR is authorized until the maintainer completes in-game testing and explicitly requests it.

## Dashboard and visual coverage

Dashboard controls tracking; Libraries controls sharing. Turning tracking off unregisters module gameplay work while a grouped, opted-in sender can still answer build requests. Cross-sync preserves the current layout and supports native character profiles.

Coverage uses four compact columns with native effect/set icons, provider buttons and source explanations. Builds shows every equipped set with independent front/back counts. CP slots use ESO's native discipline star renderer as a static image, with the sender's invested points on hover. The food/potion summary is part of Builds, with group food status on the player list.
