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

The optional Overload effect subscription is filtered to the player and relevant morphs. Cached slot/effect state handles presentation; layout checks do not rescan skills. Placement and loading suppress alerts. Overload no longer calls effect cancellation APIs or maintains auto-stop state.

The personal HUD compares a layout signature before reanchoring unchanged controls. Resource and readiness text can update without repeating the geometry work. Horizontal/Vertical selection is explicit, with cached dimensions for each orientation; a small edge movement does not trigger a sudden template switch.

## Group ULT

LibGroupCombatStats is subscribed for **ULT only**. An incoming player update changes that player's cached entry; no DPS/HPS stream is requested. Full roster refreshes are for membership/connectivity changes and a two-second safety check while the group HUD and its parent are enabled, visible and unobscured.

The group view excludes the local player and retains no group-ready-sound callback. The HUD reuses up to twelve player rows, including the twelve-player placement sample. Horizontal and vertical presentations reuse the same pool. READY animation stops when no visible row requires it, and placement samples do not start gameplay alerts.

Group row geometry is cached separately from charge/readiness painting. The configured row size does not stretch when fewer players match; the live frame contracts while retaining the requested full-roster dimensions for placement. Sorting and resource changes reuse existing geometry when its signature is unchanged.

## Support Coverage

Equipment, skill, Champion and mastery changes invalidate a cached local build. Coalesced scans run outside combat. Quickslot/readiness changes take the lightweight consumable path instead of always rescanning equipment. Screen-resize bursts schedule one deferred Support refresh using the dimensions available when it runs. A regression delivers 200 events before that callback and checks that they produce one pass; this measures coalescing, not native frame time.

A **five-second lightweight recovery refresh** is restricted to visible or grouped precombat use. Combat suspends Support scans and build sends; deferred changes are handled after combat. Hidden inspectors do not continuously rebuild their content. Build presentation uses existing ESO item/skill assets and cached evidence rather than a live remote 3D character scene. Detailed tooltips are requested on hover instead of pre-rendering every full description.

There is **no combat sampler, uptime accumulator, pull report archive or planner search loop** in the active workflow. Build-sharing frames and pending receiver state are bounded, rate-limited and validated before affecting coverage. Only compact capability summaries are automatic; full builds are requested on demand. Detail transfers keep one acknowledged chunk in flight, wait at least 1.2 seconds between responses and cap the serialized snapshot at 3,584 bytes. Inactive transfers time out; completed detail data is cached for 120 seconds. The companion follows the same precombat transport constraints.

Disabling a module removes its gameplay subscriptions and unnecessary updates. Enabled sharing retains only the minimal data path. A disabled Support Coverage module uses a sixty-second grouped recovery check and never evaluates coverage or renders hidden views. Native CP artwork is held at a static frame without twelve animation loops. A missing library must not cause a retry loop or chat spam.

## Optional third-party evidence

LibSetDetection set updates are event-driven. Repeated reads do not make old data fresh; the adapter uses events observed in the current group session, labels the last-report age and invalidates records on session/identity/disconnect/deactivation changes. Change-only set traffic has no artificial short expiry timer. Compatible LibGroupCombatStats Ultimate/active-line evidence follows its character-indexed group cache. Slots and skill lines are change-driven, so unchanged reports have no artificial expiry; their original valid library timestamp is preserved and is never renewed by polling. Removed cache entries, invalid timestamps and unavailable current members supply no actionable coverage. The separate Alpha Squad build-summary lifetime is unchanged.

## Verification and limits

Automated tests cover deterministic logic, syntax, manifest/version consistency and package integrity. They cannot establish a zero-FPS-drop or zero-disconnection guarantee.

In ESO, compare addon ON/OFF frame time and memory in a four-player dungeon and a twelve-player trial. Check quiet precombat state, burst gear changes, hide/show, combat start/end, late join and simultaneous compatible broadcasts. Test alongside the raid addons actually used by the group. Stop additional synthetic testing once the remaining concrete risks have meaningful coverage; complete the real-client checklist next.

## Library settings

The native Add-Ons status list reuses the manager's existing entries in one pass when that menu rebuilds, then checks seven known libraries and their declared dependencies. It adds no timer, frame update, network traffic or persistent state, and changes only the suite's display text.

Libraries remain installed and available independently of UI modules. Only verified matching protocols are changed, and queued disabled packets are pruned. LibGroupCombatStats does not expose sender unregistration; its own shared send timer can remain until reload after its protocol is disabled. The addon does not suppress callbacks belonging to another library or its other clients. On the next load, an explicitly disabled Ultimate sender is not registered by this addon.

Dashboard and Libraries reuse static controls. The shell uses actual viewport dimensions and page layout callbacks at native scale: navigation becomes a compact strip and cards stack when needed. Libraries retains one-page layouts where space permits; very narrow canvases use readable scrolling instead of shrinking all text. Native tooltip scale and draw order are restored after use.

LibSetDetection receipts belong to an uninterrupted group session rather than the tracking switch. A small membership/connectivity guard remains registered while tracking is disabled so old character data cannot survive departure. It performs no equipment scan, coverage evaluation or send. Ordinary zoning and OFF/ON do not fabricate receipt times or rehydrate an unproven stale library cache.


## Compact interface and placement

The Coverage grid creates its controls once and reanchors them for filtering or viewport changes. A fixed single page replaces tall repeated provider rows; contributor descriptions are assembled on hover. Dense rows fit native icons inside their own hit area. Set-bonus thresholds use a bounded cache of 256 successful native lookups. Successful native effect and set previews are cached; unavailable artwork uses an identified category symbol, without treating a missing lookup as verified identity.

