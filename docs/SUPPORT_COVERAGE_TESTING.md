# ESO acceptance checklist

Version **3.4.1** / **30401**. This checklist is not a record of completed in-game tests. Record current results in the [client acceptance matrix](CLIENT_ACCEPTANCE.md).

## Native Add-Ons menu

- Before login and in game, verify the complete **Ąlpha Şquad UI** title and **@SeRuM1** author, without a cut-off color tag.
- In game, expand the entry: all seven group-feature libraries must appear, with available names green and missing names red with **Missing library**.
- Select another character, disable a library, and enable it again: the status must follow the native filter and checkboxes without modifying them. Also test a missing transitive dependency and an older LibAddonMenu-2.0/LibSetDetection version.
- Collapse/reopen and refresh: no duplicate list, overlap with the next addon, or changes to CombatMetrics or other entries. Re-enable libraries and reload before verifying tracking/sharing.
- With Alpha Squad disabled or not loaded, expect the static library description without custom status colors.

## Automated validation

From the repository root:

```sh
python3 tooling/validate.py
```

The validator runs every regression suite under Lua 5.1 and Lua 5.4, checks syntax and manifest/Core metadata, and builds/validates the full-suite and companion packages. Set `LUA51` and `LUA54` when interpreter executable names differ. Current output supplies the assertion totals; historical release counts are not evidence for this version.

## Client preparation

Use the [installation instructions](../releases/README.md). Record the commit, ESO API version, addon/library versions and relevant screenshots for each finding. Close ESO and back up existing addon folders and SavedVariables before updating. Keep private chats, unrelated accounts and raw group snapshots out of reports.

Check a fresh installation separately from migrated preferences. Fresh supported sharing starts OFF and requires an explicit choice; saved ON/OFF choices must survive installation, reload, character changes and travel. A pre-existing native OFF must not be silently enabled. Verify actual native library switches as well as the Alpha Squad display.

## Settings, sharing and placement

