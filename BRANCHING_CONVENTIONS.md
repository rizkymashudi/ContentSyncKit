# Branching Conventions

This project uses a trunk-based flow: `main` is the only long-lived branch, and every
change lands on it through a short-lived branch. Branch names reuse the type vocabulary
from [Commit Conventions](COMMIT_CONVENTIONS.md).

## Format

```
<type>/<short-description>
```

Optionally with a scope, when the change is confined to one area:

```
<type>/<scope>/<short-description>
```

### Rules

- Max 50 characters, total.
- Lowercase only. Words separated by `-`, segments by `/`.
- No trailing slash, no `_`, no spaces, no uppercase.
- Imperative or noun phrase, not a sentence: `feat/incremental-diffing`, not `feat/i-am-adding-diffing`.
- One branch per logical change. If the branch needs two sentences to describe, split it.
- Delete the branch after it merges.

## Types

Same set as commit types, so the branch tells you what kind of change to expect:

| Type | Use for |
| --- | --- |
| `feat` | New user-facing capability |
| `fix` | Bug fix |
| `refactor` | Restructuring with no behavior change |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests only |
| `docs` | Documentation, code comments, README, agent instructions |
| `style` | Formatting, whitespace, SwiftLint fixes — no logic change |
| `build` | Xcode project settings, `Package.swift`, dependencies, signing config |
| `ci` | CI pipelines and automation scripts |
| `chore` | Housekeeping that fits nowhere else (`.gitignore`, file moves, tooling) |
| `revert` | Reverting a previous change |

A branch usually carries several commits of the same type. When types genuinely mix,
name the branch after the type of the change's *purpose*, not its largest diff — a
`feat` branch may still contain a `test` and a `build` commit.

## Scopes

The scope segment is optional and uses the same values as commit scopes:
`app`, `synckit`, `tests`, `uitests`, `xcodeproj`, `assets`.

Use it when it disambiguates:

```
fix/app/list-state-across-scene-phase
refactor/synckit/extract-retry-policy
```

Omit it when the change spans several scopes, or when the description already says
where the change lives.

## Issue references

When a branch maps to an issue, put the number first in the description segment:

```
fix/22-list-state-across-scene-phase
feat/synckit/31-incremental-diffing
```

## Release and hotfix branches

- `release/x.y.z` — only when cutting a version needs stabilization commits before the tag.
- `hotfix/x.y.z-<short-description>` — a fix branched from a release tag rather than `main`.

Neither is used for ordinary work. Everything else branches from the current `main`.

## Examples

```
feat/synckit/incremental-content-diffing
fix/app/list-state-across-scene-phase
test/synckit/retry-backoff-coverage
build/xcodeproj/link-local-package
docs/ai-agent-harness
docs/branching-conventions
chore/ignore-xcuserdata
refactor/synckit/extract-sync-status
release/1.2.0
hotfix/1.2.1-crash-on-empty-payload
```

## Anti-patterns

Avoid these — they carry no information or fight the tooling:

- `wip`, `test`, `new`, `temp`, `fix2`, `rizky-branch`, `my-changes`
- Personal-name prefixes (`rizky/add-diffing`) — the author is already in the commit metadata
- Bare descriptions with no type (`add-diffing`)
- Branches that outlive their merge, or accumulate unrelated work over weeks
- Reusing a merged branch name for new work
