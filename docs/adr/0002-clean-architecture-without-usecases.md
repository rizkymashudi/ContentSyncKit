# ADR-0002: Clean Architecture without a UseCase layer

**Date**: 2026-08-26
**Status**: accepted
**Deciders**: rizky mashudi

## Context

ContentSyncKit is a distributable SPM library, not an application. It has one public
facade and one consumer path, so the canonical Clean Architecture question — where do
application business rules live — has a different answer than it does in an app with many
ViewModels sharing use cases. Evidence from comparable SDK code showed a UseCase layer in
which every type was a passthrough: a protocol, a struct, an injected repository, and an
`execute()` that forwarded a single repository call, carrying no policy of its own.

## Decision

The package uses the layer chain `SDK -> Domain <- Data -> CoreNetwork` with assembler-based
dependency injection, and no `Domain/UseCases/`. Facade methods delegate directly to
repository protocols, bounded by a written extraction threshold.

## Alternatives Considered

### Alternative 1: Full canonical layering with UseCases
- **Pros**: Immediately recognisable to reviewers; a named home for orchestration; policy
  testable without going through the public API.
- **Cons**: One type per public method, each forwarding a single call. Tests at that layer
  assert only that a mock was called.
- **Why not**: A layer holding no policy looks architectural while providing none of the
  benefit. That is worse than its absence, because it misleads.

### Alternative 2: Flat Client/Engine/Transport/Store design
- **Pros**: Fewer layers; designed for Swift 6.2 from scratch rather than adapted.
- **Cons**: Loses the repository boundary that makes local/remote substitution and test
  seams straightforward.
- **Why not**: Discards a proven boundary to solve a problem the package does not have.

## Consequences

### Positive
- The dependency rule is unaffected — it governs direction, not layer count.
- No passthrough types, no ceremony per public method.
- Debugging and article readers trace `facade -> repository`, one hop instead of two.

### Negative
- The facade carries two responsibilities: public boundary and application policy. That is
  a genuine deviation, defensible only while the policy stays trivial.
- Orchestration cannot be unit-tested below the public API.
- Articles describe an architecture one layer off the canonical diagram, and must say why.

### Risks
- **Erosion: the facade becomes the path of least resistance and grows unbounded.**
  Mitigation: a threshold rule in `docs/ai-guidelines/ARCHITECTURE.md` and in `SKILL.md`, so
  the agent enforces it on every change — a facade method that orchestrates more than two
  collaborators, or branches on policy, extracts to a named type in `Domain/`.
- **Business rules leaking into `Data/` instead.** Mitigation: named in the anti-pattern
  table as an architecture bug, not a style preference.
