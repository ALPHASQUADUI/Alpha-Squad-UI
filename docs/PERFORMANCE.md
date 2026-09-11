# Performance Guidelines

Performance is a design constraint for every Ąlpha Şquad UI module.

## Rules

1. Prefer ESO events over frequent polling.
2. Poll only as a fallback when the ESO API does not expose a reliable event.
3. A dormant module should not run fast update callbacks.
4. Fast animation callbacks should be registered only for the lifetime of the animation.
5. Avoid repeated UI writes when displayed values have not changed.
6. Avoid repeatedly scanning unrelated action slots.
7. Filter events as narrowly as the API allows.
8. Keep combat HUD trees shallow and reuse controls rather than recreating them.
9. Do not perform debug/chat formatting unless debug output is explicitly enabled or requested.
10. Any new persistent heartbeat must document why an event-driven solution is insufficient.

## Overload module baseline

The current Overload module uses event-driven updates for effects, power, action slots, hotbars, ability use and scenes. A slow fallback synchronization remains as a safety net.

When no supported Overload Ultimate is equipped, the module enters dormant mode and greatly reduces background work.
