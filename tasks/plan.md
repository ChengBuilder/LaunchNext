# Implementation Plan: Native AppKit Rebuild

## Overview

Migrate LaunchNext from a SwiftUI-hosted application to native AppKit in
buildable, reversible phases. Reuse the existing Core Animation grid/folder
engines, preserve persisted data and automation contracts, and validate every
user-visible replacement before removing its legacy path.

The detailed product and visual specification is
[`docs/appkit-rebuild-spec.md`](../docs/appkit-rebuild-spec.md).

## Dependency Order

```text
spec + baseline
└── tests + performance instrumentation
    └── native application/window shell
        └── native launcher surface
            ├── search + hidden catalog
            ├── Dock integration boundary
            └── native folder overlay
                └── settings/onboarding/update views
                    └── SwiftUI deletion
                        └── performance and visual release gate
```

## Phase 0: Specification And Baseline

- Record architecture, LaunchOS evidence, migration boundaries, performance
  contract, and phase checkpoints.
- Record the baseline SwiftUI surface and build prerequisites.
- Push a documentation-only commit.

Checkpoint:

- Owner reviews open questions and accepts/revises the proposed specification.
- Repository contains no behavior changes.

## Phase 1: Safety Rails

- Add an XCTest target and fixture-only defaults/persistence support.
- Add pure contracts for layout, catalog visibility, and Dock capability.
- Add `os_signpost` launch/index/animation intervals and a repeatable benchmark
  runbook.
- Capture legacy behavior and performance baselines before switching UI.

Checkpoint:

- Focused tests pass and Debug/Release builds succeed outside the sandboxed icon
  compiler limitation.
- Signposts can be captured without changing normal UI behavior.

## Phase 2: Native Application Shell

- Add a pure AppKit entry point and retain the existing `AppDelegate` services.
- Introduce `LauncherWindowController` and a minimal `LauncherViewController`.
- Keep the legacy SwiftUI content behind a development switch while the native
  surface is incomplete.
- Preserve hotkey, hot-corner, multi-display, CLI/TUI, login-item, appearance,
  and show/hide behavior.

Checkpoint:

- Both paths launch from the same stored data with no schema changes.
- Window/focus/show/hide integration tests and manual checks pass.

## Phase 3: Native Launcher Surface

- Compose native material/background, `NSSearchField`, settings button,
  `CAGridView`, page indicator, empty/loading states, and FPS overlay.
- Move representable callback wiring into a dedicated grid coordinator.
- Implement deterministic `LauncherLayoutPolicy` and keyboard/accessibility
  behavior.
- Make the native surface the default once launcher parity passes.

Checkpoint:

- Launch, search, page, reorder, create/move/dissolve folder, context menu,
  controller, gesture, and external Dock drag flows pass.

## Phase 4: Hidden Search And Dock Command

- Separate the complete catalog from visible layout filtering.
- Add the persisted, default-off `showHiddenAppsInSearch` preference and badge
  hidden results without mutating layout.
- Add a `DockIntegration` capability boundary and context-menu command.
- Integrate the owner-supplied LaunchOS persistent Dock helper only after source
  and permission behavior are reviewed.

Checkpoint:

- Hidden search behavior has unit/integration coverage.
- Dock drag always works; Add to Dock is either verified or explicitly disabled
  with an actionable explanation.

## Phase 5: Native Folder Experience

- Build `FolderOverlayViewController` around the existing
  `CAFolderGridView`.
- Implement source-linked open/close geometry, title editing, page/vertical
  layouts, drag-out handoff, focus trapping, and interruption settlement.
- Respect Reduce Motion and Reduce Transparency.

Checkpoint:

- Folder workflows pass mouse, keyboard, controller, and accessibility checks.
- 60/120 Hz traces meet the frame budget on representative hardware.

## Phase 6: Native Settings And Secondary Views

- Build a split-view settings window with independent AppKit section
  controllers.
- Migrate onboarding, backup/import/export panels, update/release notes, hidden
  app management, gesture configuration, and about/development tools in small
  vertical slices.
- Reuse existing localization keys and service methods.

Checkpoint:

- Every currently reachable setting has parity or an owner-approved removal
  decision.
- Preferences survive upgrade/downgrade testing without reset.

## Phase 7: Remove SwiftUI

- Delete legacy views, representables, SwiftUI-only helpers, feature switch, and
  hosting code.
- Replace remaining SwiftUI types in models/helpers with Foundation/AppKit types.
- Enforce source and linked-binary static gates in CI/release scripts.

Checkpoint:

- `rg` and `otool` gates report no SwiftUI.
- Full regression matrix passes and the legacy build can still read the same data
  for rollback validation.

## Phase 8: Performance And Release Qualification

- Run comparable launch/index and animation traces.
- Fix measured bottlenecks only; publish p50/p95 results and hardware/catalog
  details.
- Complete LaunchOS visual comparison, VoiceOver, multi-display, appearance,
  Reduce Motion/Transparency, and packaging checks.

Checkpoint:

- The 5x claim is supported by comparable data or product copy is corrected.
- App is ready for staged distribution with rollback instructions.

## Git Checkpoints

Each phase follows:

```text
implement -> focused tests -> full build/static gates -> review diff
          -> atomic commit(s) -> push refactor/appkit-foundation
```

Do not push a phase with a known compile error, data migration ambiguity, disabled
test, or unreviewed secret/generated artifact.

## Risks And Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| No existing tests | regressions in layout/data | add fixture-based tests before behavior changes |
| `AppStore` owns too many concerns | UI replacement becomes tangled | extract only tested boundaries needed by each slice |
| Two UI paths drift | prolonged migration cost | explicit parity gates and final static deletion gate |
| Dock persistence uses unsupported behavior | OS breakage/user trust | capability boundary; prefer shared reviewed LaunchOS source |
| 5x target is unmeasured | misleading release claim | comparable signpost protocol and raw result retention |
| Settings translation becomes another monolith | high maintenance cost | one section/controller per slice, shared control factories only after repeated use |
| Folder animation interrupted mid-state | stuck input/visual state | state machine + deterministic settle tests |
| AppIcon build fails in sandbox | incomplete automated verification | use temporary DerivedData; require manual/full Xcode build checkpoint |

## Review Gate

Implementation starts after the owner reviews the four open questions in the
specification. Answers that change scope must update the spec and this plan before
code changes.