| Check | Required outcome |
| --- | --- |
| Fresh settings | All tracking modules start enabled; supported sharing categories stay OFF until explicitly enabled, including when dependencies are installed later |
| Existing preferences | Saved module, sharing, layout and visibility choices remain intact; an explicit OFF is never reset by routine activation |
| Libraries truth | ON/OFF matches the real native setting; missing/incompatible controls show unavailable, not a guessed ON |
| Sharing switches | Toggle each category in Alpha Squad without navigating away; verify only its matching native settings change |
| External library changes | Change a matching option in the native library settings, return to Alpha Squad and verify the displayed state; reload and confirm it persists |
| Missing dependency | Missing/update states are red; installed valid states are green; installing the dependency allows pending setup without a retry storm |
| Native option identity | Unknown or ambiguous protocol controls fail closed; unrelated settings, set-incognito choices and other addons' callbacks remain untouched |
| Independent tracking | Disable each Dashboard module: its navigation and gameplay HUD disappear; permitted grouped sharing remains available |
| MOVE HUD entry | Open from keyboard Settings, gamepad Settings and `/asmove`: wait for native Settings to finish closing, then show one editor with the normal action bar; repeated clicks create no duplicate or stranded pending request |
| Placement preferences | Disabled modules stay disabled; temporary placement previews do not permanently enable hidden HUDs |
| Placement completion | Done or Back/Escape saves, locks and selects Alpha Squad in native Settings; combat, loading or another game menu ends placement without reopening settings |
| Placement scene changes | Enter and leave cursor mode (`hud`/`hudui`) while arranging panels: placement and its input remain usable; an unrelated game menu cancels active or pending placement |
| Secondary Close/Back | Open Group configuration, Coverage and Builds through settings and through each other; X/CLOSE and keyboard/controller Back restore the preceding addon window, without leaving a blank native Settings category |
| Navigation cleanup | Combat, loading and forced scene cleanup must not reopen a prior addon window; repeated Coverage/Builds round trips do not accumulate duplicate history |
| Empty group placement | Group HUD can be positioned with no matching players without inventing actual group evidence |
| Cross-sync ON | Move panels and change settings, then reload and change character on the same account/server: positions/settings remain shared |
| Cross-sync OFF | Two character profiles remain separate; switching mode keeps the active layout without requiring reload |
| Unified Ultimate migration | Both weapon slots remain visible; retired AUTO/FRONT/BACK/BOTH selectors do not return through profile migration; supported Overload options and applicable legacy placement migrate into the one personal HUD |
| Active bar and Overload | The verified active weapon slot has a green left-side marker; the inactive slot is dimmed; toggling specialized Overload behavior OFF restores normal status without a second panel |
| Dual-slot layout | Both slots remain visible with an Overload morph; the saved horizontal/vertical layout remains stable while resizing |
| Independent shell | Main settings, Libraries and About remain usable with every gameplay module disabled |
| Theme selection | Ember Classic, Tactical Compact and default Obsidian Studio repaint settings surfaces immediately, preserve status/quality/discipline colors, and survive reload/profile changes; gameplay HUDs stay neutral and Ultimate HUDs transparent; the open dropdown has an opaque backdrop and readable options |
| Dashboard dropdown ownership | Reload with both theme and language selectors present, alternate their menus and selections, then reopen settings; no duplicate BG/Scroll errors, crossed menu entries or changes to unrelated native menus |
| Resize corners | Drag every corner proportionally with icons/text intact; release, Escape, combat and loading remove temporary resize callbacks |
| Resize edges | Edge drags reshape personal/group/Support HUD contents without stretching icons; minimum/maximum bounds and screen fitting remain correct |
| Placement toolbar | Selected-panel scale/background opacity/reset/fit affect only that panel; icons/text stay opaque and all changes persist |
| Branding | Ą and Ş render fully in the static orange gradient; UI stays white; @SeRuM1 uses the blue gradient |
| External links | Website, ESOUI, Minion and Discord confirmations appear above addon windows and can be accepted or cancelled normally; About's JOIN DISCORD opens the direct verified invitation, without an intermediate page or build data |
| Viewport | At 720p, 1080p and ultrawide UI scales, Libraries remains usable, the main Close action returns to gameplay, Workspace labels remain readable, and long detail text remains available on hover |
| Continuous resizing | Repeatedly drag all corners and edges through their range; no sudden half-size change, cumulative shrinking or opposite-edge jump; unchanged pointer positions do not redraw contents |
| Display transitions | Change fullscreen/windowed/borderless, custom keyboard/gamepad UI scale and viewport dimensions; fitting preserves saved requested sizes/positions and the active drag ends before coordinates change |
| Preview states | Mixed, ready, missing/charging, Overload and live choices repaint immediately; Group examples contain 12 fictional accounts; changing modes never changes live roster, transport or build snapshots |
| Gamepad entry | Open the addon through gamepad Settings; the native options scene closes before the addon window appears |
| Navigation | Arrows, Tab/Shift+Tab, directional controller input, Select and Back reach all visible settings, filters, roster entries and hover-only detail icons; disabled and hidden controls are skipped |
| Controller placement | Secondary action cycles Move/Scale/Width/Height/Controls, shoulders select panels, and held directional input adjusts smoothly; orientation and preview controls remain reachable |
| Input ownership | Native URL/dialog confirmation receives input without interference; close, loading, combat and menu changes release the addon layer and restore normal gameplay controls |

## Builds and Coverage

