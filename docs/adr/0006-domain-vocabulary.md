# ADR-0006: Domain vocabulary: Content, Bundle, Manifest

**Date**: 2026-08-26
**Status**: proposed
**Deciders**: rizky mashudi

## Context

ADR-0001 requires every identifier to be original to this repository, and the agent
guidelines need concrete type names to reference. The package's own name already commits it
to content synchronisation, so the vocabulary should follow from that. The background story the articles will use is not yet
fixed, which is why this record is `proposed`.

## Decision

Domain entities are `ContentItem`, `ContentBundle`, `Manifest`, `SyncPolicy`, and `SyncError`.
Repository protocols are `ContentRepository` and `ManifestRepository`. The public facade is
`ContentSyncClient`.

## Alternatives Considered

### Alternative 1: Resource / Catalog / Revision
- **Pros**: More neutral; reads as a generic remote-resource cache.
- **Cons**: Drifts from the package name, so readers hold two vocabularies at once.
- **Why not**: `ContentSyncKit` whose entities are all `Resource*` invites the question of why.

### Alternative 2: Defer until the article framing is fixed
- **Pros**: Names would follow the narrative exactly.
- **Cons**: Blocks every guideline file that needs concrete names.
- **Why not**: Renaming later is a mechanical change; blocking now is not.

## Consequences

### Positive
- Names follow from the package name, so the API explains itself.
- Guideline and example files can be written with concrete types immediately.

### Negative
- If the article framing lands on a different domain, a rename touches every guideline file.

### Risks
- **Status is `proposed`, but the names are already written into
  `docs/ai-guidelines/ARCHITECTURE.md`.** Mitigation: rename before implementation begins, while
  the cost is find-and-replace across documentation rather than across source and tests.
