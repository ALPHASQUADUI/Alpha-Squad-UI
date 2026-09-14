# Downloads and installation

[Release downloads](https://github.com/ALPHASQUADUI/Alpha-Squad-UI/releases) · [Build artifacts](https://github.com/ALPHASQUADUI/Alpha-Squad-UI/actions) · [Version 3.0.0 notes](3.0.0.md)

## Install

1. Close ESO or return to character selection. Back up existing addon SavedVariables before updating.
2. Extract **AlphaSquadUI.zip** so `AlphaSquadUI/AlphaSquadUI.txt` is directly inside the ESO `live/AddOns` directory.
3. Install any libraries required by your selected group features. [Minion](https://minion.mmoui.com/) can manage published addons and dependencies.
4. Enable the addon and libraries, then log in or `/reloadui`.
5. Open **Settings → Ąlpha Şquad UI → Dashboard**. Review sharing in **Libraries**; a new installation enables supported sharing automatically. Existing saved OFF choices are preserved. Choose **Interface Style** in Dashboard and use **MOVE HUD** to position, scale or reshape enabled panels.

The optional **AlphaSquadBuildShare.zip** installs a separate `AlphaSquadBuildShare` directory for players who want to share supported builds without the tracking interface. It requires LibGroupBroadcast, starts sharing on a new installation and preserves an existing OFF preference. Use `/asbuildshare off`, `/asbuildshare on` and `/asbuildshare status` to control it. Install the appropriate package; the full suite already includes build sharing.

## Updating to 3.0.0

Overload now shares the personal Ultimate HUD. Its existing supported settings migrate without deleting old SavedVariables; saved FRONT/BACK/BOTH modes remain intact, while new installations start in AUTO. Open **ULT Tracker → OVERLOAD SETTINGS** for the optional specialized behavior. The companion package obtains its version and API metadata from the full suite during packaging.

## Automated build artifacts

Open a successful run under **Actions** and download its addon artifacts. GitHub requires sign-in for artifact downloads and may wrap the addon ZIPs in an outer archive. Extract the addon folder, not the repository or artifact wrapper, into `AddOns`. Artifact retention is limited; published release assets are listed under Releases when available.

Version numbers identify package contents. A successful automated run validates syntax, logic and packaging; it does not certify native ESO rendering or group-network coexistence. Follow the [client validation checklist](../docs/SUPPORT_COVERAGE_TESTING.md) when reviewing an update.
