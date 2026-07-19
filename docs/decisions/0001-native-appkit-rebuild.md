# ADR-0001: Rebuild The Presentation Layer With Native AppKit

## Status

Proposed

## Date

2026-07-19

## Context

LaunchNext is an interaction-heavy macOS launcher. Perceived quality depends on
startup latency, input response, animation cadence, drag behavior, focus, and
window semantics. The current application uses a SwiftUI lifecycle and a large
SwiftUI composition layer while its performance-critical grid and folder engines
already use `NSView`, Core Animation, and display links.

SwiftUI has made small interaction improvements expensive to profile and tune.
The product also needs precise source-linked folder animation, ProMotion-aware
updates, native drag/context menus, deterministic layout, and searchable hidden
applications.

## Decision

Replace the SwiftUI presentation layer with AppKit view/window controllers and
retain the proven AppKit/Core Animation grid engines. Migrate incrementally behind
a development switch until critical workflows have parity, then delete all
SwiftUI views, representables, lifecycle code, and build-time linkage.

Use Combine for observation during the migration. Preserve SwiftData schemas,
UserDefaults keys, CLI/TUI contracts, and existing application services. Split
`AppStore` only where a tested boundary directly supports a migration slice; do
not make a wholesale state-layer rewrite a prerequisite for the UI rebuild.

## Alternatives Considered

### Continue optimizing SwiftUI

Pros: smallest initial diff and settings UI stays intact.

Cons: retains the source of timing, lifecycle, animation, and bridging limits;
performance-critical behavior remains split across two UI systems.

Rejected because it does not meet the explicit no-SwiftUI end state.

### Rewrite the entire application and data layer at once

Pros: theoretically clean architecture.

Cons: discards working scan, persistence, input, CLI, grid, and folder code;
creates a long period with no buildable parity path and high data-regression risk.

Rejected in favor of replacing one user flow at a time.

### Keep SwiftUI only for settings

Pros: avoids translating the largest view immediately.

Cons: the binary still links SwiftUI and maintains two UI stacks indefinitely.

Rejected as a final architecture, allowed only as a temporary migration state.

## Consequences

- Window, focus, event routing, layout, animation, accessibility, and update
  scheduling become explicit and testable.
- Existing CAGrid/CAFolderGrid code is promoted from a hosted renderer to a native
  first-class view.
- Settings and onboarding require deliberate AppKit implementations rather than
  mechanical line-for-line translation.
- A new XCTest target and performance signposts are prerequisites for credible
  behavior and speed claims.
- Migration temporarily carries two UI paths, but each phase has a removal gate
  and the final static/link check prevents that state from becoming permanent.
- Persistent Add to Dock remains capability-gated because macOS has no stable
  public API for directly editing the Dock.

## Supersession

If the team later adopts another UI framework, write a new ADR that references
and supersedes this record. Do not edit the rationale retroactively.
