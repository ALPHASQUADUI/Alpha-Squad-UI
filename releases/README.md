# Downloads and installation

[Release downloads](https://github.com/ALPHASQUADUI/Alpha-Squad-UI/releases) · [Build artifacts](https://github.com/ALPHASQUADUI/Alpha-Squad-UI/actions) · [Version 3.3.1 notes](3.3.1.md)

The maintainer accepted the 3.3.1 candidate as stable in the tested setup on 2026-09-16 and authorized promotion to `main`. A public GitHub Release remains pending formal protocol reservation, coexistence evidence and release-environment configuration. The previous published packages remain unchanged. Retain a private backup of your existing SavedVariables when installing the candidate.

## Install

1. Close ESO or return to character selection. Back up existing addon SavedVariables before updating.
2. Extract **AlphaSquadUI-3.3.1.zip** so `AlphaSquadUI/AlphaSquadUI.txt` is directly inside the ESO `live/AddOns` directory.
3. Install any libraries required by your selected group features. [Minion](https://minion.mmoui.com/) can manage published addons and dependencies.
4. Enable the addon and libraries, then log in or `/reloadui`.
5. Open **Settings → Ąlpha Şquad UI → Dashboard**. Review sharing in **Libraries**; a new installation keeps supported sharing OFF until you choose otherwise. Existing saved ON/OFF choices and native OFF states are preserved. Choose **Interface Style** in Dashboard and use **MOVE HUD** to position, scale or reshape enabled panels. Select Horizontal or Vertical for the Ultimate panels and use Preview to place them with sample data, including a twelve-player group.

The optional **AlphaSquadBuildShare-3.3.1.zip** installs a separate `AlphaSquadBuildShare` directory for players who want to share supported builds without the tracking interface. It requires LibGroupBroadcast and its dependencies, starts with sharing OFF on a new installation and preserves existing saved preferences. Use `/asbuildshare off`, `/asbuildshare on` and `/asbuildshare status` to control it. Install the appropriate package; the full suite already includes build sharing. The companion transmits build snapshots, not live Ultimate charge; that needs a compatible LibGroupCombatStats sender.

## Updating to 3.3.1

Update the full suite and any separately installed companion together. New installations now require an explicit sharing choice. Settings respect combat/loading boundaries, hidden Ultimate HUDs defer painting, and preparation warnings remain visible independently of available effect sources. Interrupted build transfers expire without requiring an open inspector, while progress and failures remain visible beside partial build information.

If a queued build cannot be cleared, the addon attempts to block only its own native protocols and requires a new explicit ON after recovery, including after a reload. If native controls cannot disable sending, the status explains that a UI reload is required. Existing native OFF choices are never automatically restored to ON by this recovery path.

Existing supported settings and FRONT/BACK/BOTH selections remain intact; new installations start in AUTO. Overload remains integrated into the personal Ultimate HUD, with **Warning starts** and optional alerts under **ULT Tracker → OVERLOAD SETTINGS**. Automatic cancellation has been removed; you stop Overload using your Ultimate binding. Group tracking has one ON/OFF switch in the parent ULT settings and excludes your own character. A previously hidden group HUD migrates to Group tracking OFF, while filters and layout remain saved.

MOVE HUD now waits for the native menu transition before opening. Select Horizontal or Vertical, adjust the twelve-player preview, and choose Done or Back to save and return to the addon window you came from. Closing Group configuration, Coverage or Builds also returns to the previous addon window. Safety stops caused by combat, loading or another game menu do not reopen settings. Preview states remain temporary and are never shared.

About contains the website and direct Discord invitation. No separate Discord page or widget is required.

Keyboard and controller navigation use the same settings and tooltips. Controller access is available through the native gamepad settings category; suite navigation releases input when closed or when native dialogs, combat or loading take over. The companion package obtains its version and API metadata from the full suite during packaging.

## Automated build artifacts

Open a successful run under **Actions** and download its addon artifacts. GitHub requires sign-in for artifact downloads and may wrap the addon ZIPs in an outer archive. Extract the addon folder, not the repository or artifact wrapper, into `AddOns`. Artifact retention is limited; published release assets are listed under Releases when available.

Version numbers identify package contents. A successful automated run validates syntax, logic and packaging; it does not certify native ESO rendering or group-network coexistence. Follow the [client validation checklist](../docs/SUPPORT_COVERAGE_TESTING.md) when reviewing an update.
