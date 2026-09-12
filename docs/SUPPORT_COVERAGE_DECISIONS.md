# Support Coverage — validated direction

Development continues on `support-coverage`. The user explicitly prohibited an alternative development branch, an automatic PR to main and an automatic merge. Main remains the stable baseline. The deleted `support-coverage` reference was restored to its preserved original commit before this integration.

The approved direction is broad observable-effect collection with raid-relevant display defaults; optional expected/actual equipment checks; four Champion slottables by role/build; committed Class Masteries; expected food and potion checks; combat potion-use evidence; optional non-mandatory poison checks; recipient- and target-specific uptime; closeable/reopenable reports and bounded raid/boss pull history; manual history reset and clearing on leaving/disbanding; recorded-loadout proposals; saved encounter profiles; and best-effort observations for non-ASUI group members with explicit missing-data labels.

Detailed checks use OFF, WARN and REQUIRED modes. No single meta loadout is mandatory. Source presence, manual assignment, observed uptime and proof of consumption/caster are different facts.

History labels use observed boss names and encounter-specific counters. Closing, automatic closing and reopening a report must not erase the stored report. A new fight closes deep planning/report windows. History must remain bounded independently of the user-selected number of pulls.

Unsupported or stale peer fields are UNKNOWN. A non-ASUI user is not assigned guessed gear, CP, mastery choices or potion use. Class, visible effects and compatible library data can still contribute explicit positive evidence.

This test branch is the validation base. Completion of syntax tests, regression tests or an audit does not authorize a PR. In-game testing and a later explicit user PR request remain separate steps.
