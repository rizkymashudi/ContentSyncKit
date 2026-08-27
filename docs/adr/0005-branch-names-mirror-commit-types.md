# ADR-0005: Branch names mirror commit types

**Date**: 2026-08-26
**Status**: accepted
**Deciders**: rizky mashudi

## Context

The repository already follows Conventional Commits, subject line only, documented in
`COMMIT_CONVENTIONS.md`. Branch naming had no convention at all, and the first branch needing
a name — the agent harness work — had no obvious precedent to follow.

## Decision

Branches are named `<type>/<short-description>`, or `<type>/<scope>/<short-description>` when
confined to one area, reusing the commit type and scope vocabulary. Trunk-based: short-lived
branches off `main`, deleted after merge. Rules live in `BRANCHING_CONVENTIONS.md`.

## Alternatives Considered

### Alternative 1: Personal or ticket prefixes (`rizky/...`, `CSK-12/...`)
- **Pros**: Common in team settings; maps to a tracker.
- **Cons**: Authorship is already in commit metadata, and there is no tracker.
- **Why not**: Encodes information that is either redundant or absent.

### Alternative 2: No convention
- **Pros**: Zero overhead.
- **Cons**: Branch lists become unreadable as soon as several exist.
- **Why not**: The cost of the rule is one line; the cost of no rule compounds.

## Consequences

### Positive
- One vocabulary for branches and commits; nothing new to learn.
- A branch name states the kind of change before any diff is read.

### Negative
- Branches whose commits genuinely mix types need a judgement call — named after the change's
  purpose, not its largest diff.

### Risks
- **Convention drifts because nothing enforces it.** Mitigation: recorded as a preference the
  agent applies when proposing branch names.
