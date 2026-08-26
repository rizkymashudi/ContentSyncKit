# ADR-0004: Verification covers the package and the Example app

**Date**: 2026-08-26
**Status**: accepted
**Deciders**: rizky mashudi

## Context

`swift build` and `swift test` verify the package in isolation, but a library's real contract
is what consumers can compile against. `Example/ContentKitExample.xcodeproj` consumes the
package by relative path, so it is the only place the public API is exercised the way a client
exercises it. A change can compile inside the package and still break every consumer.

## Decision

No change is complete until both the package (`swift build`, `swift test`) and the Example app
(`xcodebuild ... build test` on the `ContentKitExample` scheme) succeed. The agent harness gates
completion claims on both.

## Alternatives Considered

### Alternative 1: Package only
- **Pros**: Fast — no simulator boot, hooks stay responsive.
- **Cons**: Public API breakage is invisible until someone opens the Example app manually.
- **Why not**: The public surface is the product (ADR-0002); leaving it unverified defeats the
  package's purpose.

## Consequences

### Positive
- Public API regressions surface in the same change that causes them.
- The Example app cannot silently rot into a non-compiling demo.

### Negative
- Verification is materially slower; simulator boot dominates the loop.
- The harness needs a pinned simulator destination, which drifts as Xcode updates.

### Risks
- **Slow gates get skipped under pressure.** Mitigation: the package-only commands stay fast
  for inner-loop work; the full gate runs before any completion claim.
