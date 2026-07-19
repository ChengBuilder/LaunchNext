# AppKit Rebuild Performance Benchmark

## Purpose

This runbook measures launch, catalog publication, cache preparation, window
transitions, and later folder/page animations with comparable Instruments
signposts. It does not infer performance from Debug logging or FPS averages.

## Test Matrix

- Use the same Mac, display, refresh rate, power source, application catalog, and
  LaunchNext data snapshot for legacy and AppKit builds.
- Use Release builds with the same architecture and signing configuration.
- Disable unrelated background indexing and allow the machine to reach idle.
- Perform one unrecorded warm-up, then record 10 runs per build.
- Record cold and warm launch cohorts separately. Do not combine them.
- Exclude headless CLI/TUI and silent login-item launches from first-frame
  cohorts; those modes intentionally do not present an initial launcher frame.

Never benchmark against the developer's live data without first making a
read-only snapshot. Do not commit snapshots or Instruments traces.

## Signposts

| Signpost | Starts | Ends | Interpretation |
| --- | --- | --- | --- |
| `app_entry_to_did_finish_launching` | earliest current app-delegate construction | `applicationDidFinishLaunching` entry | lifecycle bootstrap; final AppKit main will move start before `NSApplicationMain` |
| `launch_to_first_interactive_frame` | earliest current app-delegate construction | first visible grid frame accepting input | primary perceived-launch metric; final AppKit main will move start before `NSApplicationMain` |
| `catalog_scan` | order-preserving scan dispatch | main-thread catalog/layout publication | full application index |
| `catalog_cache_schedule` | cache preparation call | synchronous scheduling/preload return | scheduling cost only; never report as cache completion |
| `window_show` / `window_hide` | transition intent | visual settle | current window transition |
| `folder_open` / `folder_close` | folder state-machine intent | proxy/content settle | added with native folder overlay |
| `page_animation` | page animation begins | target page settles | added with frame-budget counters |

The current in-memory cache has no persistent first-cache-result signal.
`catalog_cache_schedule` must not be reported as full cache completion until the
cache manager exposes a completion callback.

## Capture

1. Build LaunchNext in Release configuration.
2. Open Instruments and choose the App Launch or Points of Interest template.
3. Select the exact built executable, not a previously installed copy.
4. Record one launch/scan cycle and stop after catalog publication settles.
5. Export the trace outside the repository using a build/cohort/run identifier.
6. Repeat for 10 recorded runs per cohort and implementation.

For animation traces, capture the active display refresh rate and exercise one
page or folder transition at a time. Frame callbacks will later publish only
aggregate frame count, late-frame count, and maximum delta; never log one event
per frame.

## Reporting

For every interval report p50, p95, minimum, maximum, hardware, macOS version,
catalog size, mode, display refresh rate, and whether the run was cold or warm.

The 5x result is valid only when:

```text
legacy median / AppKit median >= 5.0
```

for both cold first interactive frame and first complete index under comparable
conditions. If either result misses the threshold, publish the measured value
and profile the bottleneck before changing implementation or product copy.
