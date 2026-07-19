# LaunchNext AppKit Rebuild Specification

Status: Proposed

Date: 2026-07-19

Target branch: `refactor/appkit-foundation`

## 1. Objective

Rebuild the LaunchNext presentation layer with native AppKit while preserving the
existing launcher data, automation, input, and localization behavior. The new UI
should follow the interaction hierarchy and visual restraint of the locally
installed LaunchOS 2.2.0 application without turning LaunchNext into a branded
copy of LaunchOS.

The final application must not import or link SwiftUI. Existing AppKit/Core
Animation renderers are migration assets and should be reused rather than
rewritten.

### User outcomes

- LaunchNext becomes interactive materially faster, with a measured goal of at
  least 5x for cold first launch and first full application index.
- Paging, drag previews, folder transitions, and hover/press feedback track the
  active display refresh rate, including 120 Hz ProMotion displays.
- An application can be dragged to the Dock. A context menu can request "Add to
  Dock" when a supported, user-authorized integration is available.
- Folder open and close transitions originate from the selected folder and
  preserve visual continuity.
- Layout uses the available window/screen area efficiently without crowding or
  clipping labels.
- Search can optionally include hidden applications without restoring them to
  the normal grid.
- Existing layouts, folders, hidden-app choices, preferences, CLI/TUI behavior,
  gestures, controller input, backups, and localization remain compatible.

## 2. Current Baseline

The repository is not a pure SwiftUI implementation. It is a SwiftUI host around
substantial AppKit infrastructure:

- `LaunchpadApp.swift` owns the AppKit window lifecycle but enters through a
  SwiftUI `App` and installs `LaunchpadView` with `NSHostingView`.
- `LaunchpadView.swift` owns main-screen composition, search, paging, selection,
  folder overlays, onboarding, and event wiring.
- `CAGridView`, `CAGridView+Layout`, and `CAGridView+Input` already provide an
  `NSView`/Core Animation grid, display-link paging, reordering, and external
  file-URL dragging.
- `CAFolderGridView` already provides an AppKit/Core Animation folder grid.
- `SettingsView.swift` is a 6,000+ line SwiftUI settings implementation and is
  the largest remaining UI migration surface.
- `AppStore.swift` combines catalog scanning, persistence, layout operations,
  preferences, update behavior, and transient UI state. It uses Combine and can
  remain observable without SwiftUI.
- There is currently no test target. A normal build also requires the updater
  executable to be built first.

Static baseline on 2026-07-19:

| Metric | Baseline |
| --- | ---: |
| Swift source | about 36,000 lines |
| Files with `import SwiftUI` | 14 |
| `NSHostingView` call sites | 2 |
| Unit/UI test targets | 0 |
| Deployment target | macOS 26.0 |

The first sandboxed baseline build reached asset compilation, then failed in
`ibtoold` while opening `AppIcon.icon` because CoreSimulator services are not
available in the automation sandbox. This is an environment limitation, not a
Swift compiler finding. A signed/manual Xcode build remains a release gate.

## 3. LaunchOS Reference

### Evidence source

The reference is the locally installed `/Applications/LaunchOS.app`, version
2.2.0 (build 405). The bundle identifies AppKit as the primary windowing stack.
Retained symbols and resources expose the following native hierarchy:

```text
LaunchpadWindowController
└── LaunchpadViewController
    ├── LaunchpadWindowSurfaceView
    ├── LaunchpadSearchView / LaunchpadTextField
    ├── LaunchpadContentView
    │   ├── LaunchpadPageIndicatorView
    │   ├── LaunchpadGroupView
    │   └── LaunchpadAppView
    └── opened-folder views
        ├── OpenedFolderBackdropView
        ├── OpenedFolderBlurView
        ├── OpenedFolderClipView
        ├── LaunchpadFolderView
        └── FolderAnimationProxyLayer
```

The resource catalog also confirms dedicated search, settings, folder, page,
empty-state, and settings-tab artwork. No LaunchOS source checkout was found on
this machine, so implementation must not assume behavior that cannot be observed
or supplied by the owner.

### Verified color tokens

These values come from LaunchOS `Assets.car`; use semantic token names in code
and allow AppKit appearance resolution to select light/dark values.

| Token | Light | Dark | Intended use |
| --- | --- | --- | --- |
| `accent` | system blue `#0088FF` | system blue | focus, selection, commands |
| `main` | `#FFFFFF` | about `#111111` | primary surface/content contrast |
| `window` | `#FFFFFF` | about `#20222E` | opaque fallback surface |
| `glassTint` | white at 10% | white at 2% | material tint, not a flat fill |
| `searchGlassTint` | `#111111` at 15% | `#111111` at 16% | search-field material overlay |
| `folderTint` | `#111111` at 5% | transparent | folder material tint |
| `folderHighlight` | white at 30% | white at 8% | folder edge/highlight |

LaunchNext should copy the semantic relationships, not hard-code a monochrome
palette. Standard `labelColor`, `secondaryLabelColor`, separators, and control
states remain system colors.

### Visual and interaction rules