| Check | Required outcome |
| --- | --- |
| Trial/Dungeon | Separate ON/OFF choices persist; disabled effects stop contributing to that context |
| Complete Coverage page | Every catalog entry fits under Buffs, Debuffs, Group Sets or Group Mythics without scrolling or pagination; no tile/column/footer overlap |
| Filters | All, Missing and Duplicates preserve their correct entries; stale pooled controls are hidden |
| Contributor hover | Every known duplicate account and its exact source names/bar availability remain readable; a count opens the named build |
| Effect hover | Full names, conditions, source alternatives and duplicate rules remain available without raw-ID clutter |
| Set icons | Actual equipped pieces or clearly labelled native collection references are used; references never imply the sender's trait/enchantment |
| Equipment layout | Native silhouette stays centered and proportionate; paired armor columns have equal distances and row spacing; jewelry/front/back weapon groups retain their positions |
| Set headline | Three body pieces + front sword/shield + back staff from one set show 5×, with FRONT 5× and BACK 5×, despite six physical items |
| Native excess warning | A genuine sixth piece remains 6× with an appropriate one-extra-piece warning; monster, arena, mythic and shorter sets use their actual native bonus thresholds |
| Unknown threshold | Missing native bonus requirements or incomplete equipment never manufacture a five-piece rule, exact total or excess warning |
| One-bar qualification | A qualifying front-only or back-only source counts; partial pieces do not falsely reach its requirement |
| Two-handed and Perfected | Weapon weights and shared normal/Perfected set families match actual equipped links on both bars |
| Exact item tooltip | Compare every slot with its native inventory link: item name, quality, trait, enchantment and missing glyph; repeat after item changes and player selection |
| Viewer-dependent counters | Native item-tooltip set counters are identified as viewer-based; the inspected build's FRONT/BACK summary remains authoritative for its reported equipment |
| Skills and Ultimates | Each bar has the exact slotted skills and Ultimate morph, including subclassed skills; gaps never shift abilities into another slot |
| Champion artwork | Use native discipline stars, the correct slotted identity and the sender's invested points/bonus; no stray zero or unrelated ability icon |
| Champion sources | Verified native CP identity and committed points qualify; translated names alone cannot substitute another star or an empty slot |
| Masteries/passives | Only supported committed eligible selections qualify; class identity alone cannot fill missing evidence |
| Transformations | Normal bars remain separate from a reported Werewolf bar; Vampire/Werewolf/stage indicators reflect only verified fields |
| Food and potion | Known food absence differs from unknown; empty/non-potion quickslots are not invented potions; no separate Food Check page |
| Tooltip foreground | Item, skill, CP, set and contributor tooltips remain above every addon window, clamp to screen and restore native state when closed |

## Transport, lifecycle and resources

| Check | Required outcome |
| --- | --- |
| Native-only peer | Available identity/class/observable effects remain usable; unsupported gear, CP and masteries stay unknown |
| Full-suite sender | Matching clients with dependencies and sharing ON exchange supported details before combat |
| Companion sender | The lightweight companion supplies the compatible format without the suite; new ON, saved OFF and full-suite precedence behave correctly |
| LibSetDetection peer | Disclosed v5 set/per-bar reports qualify without the full suite; incognito, report age and reconnect invalidation remain correct |
| LibGroupCombatStats peer | Fresh Ultimate/active-line facts remain limited to their scope; class lines never imply purchased passives or masteries |
| Unchanged library report | Keep a valid LibGroupCombatStats report unchanged beyond 75 seconds: Builds does not blank it solely due to age; disconnect, identity change and invalid native timestamps still remove actionable facts |
| Native library OFF | Subsequent matching sends are blocked; other shared protocols/callbacks remain intact; acknowledge the library-owned timer may persist until reload |
| Malformed data | Invalid sizes, field values, slots, identities, duplicates or contradictory set totals cannot certify a complete build or overwrite accepted evidence |
| Partial/stale data | Delayed chunks, changed build fingerprints, incomplete senders and stale records never mix old gear into a new complete snapshot |
| Group lifecycle | Late join, leave/rejoin, disband, reconnect and character change invalidate inappropriate cached state |
| Combat | No Support scan or detailed build send during combat; queued invalidation is handled after combat ends; no uptime/report sampler appears |
| Loading/travel | Overland, housing, dungeon, trial and PvP transitions pause local work during loading, then resume without changing preferences |
| Personal ULT | Both weapon slots, active marker, inactive dimming, swap, spend, ready sound/pulse, hide/disable, shared Overload behavior and saved geometry remain functional |
| Group ULT controls | The parent Group tracking switch controls the teammate HUD; no group self/HUD-visibility/ready-sound switches or sound behavior remain; saved filters/layout survive and a formerly hidden group HUD migrates to OFF |
| Group ULT values | Filters, readiness sorting, dead/offline players, rejoin and missing-library states remain correct; the local account never appears, repeated same-ID Ultimates use the lower valid cost, changed IDs discard stale cost and percentages stay below 100 until ready |
| Personal transformation ULT | Test Vampire and Werewolf forms and other special native hotbars: show the active native Ultimate/morph/icon/cost, use available native effect duration for ACTIVE, then restore ordinary front/back state after the form ends |
| Group transformation ULT | Accept the actual transformation Ultimate reported by LibGroupCombatStats without a fixed whitelist; do not infer transformed-bar slots or another player's active form from a front/back report |
| Overload | All morphs, optional behavior OFF, Warning starts, reserve/reminder behavior and PvP suppression remain functional in the shared personal tracker; no effect-cancellation action or cutoff setting remains, and hidden/loading/placement states play no alerts |
| Resize bursts | Repeated screen-size notifications coalesce into one deferred Support refresh using current dimensions; no repeated follow-up refreshes remain after the burst ends |
| Performance/coexistence | Compare frame time/memory and traffic ON/OFF in four- and twelve-player groups alongside the group's existing addons |

