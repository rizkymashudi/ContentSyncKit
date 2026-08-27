# ContentSyncKit — Agent Instructions

Canonical instructions for **any** AI coding agent working in this repository: Claude Code,
Codex, Cursor, Copilot, Aider, or a human following the same rules.

Tool-specific files (`CLAUDE.md`, `.claude/`) point here or enforce what is written here. They
never restate it — a second copy drifts from the first.

Before making code changes, read `SKILL.md` for the full project guidance.

## Detailed guidelines

- `docs/ai-guidelines/WORKFLOWS.md` — classify the work first: bug fix, new feature, refactor, investigation-only, test-only.
- `docs/ai-guidelines/ARCHITECTURE.md` — project baseline, folder structure, module boundaries, layer responsibilities.
- `docs/ai-guidelines/LAYER.md` — one section per layer (SDK, Domain, Data, CoreNetwork, Dependencies, Shared). Read the section for the layer you are editing.
- `docs/ai-guidelines/TESTING.md` — TDD cycle, XCTest patterns, test doubles, fixtures, testability seams.
- `docs/ai-guidelines/EXAMPLES.md` — copyable implementation patterns.
- `docs/adr/` — why the architecture is shaped this way. Read before proposing a change to it.
- `COMMIT_CONVENTIONS.md`, `BRANCHING_CONVENTIONS.md` — git conventions.

## Important defaults

- New feature work creates a new unit under `Sources/ContentSyncKit` unless the user explicitly asks to extend an existing one.
- Do not add a UseCase layer. The facade calls repository protocols directly — see `SKILL.md` for the extraction threshold.
- Do not add a `public` symbol outside `SDK/`. If a test needs reach, use `@testable import`.
- Do not add third-party dependencies to the package target. Zero dependencies is a deliberate constraint.
- Do not weaken a lint rule, assertion, or test to make a check pass. Fix the code, or report the failure.

## Verification

Never claim a change works, is fixed, or passes without showing command output.

```sh
make verify        # build + test + lint — run this before claiming done
make build
make test
make lint
make verify-example   # demo app, when your change touches it
```

`make` targets are the portable contract. Every agent, every CI run, and every human uses the
same commands, so "it passes for me" means the same thing everywhere. The underlying commands
are `swift build`, `swift test`, `swiftlint lint --strict`, and `xcodebuild` — run them directly
if `make` is unavailable, but prefer the targets.

## Credential and config safety

Never read, search inside, summarize, print, quote, or expose values from:

- {{SECRET_PATHS}}

Naming these paths when explaining project structure is fine. If a task needs a value from one
of them, ask the user for a safe redacted excerpt instead.

`make check-secrets` scans staged changes for credential-shaped content. It runs in CI on every
push and pull request.

## How the rules are enforced

The rules above are enforced by tooling, not trust. Three layers, in order of how early they
catch a mistake:

| Layer | Scope | What it enforces |
|---|---|---|
| `.claude/hooks/` | Claude Code only | Blocks reads of credential paths, blocks edits to lint/format configs, blocks "done" when files were edited but nothing was verified |
| `make` targets | Any agent, any tool, locally | Build, test, lint, secret scan — the same checks, runnable on demand |
| `.github/workflows/ci.yml` | Every push and pull request | The same checks again, as a gate nothing can skip |

If your tool has no hook system, the `make` targets and CI are your gate. Run `make verify`
before reporting work complete. An agent that cannot be blocked locally is still accountable to CI.

## Reporting work

- State what you changed, what you ran, and what the output was.
- If something is unverified — no simulator, no toolchain, a step you skipped — say so explicitly
  rather than omitting it.
- If part of a task is blocked, finish everything else and name what you left out and why.
