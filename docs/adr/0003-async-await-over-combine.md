# ADR-0003: async/await and actors over Combine

**Date**: 2026-08-26
**Status**: accepted
**Deciders**: rizky mashudi

## Context

The package deploys to iOS 15+ and is built with the Swift 6.2 toolchain under strict
concurrency. Both Combine and structured concurrency are available at that floor, so the
asynchrony model is an open choice rather than one the platform makes for us. It has to be
decided once, at the boundary, because it propagates through every protocol in the package.

## Decision

All repository and data-source protocols are `Sendable` and use `async throws`. Mutable
state lives in actors. Domain entities are `Sendable` value types. No Combine, no completion
handlers, no locks around shared mutable state.

## Alternatives Considered

### Alternative 1: Combine publishers
- **Pros**: Mature; familiar; composes multi-stage pipelines well.
- **Cons**: Inherits a constraint the deployment target does not impose. Bridges awkwardly to
  strict concurrency and pushes cancellation handling onto the consumer.
- **Why not**: Reproducing a workaround for a platform limitation that no longer exists.

### Alternative 2: Mixed — async facade, Combine internals
- **Pros**: Consumers get a modern API; internals could reuse pipeline patterns.
- **Cons**: Two concurrency models in one package, with a bridge layer to maintain.
- **Why not**: The bridge costs more than either model alone.

## Consequences

### Positive
- Cancellation propagates for free through `try await`.
- The compiler enforces data-race safety rather than review catching it.
- `async let` expresses concurrent independent fetches directly.

### Negative
- Reactive-pipeline experience does not transfer into this codebase.
- `@unchecked Sendable` escape hatches need written justification, which is friction by design.

### Risks
- **Strict concurrency surfaces errors that are cheap early and expensive late.** Mitigation:
  it is on from the first commit, so no migration is ever needed.
