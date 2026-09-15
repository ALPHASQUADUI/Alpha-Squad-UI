# Ąlpha Şquad UI

A modular **The Elder Scrolls Online** addon by **@SeRuM1** for group preparation, visual build inspection and Ultimate tracking.

[Website](https://alphasquadeso.com/) · [Releases](https://github.com/ALPHASQUADUI/Alpha-Squad-UI/releases) · [Changelog](CHANGELOG.md) · [Downloads and installation](releases/README.md)

## Get started

1. Install the `AlphaSquadUI` folder in ESO's `live/AddOns` directory and enable it in the Add-Ons menu.
2. Open **Settings → Ąlpha Şquad UI** in keyboard or gamepad mode, or use `/asui`.
3. In **Dashboard**, choose **ULT Tracker** and **Support Coverage**, then pick an **Interface Style**. Tracking starts enabled; you can switch either module off.
4. Open **Libraries** to check dependencies and sharing. New installations configure supported sharing **ON** automatically; saved OFF choices are preserved.
5. Use **MOVE HUD** to choose horizontal/vertical layouts, preview realistic states and arrange your panels. Drag corners to scale, edges to reshape, then choose **DONE** or Back/Escape.
6. Open **Support Coverage → Builds** or **Coverage** to prepare your group.

Use [Minion](https://minion.mmoui.com/) to install and update published ESO addons and libraries. Install the full suite or the lightweight Build Share companion according to the features you need; do not nest either folder inside another addon directory.

## Dashboard and Cross-sync

**ULT Tracker** and **Support Coverage** have independent module switches. Overload is optional behavior inside the personal Ultimate tracker, with its own settings page and **Use Overload behavior** switch. Turning ULT Tracker off also stops its Overload behavior. **Libraries stays accessible**, and its sharing choices are independent of module switches.

**Cross-sync ON** saves module preferences and HUD positions across characters on the same account and server. **OFF** gives the current character its own settings. Switching keeps the current layout, requires no reload, and preserves the existing SavedVariables namespaces. Sharing choices remain account-wide.

## Choose your style

Select **Dashboard → Interface Style** to apply one saved appearance across the settings and HUD panels:

| Style | Appearance |
| --- | --- |
| **Obsidian Studio** — default | Soft dark cards, quiet borders and clearly separated sections |
| **Ember Classic** | Warm panels with Alpha Squad orange borders and accent lines |
| **Tactical Compact** | Flatter surfaces, fine dividers and reduced background fill |

Styles change immediately without a reload. Readiness colors, item quality and Champion discipline colors keep their meaning. Appearance follows Cross-sync, alongside your other saved interface preferences.

## Arrange your HUD

Click **MOVE HUD** in the settings sidebar or enter `/asmove` outside combat. Settings close and the normal game view remains visible, including the action bar. Select the personal Ultimate, Group Ultimate or Support Coverage panel, then:

- Drag the panel to move it.
- Drag a **corner** to scale the whole panel proportionally.
- Drag an **edge** to change its shape; the contents rearrange and icons stay square.
- Select **HORIZONTAL** or **VERTICAL** for personal and Group Ultimate panels. Resizing preserves this choice; it never switches layout unexpectedly at a width threshold.
- Use **PREVIEW** to choose mixed, ready, missing/charging, Overload or live states. Group previews contain twelve fictional accounts, so every row can be arranged while solo. Support previews show covered, missing, unknown, duplicate and tracking-off examples.
- Use **SCALE**, **OPACITY**, **RESET PANEL** and **FIT** in the placement toolbar for the selected panel. Opacity changes the background without fading icons or text.

**DONE** or Escape saves and locks the panels. Combat, loading or another menu ends placement safely.

Placement preserves disabled modules and normal visibility preferences. Personal Ultimate and Overload use the same panel, position and size. Group Ultimate tracking keeps its own panel and selection.

Examples exist only in the editor's presentation. They are never sent, stored as player builds, or counted as real coverage. Choosing **Live data** shows the currently available information instead. New personal HUDs start compact; previously saved sizes remain intact. Windowed, borderless, fullscreen and custom UI-scale changes refit panels without replacing the requested size.

## Keyboard and controller

The gamepad Settings menu includes **Ąlpha Şquad UI**. **Open Alpha Squad UI** and **Move Alpha Squad UI HUD** can also be assigned in Controls without replacing gameplay bindings.

Use arrows or the controller directional input to navigate, Select to activate, and Back to close the current window. Tab/Shift+Tab cycle keyboard focus. Left/right change a focused dropdown or slider. Focus displays the same explanations as mouse hover, including equipment and Champion details, and scrolls overflowing lists into view.

In MOVE HUD, the secondary action cycles **Move**, **Scale**, **Width**, **Height** and **Controls**; the shoulder actions change the selected panel. Directional movement is continuous in the geometry modes. Controls mode lets you reach orientation, preview, reset and Done. The on-screen hints identify the active mode. Native confirmation dialogs temporarily receive input; addon navigation resumes afterward. Combat, loading and leaving the addon screen release its input controls.

## Builds

Choose a group member to see a compact character sheet:

- Native character silhouette with armor, jewelry and front/back weapon slots.
- Exact item links: hover a piece for its trait, enchantment and native item description.
- Every equipped set, with the highest known bar total beside its name and exact **FRONT / BACK** counts. A two-handed weapon contributes two pieces. Three body pieces, a front sword/shield and a back staff from the same set display **5×**, with **5× / 5×** on the bars.
- An extra-piece warning when a verified bar total exceeds the set's final native bonus requirement. A genuine six-piece total stays **6×**; unknown set requirements do not produce a guessed warning. A **≥** headline identifies a lower bound when only one bar is known.
- Five skills and the exact Ultimate morph on each weapon bar, with a separate Werewolf bar when available.
- Twelve Champion slots, native discipline stars, invested points and the inspected player's corresponding bonus.
- Class Masteries, learned class passives, food, selected potion, Mundus and supported curse information.

The Champion interface uses ESO's own discipline artwork. The game does not provide a unique skill picture for each Champion star. Set icons come from actual equipment or supported native reference items; a reference is clearly distinguished from a player's equipped item. The mannequin preserves its native proportions, with mirrored armor columns and separate jewelry and weapon groups.

Tooltips appear above addon windows. For a shared skill, stat-dependent preview values use the viewer's character; equipment identity and the sender's CP allocation remain separate. **Unknown** means data is unavailable or incomplete; it never means confirmed absence.

## Coverage

Choose **Trial** or **Dungeon**, then review **Buffs**, **Debuffs**, **Group Sets** and **Group Mythics** on one page. Larger categories use multiple compact columns, with no scrolling or pagination. Each effect has native artwork, an ON/OFF switch, a status color and a contributor count. When an effect has no verified dedicated image, a native category symbol keeps the tile visible and its tooltip explains the fallback. **All**, **Missing** and **Duplicates** filter the page.

Hover an effect name for its full description, sources and conditions. Hover its contributor count for **every known provider**, their exact reported source names and bar availability. A duplicate shows **×** beside the count. Clicking the count opens the named contributor's build; select any other group member from the Builds roster. Green means covered, red missing, gold unknown or duplicate, and grey optional.

Coverage means a qualifying build source is available before combat. Range, target caps, casts and proc conditions still apply. The addon does not claim that an effect is currently active, and it does not collect pull reports or uptime history. Food and potion checks are integrated into Builds.

## Libraries and sharing

Install libraries as separate addon folders and enable their declared dependencies. **Libraries** shows green installed states, red missing/update states, ESOUI links and all sharing controls on one page.

In the in-game **Add-Ons** menu, expand **Ąlpha Şquad UI** to see all seven libraries under **Required Add-Ons**. Green means installed and enabled for the selected character; red names include **Missing library**, **Disabled**, or an update/dependency warning. This list covers the complete group feature set; local trackers still work without group libraries. The menu reads native addon states when refreshed, without changing any checkbox or sharing preference. Install missing libraries with Minion, then reload the UI. Before login, or if Alpha Squad itself is not loaded, the description lists the libraries without live status colors.

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

## Ultimate tracking

The personal Ultimate HUD handles normal Ultimates and optional Overload behavior in one panel.

- **AUTO** follows the active weapon bar. When enabled and applicable, Overload behavior prioritizes an Overload morph slotted on either bar.
- **FRONT** or **BACK** selects a weapon bar; enabled Overload behavior can still take priority.
- **BOTH** keeps both Ultimate cards visible and does not collapse the view into an Overload-only card.

New installations use AUTO. Existing FRONT, BACK and BOTH choices are preserved. **ULT Tracker → OVERLOAD SETTINGS** controls the specialized reserve warnings, ready reminder, optional safe cancellation and PvP preference. Turn **Use Overload behavior** OFF to retain standard Ultimate tracking. **Reserve alerts and auto-stop** controls the warnings and native cancellation together and starts enabled on new installations. Auto-stop runs only when ESO marks the active effect as removable; it never simulates an Ultimate key press.

The group view lets you choose abilities to follow, sorts ready players first and dims recent spends. Group tracking and library sharing remain independent of the personal display mode.

## Community

Open **Website & About** for the Alpha Squad website or **Discord** for the community page. **OPEN DISCORD COMMUNITY** opens the configured Discord widget in your browser after ESO's confirmation. Use the invitation there if Discord makes one available. The addon does not embed a web page, invent live member counts or send group/build data when you open the link.

## Commands

| Command | Opens or controls |
| --- | --- |
| `/asui` or `/alphasquad` | Main settings |
| `/asoverload` | Legacy alias for main settings |
| `/asoverload settings` | Optional Overload behavior settings |
| `/asult` | ULT settings |
| `/asult group` | Group Ultimate configuration |
| `/assupport builds` | Group build inspection |
| `/assupport matrix` | Coverage columns |
| `/assupport trial` or `/assupport dungeon` | Coverage context |
| `/asmove` | Arrange all enabled HUD panels; Done or Escape saves and locks |

Shared snapshots are bounded reports from compatible senders, not proof against a modified client. Invalid or contradictory equipment data cannot certify a complete build, and unknown fields remain unknown. The addon never executes received code or automatically equips items, consumes potions or posts group messages.

See [architecture](docs/ARCHITECTURE.md), [performance](docs/PERFORMANCE.md), [validation](docs/SUPPORT_COVERAGE_TESTING.md) and [contributing](CONTRIBUTING.md) for technical details. Screenshots and bug reports should omit private chats, unrelated account information and SavedVariables containing group data.
