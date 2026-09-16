# Downloads and installation

[Release downloads](https://github.com/ALPHASQUADUI/Alpha-Squad-UI/releases) · [Build artifacts](https://github.com/ALPHASQUADUI/Alpha-Squad-UI/actions) · [Version 3.4.1 notes](3.4.1.md)

The current development package is **3.4.1**, a hotfix for the Dashboard `BG` / `Scroll` initialization errors reported in 3.4.0. Download it from a successful `dev` Actions run and verify the version and source commit. Native retesting remains pending; this development cycle authorizes no PR or public release.

The maintainer's 3.3.1 stability report from 2026-09-16 is historical and does not approve 3.4.1. Public release still requires separate authorization, formal protocol reservation, coexistence evidence and release-environment configuration. Retain a private backup of your existing SavedVariables when installing the candidate.

## Install

1. Close ESO or return to character selection. Back up existing addon SavedVariables before updating.
2. Extract **AlphaSquadUI-3.4.1.zip** so `AlphaSquadUI/AlphaSquadUI.txt` is directly inside the ESO `live/AddOns` directory.
3. Install any libraries required by your selected group features. [Minion](https://minion.mmoui.com/) can manage published addons and dependencies.
4. Enable the addon and libraries, then log in or `/reloadui`.
5. Open **Settings → Ąlpha Şquad UI → Dashboard**. Review sharing in **Libraries**; a new installation keeps supported sharing OFF until you choose otherwise. Existing saved ON/OFF choices and native OFF states are preserved. Choose **Language** and **Interface Style** in Dashboard and use **MOVE HUD** to position, scale or reshape enabled panels. The orientation control beside each Ultimate HUD selects Horizontal or Vertical; Preview supplies sample data, including a twelve-player group.

The optional **AlphaSquadBuildShare-3.4.1.zip** installs a separate `AlphaSquadBuildShare` directory for players who want to share supported builds without the tracking interface. It requires LibGroupBroadcast and its dependencies, starts with sharing OFF on a new installation and preserves existing saved preferences. Use `/asbuildshare off`, `/asbuildshare on` and `/asbuildshare status` to control it. Install the appropriate package; the full suite already includes build sharing. The companion transmits build snapshots, not live Ultimate charge; that needs a compatible LibGroupCombatStats sender.

## Updating to 3.4.1

Update the full suite and any separately installed companion together, then log in or `/reloadui`. Open Dashboard and alternate its theme and language menus: both should initialize and select independently without duplicate-control errors. The hotfix preserves the compact bilingual 3.4 interface and existing saved settings. Native retest outcomes belong in the [client acceptance record](../docs/CLIENT_ACCEPTANCE.md).

If a queued build cannot be cleared, the addon attempts to block only its own native protocols and requires a new explicit ON after recovery, including after a reload. If native controls cannot disable sending, the status explains that a UI reload is required. Existing native OFF choices are never automatically restored to ON by this recovery path.

Existing supported settings and placement remain intact. The personal Ultimate HUD always displays both weapon slots, with a green active-bar marker and a dimmed inactive icon; the old AUTO/FRONT/BACK/BOTH selectors are retired. Overload remains integrated into this transparent HUD with gold active, green ready and red stop states, plus **Warning starts** and optional alerts under **ULT Tracker → OVERLOAD SETTINGS**. Automatic cancellation has been removed; you stop Overload using your Ultimate binding. Group tracking has one ON/OFF switch in the parent ULT settings and excludes your own character. A previously hidden group HUD migrates to Group tracking OFF, while filters and layout remain saved.

MOVE HUD waits for the native menu transition before opening. Use the orientation control beside the intended HUD, adjust the twelve-player preview, and choose Done or Back/Escape to save and select Alpha Squad in native Settings. Main Close returns to gameplay. Closing Group configuration, Coverage or Builds returns to the previous addon window. Safety stops caused by combat, loading or another game menu do not reopen settings. Preview states remain temporary and are never shared.

About contains the website and direct Discord invitation. No separate Discord page or widget is required.

Keyboard and controller navigation use the same settings and tooltips. Controller access is available through the native gamepad settings category; suite navigation releases input when closed or when native dialogs, combat or loading take over. The companion package obtains its version and API metadata from the full suite during packaging.

## Automated build artifacts

Open a successful run under **Actions** and download its addon artifacts. GitHub requires sign-in for artifact downloads and may wrap the addon ZIPs in an outer archive. Extract the addon folder, not the repository or artifact wrapper, into `AddOns`. Artifact retention is limited; published release assets are listed under Releases when available.

Version numbers identify package contents. A successful automated run validates syntax, logic and packaging; it does not certify native ESO rendering or group-network coexistence. Follow the [client validation checklist](../docs/SUPPORT_COVERAGE_TESTING.md) when reviewing an update.