Global MOVE HUD is a short-lived placement state without an idle heartbeat. Its entry waits on the existing scene lifecycle callback; repeated clicks cannot queue multiple editors. Normal HUD/cursor-mode changes retain the editor, while combat/loading and unrelated menus cancel it. Only Dashboard-enabled modules participate. A mouse-position callback exists only during an active drag and stops on release or cancellation. Unchanged pointer positions do no layout work. Corners change only the native parent scale; edge changes reflow the logical dimensions. Both paths keep the opposite edge fixed and avoid applying scale twice. Cached logical canvas sizes also prevent repeated scaled inspector refreshes from shrinking the build sheet.

`Core/Preview.lua` stores only the selected presentation mode. Personal, group and Support renderers cache their sample tables by mode and consume them only during placement. Switching samples performs no scan, build request or send, and sample rows never enter live evidence. Placement previews suspend normal alert animation work and preserve normal visibility settings; closing saves and locks the panels. Personal ULT and Overload share one HUD, with cached slot state choosing the display and no extra skill scan.

New sharing categories start OFF until explicitly enabled, and actual native library states remain authoritative afterward. Missing libraries and unsupported controls do not trigger polling or repeated navigation. Sharing controls do not create a second library-settings window.

## Input ownership

Keyboard/controller navigation reuses registered controls, their existing callbacks and a shared focus border. The action layer and native directional-input owner are acquired only for an open suite window or placement toolbar and released when navigation is suspended or closed. Live HUD visibility alone does not acquire them. Native dialogs, combat, loading and scene changes suspend navigation instead of leaving movement controls captured.

Focus candidate geometry is read when navigating visible controls, not through an always-running scan. Controller placement uses the open session's directional-input callback and capped frame delta for movement. When suite navigation is closed, it adds no directional-input loop or mouse-position poll. These lifecycle checks do not replace real-client controller and frame-time measurements.

## Appearance and community pages

Theme changes repaint registered settings/HUD surfaces once; profile changes rebind the saved preset. The themes add no animation, recurring repaint or build scan. Tactical Compact changes framing and background fill, not the geometric layout or icon sizes. Status, quality, Champion colors and branding remain stable.

Core Shell initializes independently of disabled gameplay modules. The widened Workspace and About page use static native controls. Discord opens the verified invitation only after an explicit click and ESO confirmation; there is no intermediate community page, embedded web renderer or live member-count polling. The style dropdown owns one opaque native backdrop. Window return history is a bounded transient list, not a polling task or persistent navigation log.

## Recorded observations

The supplied 3.1.0 client recording shows a brief FPS-counter decrease when Builds opens, followed by recovery. It does not isolate the addon from the game scene or other addons, and cannot establish a cause or a before/after improvement. This update fixes scene ordering and redundant resize callbacks; it makes no measured FPS claim. The [video review](VIDEO_REVIEW_3.2.0.md) distinguishes visible failures from code findings and remaining client checks.

## 3.3.1 maintenance boundaries

Hidden personal and Group Ultimate HUDs retain current data but defer painting until their next visible presentation. Normal visibility restoration and placement previews perform the pending render. Static Ultimate names/icons are cached for resource-only ticks; identity, cost and active effect state remain dynamic. Settings execute global refreshers and the selected page's refreshers, with an immediate refresh when a page becomes active.

Readiness-only changes are coalesced separately from build changes. If food/potion/Mundus and their presentation facts are unchanged, the fast path avoids another roster/coverage reconstruction; meaningful expiry and peer-freshness boundaries still require evaluation. A full build scan reuses its readiness facts rather than immediately reading them twice. Equipment and skill changes retain full invalidation because native descriptions and derived evidence can depend on changed stats. This is a correctness choice, not a claim that every future scan optimization is complete.

Transfer watchdogs exist only for live transfers. They enforce inactivity and total duration, have at most one live next check per transfer, and stop after cancellation. Incoming summary/capability work is bounded and duplicate content reuses existing state without suppressing a stale-to-fresh transition. The protocol still retains one incoming and one outgoing build.

Counter-based regressions establish skipped work, not a measured FPS gain. Solo, four-player and twelve-player measurements remain native-client acceptance work.

## 3.4.0 presentation and sender work

The personal Ultimate renderer interpolates positive progress changes for 180 ms only while visible. A decrease/spend updates immediately, and interpolation cannot make an unready ability display 100%. Its shared animation lifecycle stops on hide, disable, loading and placement. Group readiness is steady green; the old full-row pulse and its timer are removed. Solo Group ULT no longer retains an empty-roster recovery update.

Localization uses one dictionary lookup per changed label and a one-shot refresh of existing controls on language choice. It never changes protocol tokens, native item/skill names or player names. Cached readiness stores its English template/arguments, allowing translated tooltips without a new build scan. Hidden views render from current cached state when opened. Native tooltip text remains in the ESO client language.

A detailed response reuses the already validated encoding of that exact local snapshot, avoiding a second Encode pass. When tracking is OFF and actual native sending is OFF/unavailable, expensive scans are skipped. Dirty flags, combat/loading/queue cleanup and the slow 60-second sender wake check remain, so later native ON can recover. A peer request while native sending is OFF is rejected before capture or encoding, without preventing receipt of compatible summaries. These are counter-tested work reductions, not measured FPS improvements.
