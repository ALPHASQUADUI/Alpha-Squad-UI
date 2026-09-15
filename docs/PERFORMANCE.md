# Performance Guidelines

Performance is a design constraint for **Ąlpha Şquad UI**. The design reduces unnecessary work; real frame time, network coexistence and memory behavior must still be measured in ESO.

## Shared rules

1. Prefer filtered native events to frequent polling.
2. Coalesce bursts of equipment, skill and roster changes.
3. Cache validated snapshots and update only affected roster entries where practical.
4. Reuse controls and refresh visible views only when relevant state changes.
5. Run animations only while their visual output is visible.
6. Keep peer caches, payloads, pending fragments and retry queues bounded.
7. Guard missing optional libraries and malformed values at integration boundaries.
8. Do not parse combat logs for a precombat readiness question.

## Personal ULT and Overload

Native events drive shared personal slot/resource changes and relevant Overload effects. A single 1.5-second fallback refresh runs only while the personal tracker is enabled, visible and unobscured. READY, reserve and reminder animation runs only while visible and needed. Overload uses the same HUD, resource state and lifecycle; it has no separate recovery heartbeat.

The optional Overload effect subscription is filtered to the player and relevant morphs. Cached slot/effect state handles presentation; layout checks do not rescan skills. Placement and loading suppress alerts and cancellation.

## Group ULT

LibGroupCombatStats is subscribed for **ULT only**. An incoming player update changes that player's cached entry; no DPS/HPS stream is requested. Full roster refreshes are for membership/connectivity changes and a two-second safety check while the group HUD and its parent are enabled, visible and unobscured.

The HUD reuses up to twelve player rows. READY animation stops when no visible row requires it.

## Support Coverage

Equipment, skill, Champion and mastery changes invalidate a cached local build. Coalesced scans run outside combat. Quickslot/readiness changes take the lightweight consumable path instead of always rescanning equipment.

A **five-second lightweight recovery refresh** is restricted to visible or grouped precombat use. Combat suspends Support scans and build sends; deferred changes are handled after combat. Hidden inspectors do not continuously rebuild their content. Build presentation uses existing ESO item/skill assets and cached evidence rather than a live remote 3D character scene. Detailed tooltips are requested on hover instead of pre-rendering every full description.

There is **no combat sampler, uptime accumulator, pull report archive or planner search loop** in the active workflow. Build-sharing frames and pending receiver state are bounded, rate-limited and validated before affecting coverage. Only compact capability summaries are automatic; full builds are requested on demand. Detail transfers keep one acknowledged chunk in flight, wait at least 1.2 seconds between responses and cap the serialized snapshot at 3,584 bytes. Inactive transfers time out; completed detail data is cached for 120 seconds. The companion follows the same precombat transport constraints.

Disabling a module removes its gameplay subscriptions and unnecessary updates. Enabled sharing retains only the minimal data path. A disabled Support Coverage module uses a sixty-second grouped recovery check and never evaluates coverage or renders hidden views. Native CP artwork is held at a static frame without twelve animation loops. A missing library must not cause a retry loop or chat spam.

## Optional third-party evidence

LibSetDetection set updates are event-driven. Repeated reads do not make old data fresh; the adapter uses events observed in the current group session, labels the last-report age and invalidates records on session/identity/disconnect/deactivation changes. Change-only set traffic has no artificial short expiry timer. Compatible LibGroupCombatStats Ultimate/active-line evidence uses a 75-second conservative age limit; an idle sender may therefore become limited until it sends fresh data.

## Verification and limits

Automated tests cover deterministic logic, syntax, manifest/version consistency and package integrity. They cannot establish a zero-FPS-drop or zero-disconnection guarantee.

In ESO, compare addon ON/OFF frame time and memory in a four-player dungeon and a twelve-player trial. Check quiet precombat state, burst gear changes, hide/show, combat start/end, late join and simultaneous compatible broadcasts. Test alongside the raid addons actually used by the group. Stop additional synthetic testing once the remaining concrete risks have meaningful coverage; complete the real-client checklist next.

## Library settings

The native Add-Ons status list reuses the manager's existing entries in one pass when that menu rebuilds, then checks seven known libraries and their declared dependencies. It adds no timer, frame update, network traffic or persistent state, and changes only the suite's display text.

Libraries remain installed and available independently of UI modules. Only verified matching protocols are changed, and queued disabled packets are pruned. LibGroupCombatStats does not expose sender unregistration; its own shared send timer can remain until reload after its protocol is disabled. The addon does not suppress callbacks belonging to another library or its other clients. On the next load, an explicitly disabled Ultimate sender is not registered by this addon.

Dashboard and Libraries use static controls. Libraries fits its two columns and Minion footer on the settings canvas without a scrollbar. The common shell fits smaller viewports by scaling only when necessary. Native tooltip scale and draw order are restored after use.


## Compact interface and placement

The Coverage grid creates its controls once and reanchors them for filtering or viewport changes. A fixed single page replaces tall repeated provider rows; contributor descriptions are assembled on hover. Set-bonus thresholds use a bounded cache of 256 successful native lookups. Incomplete or unavailable native lookups are not cached as proof of absence.

Global MOVE HUD is a short-lived placement state without an idle heartbeat. Only Dashboard-enabled modules participate. A mouse-position callback exists only during an active edge/corner drag, reflows changed dimensions and stops on release or cancellation. Placement previews suspend normal alert animation work and preserve normal visibility settings; closing saves and locks the panels. Personal ULT and Overload share one HUD, with cached slot state choosing the display and no extra skill scan.

Sharing defaults are applied once, and actual native library states remain authoritative afterward. Missing libraries and unsupported controls do not trigger polling or repeated navigation. Sharing controls do not create a second library-settings window.

## Appearance and community pages

Theme changes repaint registered settings/HUD surfaces once; profile changes rebind the saved preset. The themes add no animation, recurring repaint or build scan. Tactical Compact changes framing and background fill, not the geometric layout or icon sizes. Status, quality, Champion colors and branding remain stable.

Core Shell initializes independently of disabled gameplay modules. Website & About and Discord pages use native static controls. Opening the Discord widget is an explicit external-browser action after ESO confirmation; there is no embedded web renderer or live member-count polling.
