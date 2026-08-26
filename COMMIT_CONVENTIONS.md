# Commit Conventions

This project follows [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/), **subject line only**.

## Format

```
<type>(<scope>): <subject>
```

One line. No body, no footer.

### Rules

- Max 72 characters, total.
- Imperative mood ("add", not "added" or "adds").
- Lowercase start, no trailing period.
- One logical change per commit. Do not mix a refactor with a feature.
- If the change needs a paragraph to explain, it is too big — split it into several commits.

## Types

| Type | Use for |
| --- | --- |
| `feat` | New user-facing capability |
| `fix` | Bug fix |
| `refactor` | Restructuring with no behavior change |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests only |
| `docs` | Documentation, code comments, README |
| `style` | Formatting, whitespace, SwiftLint fixes — no logic change |
| `build` | Xcode project settings, `Package.swift`, dependencies, signing config |
| `ci` | CI pipelines and automation scripts |
| `chore` | Housekeeping that fits nowhere else (`.gitignore`, file moves) |
| `revert` | Reverting a previous commit |

## Scopes

Scope is optional but preferred. Use the module or feature area:

| Scope | Covers |
| --- | --- |
| `app` | `ContentKitExample/` — the SwiftUI app target |
| `synckit` | `ContentSyncKit/Sources/` — the local Swift package |
| `tests` | `ContentKitExampleTests/`, `ContentSyncKitTests/` |
| `uitests` | `ContentKitExampleUITests/` |
| `xcodeproj` | `ContentKitExample.xcodeproj` project/scheme changes |
| `assets` | `Assets.xcassets`, icons, colors |

For a change spanning several scopes, omit the scope rather than listing many.

## Breaking changes

Public API changes in `ContentSyncKit` are breaking changes for consumers. Mark them with `!` after the type/scope, and name the affected API in the subject:

```
feat(synckit)!: require an explicit SyncPolicy in SyncClient.start
refactor(synckit)!: drop deprecated SyncClient.sync(completion:)
```

## Issue references

Put the reference in the subject line when a commit maps to an issue:

```
fix(app): keep list state across scene phase changes (#22)
```

## Examples

```
feat(synckit): add incremental content diffing by hash
fix(app): keep ContentView list state across scene phase changes
test(synckit): cover retry backoff on transient network failure
build(xcodeproj): add ContentSyncKit as a local package dependency
refactor(app): extract sync status view out of ContentView
docs: add commit conventions
chore: ignore xcuserdata from version control
```

## Anti-patterns

Avoid these — they carry no information:

- `update files`, `fix stuff`, `wip`, `misc changes`
- `Initial Commit` for anything after the first commit
- Commits mixing generated Xcode project churn with source changes — commit `project.pbxproj` noise separately under `build(xcodeproj)`
