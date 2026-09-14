# Ąlpha Şquad UI

A modular **The Elder Scrolls Online** addon by **@SeRuM1** for group preparation, visual build inspection and Ultimate tracking.

[Website](https://alphasquadeso.com/) · [Releases](https://github.com/ALPHASQUADUI/Alpha-Squad-UI/releases) · [Changelog](CHANGELOG.md) · [Downloads and installation](releases/README.md)

## Get started

1. Install the `AlphaSquadUI` folder in ESO's `live/AddOns` directory and enable it in the Add-Ons menu.
2. Open **Settings → Ąlpha Şquad UI**, or use `/asoverload`.
3. All tracking modules start enabled. In **Dashboard**, switch off any module you do not need. Its navigation entry and tracking work stop.
4. Open **Libraries** to check dependencies and sharing. New installations configure supported sharing **ON** automatically; saved OFF choices are preserved.
5. Use **MOVE HUD** at the bottom of the sidebar, drag your panels, then click **DONE** or press Escape.
6. Open **Support Coverage → Builds** or **Coverage** to prepare your group.

Use [Minion](https://minion.mmoui.com/) to install and update published ESO addons and libraries. Install the full suite or the lightweight Build Share companion according to the features you need; do not nest either folder inside another addon directory.

## Dashboard and Cross-sync

**Overload**, **ULT Tracker** and **Support Coverage** have independent module switches. Turning a module off removes its gameplay subscriptions, recovery updates and visual work. **Libraries stays accessible**, and its sharing choices are independent of module switches.

**Cross-sync ON** saves module preferences and HUD positions across characters on the same account and server. **OFF** gives the current character its own settings. Switching keeps the current layout, requires no reload, and preserves the existing SavedVariables namespaces. Sharing choices remain account-wide.

## Arrange your HUD

Click **MOVE HUD** in the settings sidebar or enter `/asmove` outside combat. Settings close and the normal game view remains visible, including the action bar and other gameplay interfaces. Drag the enabled panels into place. **DONE** or Escape saves the positions and locks the panels. The placement view ends automatically when combat, loading or another menu begins.

Placement never enables a module you disabled in Dashboard. Temporarily shown placement panels do not change your normal visibility preferences. When an enabled, applicable Overload panel handles a slotted Overload morph, the personal ULT panel stays hidden to avoid duplicate displays; group Ultimate tracking remains independent.

## Builds

Choose a group member to see a compact character sheet:

- Native character silhouette with armor, jewelry and front/back weapon slots.
- Exact item links: hover a piece for its trait, enchantment and native item description.
- Every equipped set, with the highest known bar total beside its name and exact **FRONT / BACK** counts. A two-handed weapon contributes two pieces. Three body pieces, a front sword/shield and a back staff from the same set display **5×**, with **5× / 5×** on the bars.
- An extra-piece warning when a verified bar total exceeds the set's final native bonus requirement. A genuine six-piece total stays **6×**; unknown set requirements do not produce a guessed warning. A **≥** headline identifies a lower bound when only one bar is known.
- Five skills and the exact Ultimate morph on each weapon bar, with a separate Werewolf bar when available.
- Twelve Champion slots, native discipline stars, invested points and the inspected player's corresponding bonus.
- Class Masteries, learned class passives, food, selected potion, Mundus and supported curse information.

The Champion interface uses ESO's own discipline artwork. The game does not provide a unique skill picture for each Champion star. Set icons come from actual equipment or the native set collection; a collection reference is clearly distinguished from a player's equipped item.

Tooltips appear above addon windows. For a shared skill, stat-dependent preview values use the viewer's character; equipment identity and the sender's CP allocation remain separate. **Unknown** means data is unavailable or incomplete; it never means confirmed absence.

## Coverage

Choose **Trial** or **Dungeon**, then review **Buffs**, **Debuffs**, **Group Sets** and **Group Mythics** on one page. Larger categories use multiple compact columns, with no scrolling or pagination. Each effect has a native icon where available, an ON/OFF switch, a status color and a contributor count. **All**, **Missing** and **Duplicates** filter the page.

Hover an effect name for its full description, sources and conditions. Hover its contributor count for **every known provider**, their exact reported source names and bar availability. A duplicate shows **×** beside the count. Clicking the count opens the named contributor's build; select any other group member from the Builds roster. Green means covered, red missing, gold unknown or duplicate, and grey optional.

Coverage means a qualifying build source is available before combat. Range, target caps, casts and proc conditions still apply. The addon does not claim that an effect is currently active, and it does not collect pull reports or uptime history. Food and potion checks are integrated into Builds.

## Libraries and sharing

Install libraries as separate addon folders and enable their declared dependencies. **Libraries** shows green installed states, red missing/update states, ESOUI links and all sharing controls on one page.

| Library | Purpose | Required setup |
| --- | --- | --- |
| [LibGroupBroadcast](https://www.esoui.com/downloads/info1337-LibGroupBroadcast.html) | Compatible full-build exchange | Install with LibAddonMenu-2.0 38+ and LibDebugLogger. **Share equipped build** starts ON on new installations; participating clients need a compatible sender. |
| [LibGroupCombatStats](https://www.esoui.com/downloads/info4024-LibGroupCombatStats.html) | Group Ultimate data | Install with LibCombat and LibGroupBroadcast. **Share group Ultimates** controls its matching library protocols. |
| [LibSetDetection v5+](https://www.esoui.com/downloads/info3338-LibSetDetection.html) | Shared sets and per-bar counts | Install on both ends with LibGroupBroadcast. **Share equipped sets** controls its matching protocol; existing incognito choices are respected. |
| [LibFoodDrinkBuff](https://www.esoui.com/downloads/info1902-LibFoodDrinkBuff.html) | Recognition of observable food/drink effects | Install and enable. No additional setup is needed. |
| [LibCombat](https://www.esoui.com/downloads/info2528-LibCombat.html) | Dependency of LibGroupCombatStats | Install and enable. Alpha Squad does not request DPS/HPS streams. |
| [LibAddonMenu-2.0](https://www.esoui.com/downloads/info7-LibAddonMenu-2.0.html) | Library settings | Version 38 or newer for LibGroupBroadcast. |
| [LibDebugLogger](https://www.esoui.com/downloads/info2275-LibDebugLogger.html) | Dependency of LibGroupBroadcast | Install and enable; normal use needs no extra logging configuration. |

Fresh installations configure **Share equipped build**, **Share group Ultimates** and **Share equipped sets** ON once, when their required libraries are available. Existing saved ON/OFF choices take priority. A missing dependency remains visibly unavailable; installing it and reloading allows pending setup to finish.

The displayed switch follows the actual matching library setting. Clicking ON/OFF updates that setting directly and keeps you on the Alpha Squad Libraries page. Later changes made in either interface are respected. Module switches and Cross-sync do not revoke or reset sharing.

Full build transport identifiers remain provisional pending formal registration and coexistence validation. Build details are requested on demand, validated and retained briefly in memory. Build sharing pauses during combat and loading; group and identity changes invalidate inappropriate data.

The library switches use verified native settings controls for their matching protocols. Other addons using the same library protocols follow those settings; unrelated protocols and incognito choices are untouched. Unsupported library versions show an unavailable state instead of a false ON or opening another settings page. LibGroupCombatStats may keep its own shared timer until reload after sending is disabled; Alpha Squad does not remove another library's event registrations.

ESOUI, website and Minion links use ESO's native confirmation dialog, which appears in front of addon windows. Clicking a sharing switch never opens a link or another addon's page.

### What can other players share?

| Sender setup | Available information |
| --- | --- |
| No compatible sender | Native group identity, class and observable effects only; no general remote inventory inspection |
| LibSetDetection | Disclosed sets and front/back counts; no exact items, traits, glyphs, CP or skill bars |
| LibGroupCombatStats | Shared Ultimates and supported active class-line information; no full-build inspection |
| Alpha Squad UI with sharing enabled | Supported equipment, skills, Champion allocation, masteries and readiness snapshot |
| **AlphaSquadBuildShare** companion | The same supported build format without installing the tracking UI suite |

The companion needs LibGroupBroadcast. Use `/asbuildshare on`, `/asbuildshare off` and `/asbuildshare status`. It starts ON on a new installation, preserves an existing OFF setting and yields to the full suite when both are installed. Installing a transport library alone cannot expose another player's complete build.

## Ultimate modules

**Overload** follows the actual Sorcerer Overload morph and provides reserve warnings, optional safe cancellation and a ready reminder. Automatic cancellation uses `CancelBuff` only when ESO marks the effect as removable; it never simulates a protected key press.

**ULT Tracker** reads the actual Ultimates on both weapon bars. The group view lets you choose abilities to follow, sorts ready players first and dims recent spends. Tracking and library sharing have independent lifecycles. The personal view yields to Overload when its dedicated panel is handling the slotted morph, then resumes when that condition ends.

## Commands

| Command | Opens or controls |
| --- | --- |
| `/asoverload` | Main settings and Dashboard |
| `/asult` | ULT settings |
| `/asult group` | Group Ultimate configuration |
| `/assupport builds` | Group build inspection |
| `/assupport matrix` | Coverage columns |
| `/assupport trial` or `/assupport dungeon` | Coverage context |
| `/asmove` | Arrange all enabled HUD panels; Done or Escape saves and locks |

Shared snapshots are bounded reports from compatible senders, not proof against a modified client. Invalid or contradictory equipment data cannot certify a complete build, and unknown fields remain unknown. The addon never executes received code or automatically equips items, consumes potions or posts group messages.

See [architecture](docs/ARCHITECTURE.md), [performance](docs/PERFORMANCE.md), [validation](docs/SUPPORT_COVERAGE_TESTING.md) and [contributing](CONTRIBUTING.md) for development details. Screenshots and bug reports should omit private chats, unrelated account information and SavedVariables containing group data.
