# Native AppKit Rebuild Tasks

The active task should be the first unchecked item whose dependencies are
complete. Every task must leave the project buildable.

## Phase 0: Documentation

- [x] Audit SwiftUI/AppKit boundaries and existing native renderers.
- [x] Inspect the installed LaunchOS bundle, native hierarchy, and visual assets.
- [x] Define architecture, visual rules, performance contract, and migration
  boundaries.
- [x] Record ADR-0001 and the phased implementation plan.
- [x] Owner authorized implementation to continue; unresolved questions remain
  release gates.
- [x] Push the verified Phase 0 documentation commit (`95fd6da`).

## Phase 1: Safety Rails

- [x] Add an isolated SwiftPM XCTest harness for pure AppKit foundation
  contracts.
  - Acceptance: tests have no dependency on live LaunchNext user data.
  - Verify: `swift test` runs with an isolated HOME and scratch path, and an
    isolated-suite sentinel never appears in standard defaults.
- [x] Add failing tests for current layout policy examples.
  - Acceptance: compact/full-screen boundary cases and stable geometry are
    specified.
  - Verify: tests fail before `LauncherLayoutPolicy` exists.
- [x] Implement `LauncherLayoutPolicy` as pure geometry.
  - Acceptance: all layout examples pass with no AppKit view dependency.
  - Verify: focused XCTest plan passes.
- [x] Add failing hidden-catalog/search tests.
  - Acceptance: default exclusion and opt-in inclusion are specified.
  - Verify: tests fail against current prune-on-hide behavior.
- [x] Add signpost intervals and benchmark runbook.
  - Acceptance: launch, first frame, scan, cache scheduling, and window
    animation intervals appear
    in Instruments without logging user paths.
  - Verify: focused typecheck plus manual Instruments capture outside the Codex
    sandbox; full Xcode build currently stops only when the outer sandbox blocks
    the existing SwiftData macro plugin.
- [ ] Commit, review, and push Phase 1.

## Phase 2: Native Shell

- [ ] Add an AppKit entry point while preserving headless CLI/TUI startup.
- [ ] Add `LauncherWindowController` and move window creation/configuration into
  it without changing frame or show/hide behavior.
- [ ] Add minimal `LauncherViewController` and a development-only native/legacy
  UI switch.
- [ ] Test window activation, focus, show/hide notifications, and teardown.
- [ ] Manually verify login launch, hotkey, hot corner, multi-display, menu/Dock
  visibility, and appearance changes.
- [ ] Commit, review, and push Phase 2.

## Phase 3: Native Launcher Surface

- [ ] Add native surface/material and toolbar with search/settings controls.
- [ ] Add `CAGridCoordinator` and move callbacks out of
  `CAGridViewRepresentable`.
- [ ] Add deterministic page indicator, loading, empty, search-empty, and FPS
  views.
- [ ] Implement search debounce, focus, selection, Return/Escape, and controller
  routing in AppKit.
- [ ] Add accessibility elements/actions and Reduce Motion/Transparency behavior.
- [ ] Verify launch, paging, reordering, folder creation/move/dissolve, menus,
  controller, gesture, and external Dock drag.
- [ ] Make the native launcher the default, then commit/review/push Phase 3.

## Phase 4: Hidden Search And Dock

- [ ] Introduce a complete catalog representation without changing saved layout.
- [ ] Implement catalog-to-visible-layout filtering with passing migration tests.
- [ ] Add default-off `showHiddenAppsInSearch` preference and settings control.
- [ ] Render hidden search results with a non-color-only badge and restricted
  actions.
- [ ] Add `DockIntegration` capability interface and Add to Dock context item.
- [ ] Review/integrate owner-supplied LaunchOS Dock source or document unsupported
  capability.
- [ ] Commit, review, and push Phase 4.

## Phase 5: Folder Overlay

- [ ] Add folder presentation state machine and failing interruption tests.
- [ ] Add native folder backdrop, material/clip views, title editor, and
  `CAFolderGridView` coordinator.
- [ ] Implement captured source/destination geometry and reversible proxy-layer
  animation.
- [ ] Implement paged/vertical layout, drag-out handoff, rename, keyboard,
  controller, and context actions.
- [ ] Verify Reduce Motion/Transparency, focus, VoiceOver, and 60/120 Hz traces.
- [ ] Commit, review, and push Phase 5.

## Phase 6: Settings And Secondary Views

- [ ] Add split-view settings window and shared section protocol.
- [ ] Migrate General and Interface sections.
- [ ] Migrate Layout, search, and hidden-app sections.
- [ ] Migrate activation, gesture, controller, sound, and voice sections.
- [ ] Migrate backup/import/export and application-source sections.
- [ ] Migrate update/release-notes, about, and development sections.
- [ ] Migrate onboarding and any remaining sheets/panels.
- [ ] Run preference compatibility matrix, then commit/review/push Phase 6.

## Phase 7: SwiftUI Removal

- [ ] Delete legacy launcher/folder/settings views and representables.
- [ ] Replace remaining SwiftUI-only model/helper types.
- [ ] Remove feature switch and hosting fallback.
- [ ] Add CI/release source and linked-binary gates.
- [ ] Run full regression and downgrade-read compatibility checks.
- [ ] Commit, review, and push Phase 7.

## Phase 8: Qualification

- [ ] Capture 10-run Release launch/index traces for legacy and AppKit builds.
- [ ] Profile and fix only measured startup/index/animation bottlenecks.
- [ ] Complete LaunchOS visual comparison in both modes and appearances.
- [ ] Complete multi-display, input, accessibility, update, backup, CLI/TUI, and
  packaging matrix.
- [ ] Publish measured performance report and rollback notes.
- [ ] Commit, review, and push Phase 8; prepare final merge/release review.