1. **Surface first.** Use a single window/screen surface. Search, grid, page
   indicator, and folder overlay are layers of that surface, not nested cards.
2. **Native material.** Prefer `NSVisualEffectView` and macOS 26 material APIs.
   Keep flat-color fallbacks for Reduce Transparency and screenshots.
3. **Compact controls.** Search is a restrained pill-shaped system search field;
   settings and navigation commands use symbol-only `NSButton`s with tooltips.
4. **Content hierarchy.** Application icons are the dominant signal. Labels,
   page dots, and toolbar controls remain quiet and never compete with icons.
5. **Stable geometry.** Grid columns/rows, cell size, content insets, and folder
   bounds are computed from one layout policy. Hover and selection transforms do
   not participate in Auto Layout and cannot shift neighbors.
6. **Source-linked folders.** Opening creates a proxy from the selected folder
   frame, scales/translates it into the overlay, and cross-fades real content.
   Closing reverses the same geometry using the current source frame.
7. **Refresh-rate-aware animation.** Advance interactive paging and gesture
   following from `CADisplayLink`; do not use a 60 Hz timer. Core Animation owns
   non-interactive transforms and opacity.
8. **Accessibility.** Every application/folder is exposed as an accessibility
   element with name, role, selected state, and available actions. Reduce Motion
   replaces spring/scale travel with a short cross-fade.

### Reusable LaunchOS materials

The user has authorized reuse of assets from their LaunchOS application. Reuse is
still provenance-controlled:

- Allowed after review: semantic colors, generic search/settings/folder symbols,
  interaction timing, and unbranded layout/animation behavior.
- Keep LaunchNext identity: LaunchNext name, application icon, screenshots,
  update feed, bundle identifier, and product copy.
- Do not copy signing material, Sparkle keys, license state, analytics settings,
  or LaunchOS persistence files.
- If LaunchOS source for Dock integration or folder geometry is supplied later,
  copy it as source with a provenance note and adapt tests before enabling it.

## 4. Target Architecture

```text
NSApplication
└── AppDelegate
    ├── LauncherWindowController
    │   └── LauncherViewController
    │       ├── LauncherSurfaceView
    │       ├── LauncherToolbarView (NSSearchField + icon buttons)
    │       ├── CAGridView (existing engine)
    │       ├── PageIndicatorView
    │       └── FolderOverlayViewController
    │           └── CAFolderGridView (existing engine)
    ├── SettingsWindowController
    │   └── NSSplitViewController + section view controllers
    └── application services
        ├── ApplicationCatalog
        ├── LayoutRepository
        ├── LauncherSession
        ├── SearchController
        ├── PreferencesStore
        └── DockIntegration
```

### Dependency rules

- View controllers may observe `AppStore`/services with Combine, but model and
  persistence code must not import AppKit UI classes.
- `CAGridView` and `CAFolderGridView` receive explicit configuration values and
  callbacks. SwiftUI representables are temporary adapters only.
- UserDefaults keys and the SwiftData schema remain stable during the UI rebuild.
- UI state such as selection, open folder, field focus, and drag presentation
  belongs to `LauncherSession`/view controllers, not the persisted catalog.
- New functionality is introduced behind a development switch until its full
  user flow passes the phase checkpoint.

## 5. Feature Design

### Search including hidden applications

Current hidden applications are removed from `apps` and `items`, so the search
engine cannot discover them. Replace that representation with two views of one
catalog:

```text
complete discovered catalog
├── visible layout candidates -> normal grid/folders
└── hidden candidates --------> search only when preference is enabled
```

`showHiddenAppsInSearch` defaults to off for compatibility. Hidden search results
are transient, visually badged, launchable, and do not silently re-enter layout.
Their context menu offers Show in Finder and Unhide; destructive layout actions
are disabled until the app is unhidden.

### Dock integration

External URL drag already exists and remains the primary supported path. macOS
does not expose a stable public API that directly persists arbitrary applications
in the Dock. The context-menu command therefore uses a capability-based
`DockIntegration` boundary:

- `.externalDrag`: always available through the existing drag session.
- `.addPersistently`: enabled only when the shared LaunchOS implementation is
  available and passes the current OS/accessibility permission checks.
- Unsupported or denied operations show a precise native alert and never mutate
  `com.apple.dock` defaults directly as a fallback.

### Layout policy

One pure `LauncherLayoutPolicy` computes columns, rows, icon size, cell size,
content insets, toolbar height, and folder bounds from the visible frame and user
preferences. It must:

- preserve at least the configured minimum icon/label clearance;
- keep search and page indicators outside icon hit regions;
- use extra width for balanced outer insets before adding columns;
- clamp compact mode to its minimum content size;
- avoid changing column count during hover, drag, label edits, or search updates;
- produce deterministic results suitable for unit tests.

### Folder transition

Open and close use the same captured geometry:

1. Freeze the source folder layer presentation frame.
2. Add a proxy layer above the grid and a dim/material backdrop below it.
3. Animate proxy position, bounds, corner radius, and scale to folder bounds.
4. Cross-fade title and `CAFolderGridView` near the end of opening.
5. Disable grid hit testing while open; preserve keyboard focus inside the folder.
6. Reverse the path on close, resolving the source frame again if layout moved.