## Release requirements and references

Source availability is not live application or guaranteed recipient coverage. A valid shared snapshot is still a report from its sender; it is not proof against a modified client. Automated checks cannot certify native rendering, measured FPS or network coexistence. The 3.1.0 recording documents the reported failures; it is not an after-change acceptance test. See the [3.2.0 video review](VIDEO_REVIEW_3.2.0.md).

The active build protocols **507/510** remain provisional; legacy **508/509** are retired. Formal reservation and coexistence validation remain required before public full-build-sharing release. Completing this checklist does not itself authorize a pull request, merge, tag or release; maintainer approval remains required.

Primary API and implementation references:

- [ESO native UI source](https://github.com/esoui/esoui)
- [ESO skill/mastery data](https://github.com/esoui/esoui/blob/live/esoui/ingame/skills/playerskillsdata.lua)
- [ESO Champion data](https://github.com/esoui/esoui/blob/live/esoui/ingame/champion/championdatamanager.lua), [action bar](https://github.com/esoui/esoui/blob/live/esoui/ingame/champion/championassignableactionbar.lua) and [star renderer](https://github.com/esoui/esoui/blob/live/esoui/ingame/champion/championstarvisuals.lua)
- [LibSetDetection author source](https://github.com/exoy94/LibSetDetection)
- [LibGroupCombatStats author source](https://github.com/m00nyONE/LibGroupCombatStats)
- [LibGroupBroadcast author source](https://github.com/sirinsidiator/ESO-LibGroupBroadcast)
- [Native texture names](https://github.com/esoui/esoui/blob/live/esoui/publicallingames/globals/sharedtextures.lua) and [effect identities](https://github.com/DakJaniels/LuiExtended/blob/master/LuiData/Effects/BarHighlight/MajorMinor.lua)

These references describe contracts and resources, not completed in-game acceptance results.

## 3.4.1 interface acceptance

The maintainer reported duplicate native `BG` / `Scroll` initialization errors in 3.4.0. The 3.4.1 dropdown fix awaits native retesting; the failed 3.4.0 run does not establish any of the outcomes below.

- Install 3.4.1, reload and open Dashboard with both theme and language selectors present. Open each menu repeatedly, alternate selections, close/reopen settings and reload again. No duplicate-control errors, crossed menu entries or stale translations; popup fills remain opaque and unrelated native menus retain their appearance.
- Start a fresh English client and French client: Automatic selects the matching addon language. Other client locales fall back to English. Switch EN/FR/Automatic without reload on every page and already-open window; reconnect and change character to verify persistence. Native names/tooltips remain in ESO's client language.
- Test 720p, 1080p and the actual custom UI scale. Inspect long French buttons, dropdowns, tooltips, contributor details and narrow Builds/Coverage layouts. No overlapped actions or clipped essential status.
- Personal ULT: verify both slots in both orientations, left-side green marker through rapid weapon swaps, dimmed inactive slot, distinct costs, empty slot, unknown cost, transformation/temporary hotbar and recovery. No stale READY after spending.
- Overload: verify gold active, green ready pulse and red reserve warning; check toggling behavior, combat, hiding and editor previews. The addon must never activate/cancel a skill.
- Each module's Move HUD action opens placement; orientation icon is beside the intended HUD. Done and Escape select Alpha Squad in native Settings. Main Close returns gameplay. Combat/loading/different native menus dismiss without reopening settings.
- Compare quiet solo, four-player and twelve-player frame time/memory before and after. Hidden/disabled HUDs stop presentation work. Verify no sharing changes when switching language, theme or visibility.

These checks remain unrecorded until performed in ESO against the exact development commit.
