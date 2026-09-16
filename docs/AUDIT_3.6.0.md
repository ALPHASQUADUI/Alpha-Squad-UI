# 3.6.0 development audit

This audit separates supplied recording observations, source corrections and remaining client acceptance. No private recording, player roster or raw build data is included. The recording is input to the changes, not a test of the resulting commit.

## Recording observations

| Recording position | Observed concern | Change and required follow-up |
| --- | --- | --- |
| 00:58–02:18 | Group HUD body interactions did not reliably move the panel | Foreground placement body captures the drag; verify rows/icons, overlapping panels and release/cancel paths in ESO |
| 02:39 | Transparent HUD offered background adjustment; French presentation mixed native set names | Hide unsupported opacity controls; use verified ID-based name mappings where available; unresolved native text remains explicit |
| 03:07 | Weapon BACK used the navigation translation; native tooltip remained English | Separate weapon ARRIÈRE semantics from navigation RETOUR; full native tooltips still use client locale |
| 04:08 | Charging text remained untranslated | Add the corresponding French status and exercise live language refresh |
| 04:56 | Game language appeared as a selector option | Offer EN/FR only, with one-time client-language seeding and English fallback |

## Priority corrections

1. **Native coexistence:** remove the complete native Ultimate suppression bridge. Tests trap native control writes/hooks during initialization, options, scene changes, loading and placement; other addons' hidden/native input choices remain untouched.
2. **Shared authority:** native membership and crown determine who assigns the raid leader; only the selected leader changes shared filters. Settings frames use current context, catalog and revision checks. Invalid, stale or unauthorized messages cannot become accepted settings. This is validation of addon messages, not proof against a deliberately modified game client.
3. **Data identity:** group filters match verified support-family slot/morph IDs, not class, translated names or gear. Cryptcanon uses dedicated Ultimate `195031`. Dragonknight Standard's group bonus excludes Shifting Standard and debuff effect IDs; effect identifiers must not be substituted for slotted skills. The [official Update 49 changes](https://forums.elderscrollsonline.com/en/discussion/689473/update-49-live-patch-notes-all-platforms) distinguish base/Standard of Might group support from Shifting Standard.
4. **Food uncertainty:** consume only fresh, verified evidence belonging to the current account/tag/character. Preserve active, absent and unknown. Expiry and detailed-response timestamps cannot be renewed just by rereading or delivering old observations. No additional food scanner or network stream is introduced.
5. **Placement:** use native whole-body movement above child hit areas; retain resize handles and end-of-session cleanup. Hide controls that do not apply to the selected transparent HUD.
6. **Localization:** retain a persistent explicit EN/FR choice, contextual labels and bounded verified native-name mappings. Full ESO tooltips and unmapped game names retain client text. Names, item links and protocol identity are never fabricated to simulate complete translation.
7. **Performance:** replace eighteen arrow scanline children with two native textures; skip hidden stopped-progress writes; reuse cached food and skill facts; coalesce compact settings sends without an idle synchronization heartbeat. Counter-based regressions do not establish an FPS or ping improvement.

## Evidence and limits

Native texture identity follows ESO's [button templates](https://github.com/esoui/esoui/blob/live/esoui/libraries/zo_templates/buttontemplates.xml). The name table contains 709 English/French set IDs from the game-API-generated LibSets API 101050 snapshot dated 2026-05-25; its exact source blob is recorded in `Localization/NativeNames.lua`. A separate subset covers 45 support ability IDs using exact-ID native-tooltip exports, with source URLs beside the table. Unmapped abilities, item names, masteries and full tooltips retain native text. These finite tables add no runtime network request or library dependency and do not claim complete ESO translation.

The raid coordination protocol carries only bounded numeric settings/context fields. Native OFF blocks its send and receive paths, retries are bounded and combat/loading pauses normal sends. Native send failures stop after three attempts and produce an explicit status. LibGroupBroadcast has no public cancellation API for a previously queued frame; a pause may send one additional neutral replacement outside the normal send interval. This revocation is best effort, and receivers must still reject invalid/stale context. No unrelated protocol or sharing consent is changed.

Formal reservation and coexistence for **507/510/511**, real EN/FR font/layout checks, multi-client crown/delegate transitions, installed action-bar addons and measured frame time/traffic remain acceptance work. The recorded 3.4.0 dropdown failure is retained in [client acceptance](CLIENT_ACCEPTANCE.md); no automated result converts it into a native pass. This candidate is authorized for `dev`, without a PR or public release.
