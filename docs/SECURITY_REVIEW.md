# Data and runtime security review

This review covers the native build scanner, binary build records, LibGroupBroadcast adapters, sharing preferences, transient peer state and the optional companion. Automated checks exercise both Lua 5.1 and Lua 5.4. They do not attest another player's equipment or replace multiplayer testing in the current game client.

## Trust boundaries

| Boundary | Behavior |
| --- | --- |
| Native group identity | Receivers resolve the sender through current group unit tags and native account names. A packet cannot choose its own sender. Departed members are removed from pending transfers and caches. |
| Shared build claims | Items, skills and allocations are reported by the other player's addon. Native lookups validate their format and meaning; the game does not independently confirm that the sender equipped them. |
| Binary payload | Names, tooltip markup, URLs, texture paths and executable code are not accepted from build packets. Item links are reconstructed from bounded numeric fields. The receiving client resolves labels, traits, enchantments and icons. |
| Broadcast visibility | LibGroupBroadcast uses the native group broadcast channel. Addressing a request controls which client answers and which inspector accepts the response; it does not encrypt the response against other group members. |
| Checksum | Checksums detect incomplete or mismatched transfers. They are not signatures, cryptographic authentication or proof that a reported build is truthful. |
| Persistence | Peer snapshots remain in memory. The addon does not save shared builds as historical reports or send them to its website, Discord or other external endpoints. |

## Validated data boundaries

- A build body is limited to 3,584 bytes. A detail frame contains at most 64 bytes, with no more than 64 fragments of 56 build bytes. Only one incoming and one outgoing transfer are retained at a time.
- Integers must be finite and within their field bounds. Unsupported schemas, truncated data, trailing bytes, duplicate equipment positions, duplicate Champion slots and malformed item links are rejected.
- Equipment completeness requires all native positions, readable set identity and set totals that agree with the linked items. Front and back weapon bars remain separate; a two-handed weapon contributes two set pieces on its bar. A native item that cannot occupy its reported slot cannot establish complete equipment evidence.
- Skills use assignable ability slots. Scribing records require matching grimoire identity; verified combinations contain three distinct scripts in their native order. Ordinary abilities and Ultimate slots cannot carry fabricated Scribing records. Unreadable effective abilities leave the bar unknown.
- Champion records cannot repeat one star in multiple slots. Available native discipline mappings and maximum allocations are checked against the transmitted slot and invested points. Remote descriptions use the transmitted allocation, never the viewer's allocation.
- Duplicate mastery, class-line and passive records are rejected. Known potion and poison claims must agree with their native item types when those types can be resolved.
- IDs that exceed compact summary field sizes become unknown instead of being clamped to another valid class or food identifier.

These checks prevent contradictory records from becoming trusted coverage evidence. They cannot prevent a modified sender from claiming a plausible build that it does not actually wear. Summary-only capability hints remain distinct from complete shared build details.

## Transfers, expiry and consent

Requests bind a current sender, recipient, revision and checksum. Unexpected, reordered and repeated chunks cannot advance a transfer. An acknowledgment advances only the next expected fragment, with at least 1.2 seconds between response fragments. Native capture attempts have a 20-second cooldown, including failed attempts. Inactive transfers expire after 20 seconds and all transfers have a 180-second total lifetime. Watchdogs follow progress even after Builds closes. A single compatible request retry does not trigger an extra scan; a late acknowledgment or fragment cannot revive an expired transfer.

Summaries become stale after 75 seconds. Complete captures expire after 120 seconds, including when a later summary repeats the same fingerprint. Expired captures fall back to the available summary evidence. Abandoned peer snapshots are evicted after 120 seconds even when group membership is unchanged.

Libraries controls govern sharing independently of Dashboard tracking. Fresh categories start OFF until explicitly enabled. Existing saved choices and native OFF states are preserved; unknown native state never starts an Ultimate sender. An unsuccessful paired activation rolls back; a partial deactivation retains every successful OFF instead of re-enabling a protocol. Missing, ambiguous or incompatible native controls are reported as unavailable; discovery never opens a library panel, reads closure upvalues or changes unrelated protocols. Reentrant options callbacks cannot recurse through the discovery hook. Native setting failures stop new local sends without an unhandled Lua error.

Both installations use the same native sharing bridge. OFF stops new captures, cancels local transfers and replaces queued frames for protocols 507/510 with empty, unsupported-version frames through LibGroupBroadcast's public per-message replacement option before disabling those native protocols. This also replaces partially transmitted queued messages, so an immediate OFF/ON cannot resume an old private fragment. Unrelated protocols remain untouched. Data already broadcast cannot be recalled.