Interruption must settle to a valid fully-open or fully-closed state. Reduce
Motion uses opacity only.

## 6. Performance Contract

The 5x claim is a release criterion, not an assumption. Record signposts for:

- process start to `applicationDidFinishLaunching`;
- process start to first interactive grid frame;
- scan start to first cached result;
- scan start to complete catalog publication;
- icon decode/cache misses;
- folder open/close and page transition duration/missed frames.

Measure Release builds on the same Mac, user data snapshot, display, and power
state. Use one warm-up followed by 10 recorded runs and compare medians. Report
p50 and p95; retain raw signpost exports outside the repository.

| Budget | Acceptance |
| --- | --- |
| Cold first interactive frame | legacy median / AppKit median >= 5.0 |
| First complete index | legacy median / AppKit median >= 5.0 |
| Warm cached launch | p50 <= 150 ms or documented hardware-adjusted target |
| 120 Hz paging/folder animation | display-link cadence follows screen; >= 99% frames inside one refresh interval in the controlled trace |
| Main-thread stalls while scanning | no task >= 16 ms attributable to scanning/icon I/O |
| Memory | no unbounded icon/layer cache; document steady-state delta |

The initial optimization strategy is cache-first presentation, background catalog
validation, stable-ID diffs for grid layers, bounded icon caches, and no file I/O
from animation callbacks.

## 7. Commands

Build the updater once:

```bash
cd UpdaterScripts/SwiftUpdater
swift build --configuration release --arch arm64 --arch x86_64 --product SwiftUpdater
```

Build the application without signing:

```bash
HOME=/tmp/LaunchNextHome \
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project LaunchNext.xcodeproj \
  -scheme LaunchNext \
  -configuration Debug \
  -derivedDataPath /tmp/LaunchNextDerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

Migration static gates:

```bash
rg -n '^import SwiftUI|NSHosting(View|Controller)|NSViewRepresentable' LaunchNext
otool -L <built-app>/Contents/MacOS/LaunchNext | rg SwiftUI
```

The first command must return no matches and the second must not list
`SwiftUI.framework` before the final migration stage is accepted.

## 8. Testing Strategy

- Add an XCTest target before changing behavior.
- Unit test layout policy, search ranking/hidden inclusion, folder geometry,
  preference migration, and catalog-to-layout filtering.
- Integration test persistence compatibility with a fixture store and defaults
  suite; never use the developer's live `Data.store` or preferences.
- Add view/controller tests for search, keyboard navigation, context-menu
  availability, interrupted folder transitions, and Reduce Motion.
- Manually verify window/full-screen modes, multiple displays, mouse/trackpad,
  keyboard, VoiceOver, controller input, Dock drag, and appearance variants.
- Performance tests compare signpost metrics against the recorded legacy build.

## 9. Boundaries

Always:

- Keep every phase buildable and independently revertible.
- Preserve user data schemas and preference keys unless a tested migration ships
  in the same phase.
- Run the static gates, focused tests, and build before each phase commit.
- Push each completed phase to GitHub with its verification result.

Ask first:

- Change the SwiftData schema or delete stored user data.
- Add a third-party dependency or private framework.
- Copy proprietary LaunchOS source not already available in the local bundle.
- Enable an Accessibility-based persistent Dock integration by default.
- Change product branding, bundle identifier, signing, updater feed, or license.

Never:

- Modify Dock databases/defaults as an undocumented fallback.
- Claim a performance multiple without comparable measurements.
- Run migration tests against live user preferences or application data.
- Remove the legacy UI before critical flows have parity on the AppKit path.
- Commit signing keys, update keys, analytics identifiers, or generated build
  products.

## 10. Completion Criteria

- No source import, hosting bridge, build setting, or linked binary dependency on
  SwiftUI remains.
- All critical workflows in the phase matrix pass on AppKit.
- The visual QA checklist matches the LaunchOS reference hierarchy in compact and
  full-screen modes, light/dark appearances, and Reduce Motion/Transparency.
- Hidden-app search is preference-controlled and does not mutate layout.
- Dock drag works and persistent Add to Dock has an explicit supported/unsupported
  state.
- Folder transitions are reversible, interruption-safe, and refresh-rate aware.
- Performance report supports or explicitly rejects the 5x target with raw
  comparable measurements.
- Existing user data opens without reset and CLI/TUI snapshots remain compatible.
- Every phase is committed and pushed; final working tree is clean.

## 11. Open Questions For Owner Review

1. Please provide the LaunchOS source file(s) that implement persistent Add to
   Dock if that exact behavior must ship; only the installed binary is currently
   present.
2. Confirm whether the first public AppKit release may temporarily omit low-use
   settings sections behind the legacy development switch, or whether all
   settings require parity before any release.
3. Confirm the representative hardware/catalog used for the public 5x claim.
4. A runtime LaunchOS screenshot pass is still needed because launching GUI apps
   was denied by the current automation approval service. Token values above are
   bundle-verified; pixel geometry is provisional until that pass.
