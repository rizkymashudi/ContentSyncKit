# ADR-0001: Original, dependency-free implementation

**Date**: 2026-08-26
**Status**: accepted
**Deciders**: rizky mashudi

## Context

ContentSyncKit is published as a reusable Swift package and is also the subject of written
articles. Both uses require that everything in the repository is publishable without
encumbrance: no copied source, no inherited identifiers or configuration, and no third-party
dependencies in the package target.

Setting that boundary at the first commit is far cheaper than auditing for it later, and it
has to be explicit because an AI agent working in this repository will otherwise reach for
the fastest available implementation rather than the one that can be published.

## Decision

Everything in this repository is written for it.

No source, identifiers, API signatures, licence headers, or configuration is copied in from
another codebase. The package target declares zero third-party dependencies. General
engineering knowledge is not an artifact and transfers freely; artifacts do not.

## Alternatives Considered

### Alternative 1: Adapt an existing open-source sync library
- **Pros**: Fastest path to a working package; proven design.
- **Cons**: Inherits licence obligations, an existing API shape, and design constraints chosen
  for someone else's problem.
- **Why not**: The reasoning is the deliverable here, not the result. Adapting skips exactly
  the part worth writing about.

### Alternative 2: Depend on a third-party networking or persistence library
- **Pros**: Less code to write and maintain.
- **Cons**: Every consumer inherits that dependency and its release cadence. Zero dependencies
  is a genuine selling point for a distributable SDK.
- **Why not**: The problems this package solves are within reach of Foundation alone.

## Consequences

### Positive
- The package can be published, discussed, and used by others with no encumbrance.
- Every design choice is justified from first principles, which is the material the articles need.
- Consumers take on no transitive dependencies.

### Negative
- Slower. Every layer is written from scratch.
- Some solutions will be derived worse before they are derived better.

### Risks
- **Unconscious carry-over of a distinctive name or signature from code read elsewhere.**
  Mitigation: domain vocabulary is defined independently (ADR-0006), nothing is introduced by
  paste, and the agent guidelines forbid reproducing external identifiers.