Combat, loading and group transitions revoke only the owned pending frames. If revocation fails, the bridge attempts to disable both owned native protocols. After recovery, an explicit ON is required, including after a reload; the bridge does not automatically restore a setting that another interface may have turned OFF. A quick solo ON cannot reactivate unrevoked data. If queue replacement and native deactivation both fail, already queued traffic cannot be reliably revoked through the supported API: status reports the failure and asks for a UI reload. Status follows the actual native settings and clears a resolved control error; it does not report a successful OFF merely because the local sender stopped.

Protocols 507 and 510 remain provisional. Conflict handling prevents repeated declarations, but stable public transport still requires reserved IDs and coexistence checks with other installed libraries.

## Runtime and resource use

Both the full addon and the companion wait for `EVENT_PLAYER_ACTIVATED` before scanning initial equipment. Loading and combat pause captures and local detail traffic. Build changes during combat remain dirty and are captured after combat. Disabling tracking preserves only the sender work authorized in Libraries.

The companion coalesces equipment, skill and Champion changes into one delayed capture. Food, boon and quickslot updates refresh readiness without rescanning every equipment piece and skill; unchanged heartbeats reuse the captured build. It has no solo heartbeat, combat-log sampler or per-frame scan. Callback generations invalidate delayed captures on loading, opt-out and group reset.

Support Coverage also coalesces native screen-resize notifications into one pending UI pass. A burst of window-size changes cannot queue a separate HUD and inspector rebuild for every intermediate size; the pass reads the current viewport when it runs.

The subsequent video-driven review rechecked payload loops and allocations, sender resolution, transfer cancellation, native sharing controls and companion lifecycle gates. It found no additional injection or external data-transfer path in those reviewed components. This is a scoped review result, not a guarantee that the addon or its dependencies contain no vulnerabilities.

## Verification and remaining client checks

Regression suites include `build_codec.lua`, `build_sharing.lua`, `scanner_details.lua`, `source_roundtrip.lua`, `sharing_controls.lua`, `support_coverage.lua` and `companion_package.lua`. They cover malformed records, exact item-link preservation, native slot checks, stale data, offline identity, conflicting registration, partial transfers, late packets, queue revocation, consent, loading and scan coalescing. Package validation runs the shipped suite and companion sources after extraction from their installable ZIPs. An additional review against the referenced LibGroupBroadcast queue implementation checked synchronous replacement of whole/partial frames and preservation of unrelated traffic.

Real-client checks still need to cover native item and script lookups, current library versions, lossy group broadcasts, sharing OFF during queued transfers, combat/loading transitions, and CPU/frame-time behavior in a full group. No synthetic test establishes zero resource cost or compatibility with unreleased game APIs.

## Primary references

- [Native ESO API documentation](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/ESOUIDocumentation.txt): equipment-link, action-slot, Champion and Scribing contracts.
- [Native equipment-slot map](https://github.com/esoui/esoui/blob/f76cf16c4e5be7b234d15dc7f676febffa64c5bb/esoui/publicallingames/character/character_utils.lua): `ZO_Character_DoesEquipSlotUseEquipType`.
- [LibGroupBroadcast native event adapter](https://github.com/sirinsidiator/ESO-LibGroupBroadcast/blob/e8382891d63677b0ad8b77a79d5295b93062cc58/src/GameApiWrapper.lua): sender tags originate from the native broadcast event.
- [LibGroupBroadcast settings](https://github.com/sirinsidiator/ESO-LibGroupBroadcast/blob/e8382891d63677b0ad8b77a79d5295b93062cc58/src/settings/SettingsPanel.lua) and [broadcast queue](https://github.com/sirinsidiator/ESO-LibGroupBroadcast/blob/e8382891d63677b0ad8b77a79d5295b93062cc58/src/BroadcastManager.lua): native Allow Sending callbacks and checks before transmission.
- [LibGroupCombatStats implementation](https://github.com/m00nyONE/LibGroupCombatStats/blob/c88f69f7d5b970127dd9355377cad22dd1cc9ac5/LibGroupCombatStats.lua): independent Ultimate consumer registration and native-library freshness timestamps.

## Distribution boundary

The 3.3.1 package gate checks an explicit source inventory and scans final archive content. Ignored local logs, backups and SavedVariables are not distributable assets. Metadata validation checks approved public names and matching noreply identities, plus the explicitly authorized project mailbox `info@alphasquadeso.com` for the maintainer's public aliases. Other mailboxes on that domain remain subject to the privacy gate. The check does not rewrite existing history or assert that remote account protections are configured. New-branch comparisons use an available trusted main anchor when possible.

The release policy defaults to publication disabled. A public release requires a separate manual main-based operation, recorded native/transport prerequisites and an administrator-configured release environment. Development pushes and pull requests only validate.
