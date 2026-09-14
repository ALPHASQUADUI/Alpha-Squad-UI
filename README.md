# Ąlpha Şquad UI

A modular **The Elder Scrolls Online** addon by **@SeRuM1** for group preparation, visual build inspection and Ultimate tracking.

[Website](https://alphasquadeso.com/) · [Releases](https://github.com/ALPHASQUADUI/Alpha-Squad-UI/releases) · [Changelog](CHANGELOG.md) · [Downloads and installation](releases/README.md)

## Get started

1. Install the `AlphaSquadUI` folder in ESO's `live/AddOns` directory and enable it in the Add-Ons menu.
2. Open **Settings → Ąlpha Şquad UI**, or use `/asoverload`.
3. In **Dashboard**, enable the modules you want. Disabled modules disappear from navigation and stop their tracking work.
4. Open **Libraries** to install dependencies and choose what to share.
5. Open **Support Coverage → Builds** or **Coverage** to prepare your group.

Use [Minion](https://minion.mmoui.com/) to install and update published ESO addons and libraries. Install the full suite or the lightweight Build Share companion according to the features you need; do not nest either folder inside another addon directory.

## Dashboard and Cross-sync

**Overload**, **ULT Tracker** and **Support Coverage** have independent module switches. Turning a module off removes its gameplay subscriptions, recovery updates and visual work. **Libraries stays accessible**, and its sharing choices are independent of module switches.

**Cross-sync ON** saves module preferences and HUD positions across characters on the same account and server. **OFF** gives the current character its own settings. Switching keeps the current layout, requires no reload, and preserves the existing SavedVariables namespaces. Sharing choices remain account-wide.

## Builds

Choose a group member to see a compact character sheet:

- Native character silhouette with armor, jewelry and front/back weapon slots.
- Exact item links: hover a piece for its trait, enchantment and native item description.
- Every equipped set, with physical item counts and separate front/back set-piece totals. A two-handed weapon is one item worth two set pieces; a set can qualify on either bar.
- Five skills and the exact Ultimate morph on each weapon bar, with a separate Werewolf bar when available.
- Twelve Champion slots, native discipline stars, invested points and the inspected player's corresponding bonus.
- Class Masteries, learned class passives, food, selected potion, Mundus and supported curse information.

The Champion interface uses ESO's own discipline artwork. The game does not provide a unique skill picture for each Champion star. Set icons come from actual equipment or the native set collection; a collection reference is clearly distinguished from a player's equipped item.

Tooltips appear above addon windows. For a shared skill, stat-dependent preview values use the viewer's character; equipment identity and the sender's CP allocation remain separate. **Unknown** means data is unavailable or incomplete; it never means confirmed absence.

## Coverage

Choose **Trial** or **Dungeon**, then review four visual columns: **Buffs**, **Debuffs**, **Group Sets** and **Group Mythics**. Each effect has a tracking switch, source/trigger explanation and its available providers. **All**, **Missing** and **Duplicates** filters focus the view. Hover a player to see the skills or sets behind their contribution, or click to inspect their build.

Coverage means a qualifying build source is available before combat. Range, target caps, casts and proc conditions still apply. The addon does not claim that an effect is currently active, and it does not collect pull reports or uptime history. Food and potion checks are integrated into Builds.

## Libraries and sharing

Install libraries as separate addon folders and enable their declared dependencies. **Libraries** shows green installed states, red missing/update states, ESOUI links and all sharing controls on one page.

| Library | Purpose | Required setup |
| --- | --- | --- |
| [LibGroupBroadcast](https://www.esoui.com/downloads/info1337-LibGroupBroadcast.html) | Compatible full-build exchange | Install with LibAddonMenu-2.0 38+ and LibDebugLogger. Choose **Share equipped build** in Libraries on participating clients. |
| [LibGroupCombatStats](https://www.esoui.com/downloads/info4024-LibGroupCombatStats.html) | Group Ultimate data | Install with LibCombat and LibGroupBroadcast. **Share group Ultimates** controls its matching library protocols. |
| [LibSetDetection v5+](https://www.esoui.com/downloads/info3338-LibSetDetection.html) | Shared sets and per-bar counts | Install on both ends with LibGroupBroadcast. Choose **Share equipped sets**; incognito choices are respected. |
| [LibFoodDrinkBuff](https://www.esoui.com/downloads/info1902-LibFoodDrinkBuff.html) | Recognition of observable food/drink effects | Install and enable. No additional setup is needed. |
| [LibCombat](https://www.esoui.com/downloads/info2528-LibCombat.html) | Dependency of LibGroupCombatStats | Install and enable. Alpha Squad does not request DPS/HPS streams. |
| [LibAddonMenu-2.0](https://www.esoui.com/downloads/info7-LibAddonMenu-2.0.html) | Library settings | Version 38 or newer for LibGroupBroadcast. |
| [LibDebugLogger](https://www.esoui.com/downloads/info2275-LibDebugLogger.html) | Dependency of LibGroupBroadcast | Install and enable; normal use needs no extra logging configuration. |

Full-build sharing defaults **OFF**. It uses provisional transport identifiers pending formal registration; enable it only in coordinated groups. Details are requested on demand, validated and retained briefly in memory. Sharing pauses during combat and loading, and group/identity changes invalidate inappropriate data.

The library switches change only their matching protocol settings, using a guarded compatibility bridge. Other addons using those same library protocols follow those settings. Unrelated protocols and libraries are untouched. If an incompatible library version cannot be controlled safely, use the native **Settings** button. LibGroupCombatStats may keep its own shared timer until reload after sending is disabled; the addon does not tamper with another library's event registrations.

### What can other players share?

| Sender setup | Available information |
| --- | --- |
| No compatible sender | Native group identity, class and observable effects only; no general remote inventory inspection |
| LibSetDetection | Disclosed sets and front/back counts; no exact items, traits, glyphs, CP or skill bars |
| LibGroupCombatStats | Shared Ultimates and supported active class-line information; no full-build inspection |
| Alpha Squad UI with sharing enabled | Supported equipment, skills, Champion allocation, masteries and readiness snapshot |
| **AlphaSquadBuildShare** companion | The same supported build format without installing the tracking UI suite |

The companion needs LibGroupBroadcast. Use `/asbuildshare on`, `/asbuildshare off` and `/asbuildshare status`. It defaults OFF and yields to the full suite when both are installed. Installing a transport library alone cannot expose another player's complete build.

## Ultimate modules

**Overload** follows the actual Sorcerer Overload morph and provides reserve warnings, optional safe cancellation and a ready reminder. Automatic cancellation uses `CancelBuff` only when ESO marks the effect as removable; it never simulates a protected key press.

**ULT Tracker** reads the actual Ultimates on both weapon bars. The group view lets you choose abilities to follow, sorts ready players first and dims recent spends. Tracking and library sharing have independent lifecycles.

## Commands

| Command | Opens or controls |
| --- | --- |
| `/asoverload` | Main settings and Dashboard |
| `/asult` | ULT settings |
| `/asult group` | Group Ultimate configuration |
| `/assupport builds` | Group build inspection |
| `/assupport matrix` | Coverage columns |
| `/assupport trial` or `/assupport dungeon` | Coverage context |
| `/assupport move` | Enable, show and unlock the preparation HUD |

See [architecture](docs/ARCHITECTURE.md), [performance](docs/PERFORMANCE.md), [validation](docs/SUPPORT_COVERAGE_TESTING.md) and [contributing](CONTRIBUTING.md) for development details. Screenshots and bug reports should omit private chats, unrelated account information and SavedVariables containing group data.
