# Support Coverage

Precombat group preparation and visual build inspection for **Ąlpha Şquad UI**.

## Prepare your group

1. Join the group, open **Coverage** and choose **Trial** or **Dungeon**.
2. Turn the effects you need ON. The two contexts retain separate choices.
3. Use **All**, **Missing** or **Duplicates** to focus the single-page grid.
4. Hover an effect name for its full description and conditions. Hover its contributor count for every known provider, the reported skill/set/mastery sources and their bar availability.
5. Click a contributor count to inspect its provider. When several players contribute, choose the player from the compact list. You can also open **Builds** and select any group member. Food and selected potions are part of that character sheet.

**Buffs**, **Debuffs**, **Group Sets** and **Group Mythics** remain distinct. Dense categories receive extra columns; the Coverage page has no scrollbar or pagination. Native effect and item icons are used where the client provides them. Long labels remain readable on hover.

Green means covered, red missing, gold unknown or duplicate, and grey optional. A duplicate count includes **×**. Multiple providers can be intentional: target caps and conditions may require more than one source.

## Read a build

Armor icons form equally spaced pairs around the centered native silhouette, which retains the game's original proportions. Jewelry and the two weapon pairs have their own fixed groups. The complete sheet fits the available display without changing its saved layout. The silhouette is an equipment guide, not a remote 3D character model.

The number beside each set name is the **highest known weapon-bar total**. FRONT and BACK show each bar separately. Shared body/jewelry pieces count on both bars; only that bar's weapons count. Two-handed weapons contribute two pieces while occupying one physical item slot.

For example, three body pieces with a front sword/shield and a back staff from the same set show **5×**, FRONT **5×**, BACK **5×**. The physical six items are not combined into a six-piece active bonus. An actual sixth piece on a bar remains **6×**. When the native set bonuses establish its final threshold, **1 extra piece • front bar** identifies the excess; it is a review hint, not an automatic equipment change. Unknown thresholds never become guessed five-piece rules. A **≥** headline means only a lower bound is known because the other bar is unavailable.

Hover a body or weapon icon for that exact item's trait, enchantment and native description. Native item-tooltip set counters are based on the viewing character; use the inspected build's FRONT/BACK summary for its actual totals. Set-summary icons show an equipped piece when available, otherwise a clearly identified native collection reference or category symbol. A reference does not establish the sender's trait or enchantment; a category symbol is not a picture of an unverified item.

Both weapon bars retain five skills and their actual Ultimate morph. A reported Werewolf bar appears separately. Twelve Champion slots preserve their native discipline artwork and the sender's verified invested points. Hover a star for the corresponding bonus; no unrelated ability picture is substituted. Class Masteries, passives, food, potion, Mundus and supported curse information complete the view.

An empty slot and an unavailable slot are different states. Incomplete snapshots cannot certify equipment totals. Missing transformation or Vampire-stage information stays unknown. Native shared-skill descriptions can use the viewer's stat-dependent values and do not certify the sender's damage or healing.

## Understand coverage

`COVERED` means a qualifying build source is available before combat. A set can qualify on either weapon bar; it need not reach its threshold on both. Casts, range, target caps, synergies and proc conditions still apply. Availability does not prove that an effect is active or reaches every group member.

Class identity alone does not prove purchased passives, selected masteries or slotted skills. A named Major/Minor effect does not stack just because another player supplies it. A selected potion is preparation evidence, not proof of consumption. No role-specific loadout is forced.

There is no pull-report, uptime-history or recorded-build planner workflow. Builds integrates food and potion readiness; there is no separate Food Check menu.

## Sharing and dependencies

Open **Libraries** for dependency status, ESOUI links and all sharing switches. New installations configure supported sharing ON once; existing saved OFF choices are preserved. A switch changes the matching native library setting in place, without opening another addon page. Missing or incompatible libraries remain visibly unavailable rather than pretending to share.

| Sender | Available evidence |
| --- | --- |
| No compatible sender | Native group identity/class and observable effects only |
| LibSetDetection v5+ with LibGroupBroadcast | Disclosed set identities and per-bar counts; not exact items, skills or CP |
| LibGroupCombatStats with its dependencies | Compatible Ultimate identities/resource and supported active class lines; not full builds |
| Full Alpha Squad UI or AlphaSquadBuildShare companion | Supported equipment, separate skills, Champion allocation, mastery and readiness snapshot |

The full build sender needs LibGroupBroadcast and its declared LibAddonMenu-2.0/LibDebugLogger dependencies. LibFoodDrinkBuff optionally improves food identification. Sending clients need the relevant libraries too. Installing a library alone does not provide arbitrary remote inventory inspection. LibSetDetection incognito choices remain respected. Reports received during the same group session survive tracking OFF/ON and loading; leaving, disconnecting or changing identity invalidates them. Polling never turns an old library cache into a fresh report.

Full build transport identifiers are provisional pending formal registration and coexistence validation. Compact summaries are automatic while grouped precombat sharing is enabled. Full details are requested on demand, validated and cached briefly; they are replaced only by a complete accepted snapshot. A reported build remains a statement from its sender, not proof against a modified client.

## Dashboard, placement and persistence

Dashboard controls tracking independently of Libraries sharing. Turning Support Coverage off stops local HUD/coverage work; an enabled grouped sender can still answer valid build requests. Combat and loading suspend build scans/transfers.

Use **MOVE HUD** in the sidebar or `/asmove` outside combat. Move the Support panel, drag its corners to scale proportionally or its edges to reshape the content. The same toolbar controls background opacity, scale and panel reset. Choose **DONE** or Escape to save and lock. Disabled modules stay disabled. Dashboard's three interface styles also apply to Support Coverage windows and HUD controls. Cross-sync shares the current layout/settings across characters on the same account and server; OFF keeps character profiles separate.

**Preview** fills the placement HUD with sample covered, missing, unknown, duplicate and optional sources for twelve fictional players. Ready and Missing isolate those states; Live restores the current group data. Samples exist only during placement and never participate in coverage checks, inspected builds or sharing. Controller focus can open the same detail tooltips and activate the same controls as keyboard and mouse.

Existing `AlphaSquadSupportCoverageSavedVariables` settings are preserved. Remote snapshots are bounded, transient group data. The addon does not change another player's equipment or role, consume a potion or post group messages automatically.

See the [client acceptance matrix](../../../docs/CLIENT_ACCEPTANCE.md), [detailed ESO checklist](../../../docs/SUPPORT_COVERAGE_TESTING.md), [architecture](../../../docs/ARCHITECTURE.md) and [performance notes](../../../docs/PERFORMANCE.md). Automated checks cover deterministic boundaries; native rendering, frame time and multi-client behavior still require in-game validation.
