---
name: ContentSyncKit
description: Use this skill for ContentSyncKit work on iOS 15+ / Swift 6.2 involving feature development, bug fixes, refactors, tests, or project maintenance.
---

# ContentSyncKit Project Guidance

## Core workflow

- Read nearby implementation first and follow the existing module style.
- Keep changes scoped to the requested feature, bug fix, or maintenance task.
- Prefer existing project helpers, naming, dependency injection, navigation, networking, and state-management patterns.
- Do not perform broad architecture rewrites unless the user explicitly requests them.
- Classify the request before coding, then read the matching detailed guideline.

## Detailed guidelines

- `AGENTS.md` is the canonical entry point for every agent tool. This file is the detailed version.
- Read `docs/ai-guidelines/WORKFLOWS.md` first to classify the task.
- Read `docs/ai-guidelines/ARCHITECTURE.md` when creating or changing structure.
- Read the section of `docs/ai-guidelines/LAYER.md` matching the layer you edit.
- Read `docs/ai-guidelines/TESTING.md` when adding or changing tests.
- Read `docs/ai-guidelines/EXAMPLES.md` when creating new code or when a copyable pattern would reduce ambiguity.

## Architecture

```text
SDK/           public facade — ContentSyncClient, the entire public API
Domain/        entities + repository protocols; depends on nothing
Data/          DTOs, mapping, data sources, repository implementations, storage, cache
CoreNetwork/   NetworkClient, middleware chain, transport models
Dependencies/  assemblers that construct the graph
Shared/        cross-layer utilities; stays empty until two independent layers need a type
```

- Target platform: iOS 15+, built with the Swift 6.2 toolchain under strict concurrency.
- Dependency rule: `SDK -> Domain <- Data -> CoreNetwork`. `Domain` depends on nothing; nothing depends upward.
- Dependencies are constructed in assemblers under `Dependencies/` and injected through initializers. No DI container, no service locator, no singletons.

## Policies

- No UseCase layer. The facade calls repository protocols directly. Facade methods delegate only; anything that orchestrates more than two collaborators, or branches on policy, extracts to a named type in `Domain/` (`SyncCoordinator`, `ContentResolver`) — never to a type-per-method UseCase layer.
- `public` appears only in `SDK/` and on the `Domain` entities the API returns. Everything else is `internal`; tests reach it with `@testable import`.
- DTOs are `Codable` and never leave `Data/`. `Domain` entities are not `Codable`. Mapping happens in `Data/` in pure functions. A DTO in a `Domain` signature is a bug, not a nit.
- A type earns a place in `Shared/` only when two mutually-independent layers need it. Anything else lives in the layer that owns it.

## Credential and config safety

Never read, search inside, summarize, print, quote, or expose values from:

- {{SECRET_PATHS}}

Naming these paths when explaining project structure is fine. If a task needs a value from them, ask the user for a redacted excerpt.

## Implementation preferences

- async/await throughout: every public method is `async throws`. Mutable state lives in an `actor`; entities are `Sendable` value types. No Combine, no completion handlers, no locks around shared mutable state.
- The public API fails with `SyncError` only. Transport and decoding errors are mapped at the `Data` boundary and never surface to callers.
- Never log manifest contents, auth headers, or full URLs carrying query parameters.
- No user-facing strings in the package. Errors carry cases and codes, not display text — localization is the host app's job.
- Add or update focused tests when changing behavior with meaningful risk.
- Prefer XCTest with deterministic fixtures instead of live services.

## Verification

Use the `make` targets. They are the portable contract — every agent, every CI run, and every
human runs the same thing, so "it passes for me" means the same everywhere.

- `make verify` — build, test, lint, secret scan. Must pass before any completion claim.
- `make verify-example` — additionally required when the change touches the demo app.
- `make test` / `make build` / `make lint` — individual steps while iterating.
- Never weaken `.swiftlint.yml` to make a check pass. Fix the code, or report the failure.

Underlying commands are `swift build`, `swift test`, `swiftlint lint --strict`, and `xcodebuild`;
run them directly only if `make` is unavailable.

## Git

- Commit only when asked. Title format: `type(scope): subject`, per `COMMIT_CONVENTIONS.md`.
- Branch names mirror commit types, per `BRANCHING_CONVENTIONS.md`.
