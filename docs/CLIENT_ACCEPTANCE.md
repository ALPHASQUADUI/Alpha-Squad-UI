# ESO client acceptance

This checklist records behavior that automated Lua and packaging checks cannot establish. No row is passed until someone runs it in ESO on the stated versions. Never substitute a mock result for a native result.

## Record the environment

Record the Alpha Squad UI and companion versions, ESO API/build, library versions, operating system, display resolution, native UI scale and input device. Use synthetic account labels in any published evidence; keep private chats and SavedVariables out of screenshots.

## Short acceptance route

| Scenario | Expected result | Native result |
| --- | --- | --- |
| Open with the gameplay keybind, then close | Cursor is usable immediately and returns to the prior gameplay state | Not recorded |
| Open Group configuration, Coverage and Builds; close each | The previous addon window returns; combat/loading never reopens it | Not recorded |
| Read an item, skill and Champion tooltip for 15 seconds | Unchanged refreshes preserve the tooltip; changing the player replaces its content | Not recorded |
| Move HUD using mouse and controller | Moving, proportional corner scaling and edge resizing track the input; Done saves and exits | Not recorded |
| Resize between windowed, borderless and fullscreen | Controls remain reachable, text readable and requested HUD placement recoverable | Not recorded |
| Change logical canvas through 1024×768, 1280×720, 1920×1080 and ultrawide | Settings reflow; no inaccessible footer or overlapping controls | Not recorded |
| Group list changes from 12 matching players to 4 and then 1 | Rows keep their configured height; readiness values do not rebuild the whole layout | Not recorded |
| Turn Support OFF and ON with unchanged LibSetDetection peers | Valid same-session set reports return without an equipment change | Not recorded |
| Leave/rejoin, change character, go offline, travel and reload | Departed/changed identities do not inherit old set or build claims | Not recorded |
| Inspect confirmed passives/masteries on English and non-English clients | Local and received coverage agree using verified identities | Not recorded |
| Inspect supported Scribing recipes on both bars | The script combination and beneficiary determine coverage; unknown recipes remain unknown | Not recorded |
| Send a build, then OFF before its queued data leaves | Pending personal data is revoked where supported; another addon's traffic is unchanged | Not recorded |
| Disable native LGB sending, then ask companion status | The status explains the actual block instead of falsely claiming active sharing | Not recorded |
| Slot/use both Overload morphs and Werewolf/Vampire Ultimates | Personal native bar, icon, cost and active state agree with the game | Not recorded |
| Run a 12-player group with multiple sharing addons | Record latency, retries and frame-time comparison; packet loss remains bounded | Not recorded |

## Performance comparison

Compare the same scene and group with tracking ON and OFF while leaving sharing unchanged. Record frame-time distribution rather than a single FPS value, addon memory before/after repeated openings, and whether callbacks stop when their feature is hidden. Repeat after a loading transition. Do not publish a claim of zero resource cost.

## Evidence and follow-up

Record pass/fail, the exact environment and a concise reproduction for each failure. A release's automated checks and source commit are recorded in its package provenance; they do not complete this checklist. The longer [coverage checklist](SUPPORT_COVERAGE_TESTING.md) covers individual data and lifecycle cases.
