# Layers

> **The code blocks in this file are normative shapes, not excerpts.** `Sources/ContentSyncKit/`
> is still a stub, so nothing here was copied from real code, and the types it names
> (`ContentSyncClient`, `DefaultContentRepository`, `ContentItem`, `SyncError`, `Manifest`)
> do not exist yet. Follow the *structure* and the rules; do not assume a symbol exists because
> it appears here. Replace each block with a real excerpt as the code lands, and delete this
> banner once every block is real.

Per-layer reference for `Sources/ContentSyncKit/`. `ARCHITECTURE.md` states the dependency
rule and the folder structure; this file states what each layer owns, the shape its code
takes, and what must be true before a change to it is done.

Read the section matching the layer you are editing. If a change spans two sections, it
probably crosses a boundary that should have been an interface — re-read the dependency
rule before continuing.

The layer chain is `SDK -> Domain <- Data -> CoreNetwork`, with `Dependencies` as the
composition root and `Shared` off to the side.

> Code blocks below are normative shapes, not excerpts — `Sources/ContentSyncKit/` is
> still a stub. Replace each with the smallest real example from this repo as soon as one
> exists, and delete this note when the last one is replaced.

---

## SDK

### Responsibility

Owns the entire public API: the facade type, its configuration, and its lifecycle. It
translates a consumer's call into repository calls and nothing more. It must never hold a
business rule that outlives a single method, and must never name a type from `Data` or
`CoreNetwork`.

### Rules

- `public` lives here and on the `Domain` entities this layer returns. Nowhere else.
- Depend on `Domain` repository protocols only. Concrete repositories arrive from an assembler.
- Every public method is `async throws` and fails with `SyncError`, never a transport or decoding error.
- A public initializer takes `Configuration`; an `internal` one takes the collaborators, and tests use that one.
- Naming: the facade is `ContentSyncClient`. Configuration and error types nest inside it — `ContentSyncClient.Configuration`, `ContentSyncClient.Error` — never flattened to `SyncConfiguration`. No `Manager`, no `SDK` suffix, no `Helper`.

### Canonical shape

```swift
public actor ContentSyncClient {
    private let content: any ContentRepository
    private let manifests: any ManifestRepository

    public init(configuration: Configuration) {
        let assembler = ModuleAssembler(configuration: configuration)
        self.init(
            content: assembler.contentRepository(),
            manifests: assembler.manifestRepository()
        )
    }

    init(content: any ContentRepository, manifests: any ManifestRepository) {
        self.content = content
        self.manifests = manifests
    }

    public func sync() async throws -> ContentBundle {
        let manifest = try await manifests.current()
        return try await content.bundle(for: manifest)
    }
}
```

Two collaborators, no branching: this stays in the facade. A third, or a policy branch,
triggers the extraction threshold in `ARCHITECTURE.md`.

### Talking to the next layer

- Call `Domain` through `any ContentRepository` / `any ManifestRepository` only.
- Inject via initializer; store privately; never reach for a shared instance.
- Nothing to map at this boundary — `Domain` entities are already the public currency.

### Common mistakes in this layer

| Mistake | Correct |
|---|---|
| `import` of a concrete repository or `CoreNetwork` type | Depend on the `Domain` protocol; let the assembler supply the implementation |
| A DTO or `URLResponse` in a public signature | Return a `Domain` entity; map in `Data` |
| Facade grown to orchestrate three collaborators | Extract a named type into `Domain/` per the threshold |
| `public` added so a test can see a type | `@testable import ContentSyncKit` |
| Convenience singleton with its own construction path | Build the shared instance on the same injectable initializer tests use |

### Testing this layer

See `TESTING.md`. Minimum: every public method exercised against stub repositories, covering
success, the mapped-failure path, and cancellation if the method awaits more than once. A
public API change that the Example app does not compile against is not done.

---

## Domain

### Responsibility

Owns the vocabulary of the package: entities, and the repository protocols that describe how
those entities are obtained. It is the centre of the dependency graph and depends on nothing
— no networking, no persistence, no layer above or beside it. It must never know that HTTP,
files, or caches exist.

### Rules

- Entities are `Sendable` value types. No classes, no reference semantics.
- No `Codable` on entities. Transport shapes live in `Data/DTO/`.
- Repository protocols are `internal`, `Sendable`, and `async throws`.
- Foundation value types (`Date`, `URL`, `Data`) are allowed; `URLSession`, `FileManager`, and any persistence API are not.
- Naming: entities are bare nouns (`ContentItem`, `Manifest`). Protocols are `<Noun>Repository`. Errors are one namespaced enum, `SyncError`.

### Canonical shape

```swift
public struct ContentItem: Sendable, Equatable, Identifiable {
    public let id: String
    public let bundleID: String
    public let updatedAt: Date
}

public enum SyncError: Error, Sendable, Equatable {
    case malformedContent(id: String)
    case manifestUnavailable
    case transportFailed
}

protocol ContentRepository: Sendable {
    func bundle(for manifest: Manifest) async throws -> ContentBundle
}
```

### Talking to the next layer

There is no next layer. `Domain` is the innermost circle; `Data` implements its protocols and
`SDK` consumes them. If a `Domain` type needs something from another layer, the design is
inverted — express the need as a protocol here and let the outer layer satisfy it.

### Common mistakes in this layer

| Mistake | Correct |
|---|---|
| Entity conforms to `Codable` | Add a DTO in `Data/DTO/` and map at the boundary |
| Snake-case field names mirroring the API payload | Name for the domain; the mapper absorbs the wire shape |
| `import Foundation` for `URLRequest` | That type belongs in `CoreNetwork` |
| A repository protocol marked `public` | Keep it `internal`; consumers get the facade, not the seams |
| `class` entity mutated in place | `struct`, returned anew |

### Testing this layer

See `TESTING.md`. Entities and pure policy types are tested directly with no doubles. A
protocol alone needs no test — its contract is verified in the layer that implements it.

---

## Data

### Responsibility

Owns every implementation of a `Domain` repository protocol, plus the DTOs, mappers, data
sources, cache, and storage they need. It fetches and maps; it does not decide. Business
policy in this layer is an architecture bug, not a style preference.

### Rules

- One `Default<Noun>Repository` per `Domain` protocol, composed of data sources — never calling `URLSession` directly.
- `Codable` lives on DTOs and stops here. A DTO in a `Domain` or `SDK` signature does not merge.
- Mapping is a pure function in `Data/Mapping/`; mapping failure surfaces as `SyncError.malformedContent`, never a decoding error escaping upward.
- Mutable cache state is an `actor` (`ContentCache`). Never a class with a lock.
- Naming: `<Noun>DTO`, `<Noun>Mapper`. Data-source protocols are `Remote<Noun>DataSource` /
  `Local<Noun>DataSource`; implementations prefix `Default`, matching `Default<Noun>Repository`.

### Canonical shape

```swift
struct ContentItemDTO: Codable, Sendable {
    let id: String
    let bundleId: String
    let updatedAt: String
}

enum ContentItemMapper {
    static func entity(from dto: ContentItemDTO) throws -> ContentItem {
        guard let updatedAt = ISO8601DateFormatter().date(from: dto.updatedAt) else {
            throw SyncError.malformedContent(id: dto.id)
        }
        return ContentItem(id: dto.id, bundleID: dto.bundleId, updatedAt: updatedAt)
    }
}

struct DefaultContentRepository: ContentRepository {
    private let remote: any RemoteContentDataSource
    private let cache: ContentCache

    func bundle(for manifest: Manifest) async throws -> ContentBundle {
        if let cached = await cache.bundle(for: manifest.revision) { return cached }
        let dtos = try await remote.items(for: manifest.revision)
        let bundle = ContentBundle(items: try dtos.map(ContentItemMapper.entity(from:)))
        await cache.store(bundle, for: manifest.revision)
        return bundle
    }
}
```

### Talking to the next layer

- Call `CoreNetwork` through `NetworkClient` only; never build a `URLSession` task here.
- Inject the client and the cache via initializer; store them privately.
- Decode at this boundary. `URLResponse`, status codes, and headers must not travel upward.

### Common mistakes in this layer

| Mistake | Correct |
|---|---|
| Business rule inside `DefaultContentRepository` | Repositories fetch and map; policy belongs in the facade or an extracted `Domain` type |
| `DecodingError` propagating to the caller | Catch at the mapper; throw `SyncError.malformedContent` |
| Repository returning a DTO | Map to the entity before returning |
| `class ContentCache` guarded by `NSLock` | `actor ContentCache` |
| Data source constructing its own `NetworkClient` | Inject it from the assembler |

### Testing this layer

See `TESTING.md`. Minimum for a data change: the request built is correct, a valid response
maps to the expected entity, and a malformed response maps to the expected `SyncError`. Stub
the data-source protocol; no live network and no real file system.

---

## CoreNetwork

### Responsibility

Owns HTTP transport: request execution, the middleware chain, retry, auth headers, and
logging plumbing. It is content-agnostic — it moves bytes and must never know what a
`ContentItem` is.

### Rules

- Zero third-party dependencies. The middleware chain is why Alamofire is not needed.
- No `Domain` import. This layer must compile with `Domain` deleted.
- Middleware is a chain of `Sendable` values, each free to inspect, modify, short-circuit, or retry.
- Transport failures surface as a `NetworkError`; `Data` maps that to `SyncError`.
- Naming: `NetworkClient`, `<Purpose>Middleware` (`AuthMiddleware`, `RetryMiddleware`), transport models under `CoreNetwork/Model/`.

### Canonical shape

```swift
protocol NetworkMiddleware: Sendable {
    func intercept(
        _ request: URLRequest,
        next: @Sendable (URLRequest) async throws -> NetworkResponse
    ) async throws -> NetworkResponse
}

struct NetworkClient: Sendable {
    private let transport: any NetworkTransport
    private let middleware: [any NetworkMiddleware]

    func send(_ request: URLRequest) async throws -> NetworkResponse {
        try await proceed(request, at: middleware.startIndex)
    }

    private func proceed(_ request: URLRequest, at index: Int) async throws -> NetworkResponse {
        guard index < middleware.endIndex else {
            return try await transport.send(request)
        }
        return try await middleware[index].intercept(request) { forwarded in
            try await proceed(forwarded, at: index + 1)
        }
    }
}
```

### Talking to the next layer

There is no layer beneath this one — `URLSession` sits behind a `NetworkTransport` protocol
so tests can replace it. Nothing here calls upward.

### Common mistakes in this layer

| Mistake | Correct |
|---|---|
| Middleware that knows a specific endpoint's meaning | Keep it content-agnostic; endpoint knowledge lives in `Data` |
| `import` of a `Domain` type | Use transport models; `Data` bridges the two |
| Retry logic scattered through data sources | One `RetryMiddleware` in the chain |
| Auth token read from a global | Inject a token provider into `AuthMiddleware` |
| Logging a full request including headers | Never log credentials; see the secret rules in `SKILL.md` |

### Testing this layer

See `TESTING.md`. Minimum: each middleware tested in isolation with a stub `next`, asserting
what it forwards, what it rewrites, and when it short-circuits. Chain order is tested once,
with a recording transport.

---

## Dependencies

### Responsibility

The composition root. It is the one place allowed to know every layer, because construction
is not a dependency in the architectural sense — nothing calls back into it. It wires the
graph and does nothing else.

### Rules

- Assemblers only. No DI container, no service locator, no singletons.
- Contains wiring, never logic. A conditional here means a policy leaked out of `Domain` or `SDK`.
- Every assembler method returns an existential of the `Domain` protocol, not the concrete type.
- Assemblers are `Sendable` values, constructed from `ContentSyncClient.Configuration`.
- Naming: `<Area>Assembler` (`ContentAssembler`, `NetworkAssembler`), with `ModuleAssembler` composing them.

### Canonical shape

```swift
struct ContentAssembler: Sendable {
    private let network: NetworkClient
    private let configuration: ContentSyncClient.Configuration

    func contentRepository() -> any ContentRepository {
        DefaultContentRepository(
            remote: DefaultRemoteContentDataSource(client: network, baseURL: configuration.baseURL),
            cache: ContentCache(limit: configuration.cacheLimit)
        )
    }
}
```

### Talking to the next layer

- Constructs `Data` and `CoreNetwork` types and hands them to `SDK`.
- The arrow is dashed in the `ARCHITECTURE.md` diagram for a reason: this is composition, not coupling.

### Common mistakes in this layer

| Mistake | Correct |
|---|---|
| Assembler returns `DefaultContentRepository` | Return `any ContentRepository` |
| `if configuration.isDebug` branching the graph | Express the variation as a collaborator chosen by the caller |
| A `static let shared` living here | Assemble per-instance; the facade may expose a shared instance built the same way |
| Caching assembled objects to "save allocations" | Assemble on demand; lifetime is the facade's concern |

### Testing this layer

See `TESTING.md`. Assemblers are usually verified indirectly — if `swift build` and the
Example app link, the graph is valid. Write a direct test only when an assembler chooses
between collaborators, and then assert the choice, not the identity of the object.

---

## Shared

### Responsibility

Genuinely cross-layer utilities. It exists to prevent duplication between two layers that
must not depend on each other, and for nothing else. It must never become the place code
goes when its home is unclear.

### Rules

- A type earns a place here only when two layers that cannot depend on each other both need it.
- One layer using it means it belongs in that layer. Move it.
- No layer-specific vocabulary. Nothing here may import `Domain`, `Data`, `SDK`, or `CoreNetwork`.
- `Shared/` starts empty, and an empty `Shared/` is the correct state until the rule above is met.
- Naming: describe the capability, never the location. No `Utils`, `Helpers`, `Common`, or `Misc`.

### Canonical shape

```swift
// Earns its place: CoreNetwork needs it for retry backoff, Data needs it for
// cache expiry, and neither layer may import the other.
struct Backoff: Sendable {
    let base: Duration
    let maximum: Duration

    func delay(forAttempt attempt: Int) -> Duration { /* ... */ }
}
```

### Talking to the next layer

Nothing. `Shared` is a leaf — it is imported, and imports nothing from the package.

### Common mistakes in this layer

| Mistake | Correct |
|---|---|
| Utility parked here, used by one layer | Move it into that layer |
| `Extensions/` growing a general-purpose `String+Everything.swift` | Keep extensions narrow and near their use |
| A type here importing `Domain` | It is not shared; it is a `Domain` type |
| `Helpers.swift` holding unrelated free functions | One type per capability, named for the capability |

### Testing this layer

See `TESTING.md`. Anything here is pure and testable directly, with no doubles. Because two
layers depend on it, a change is only done when both callers' suites still pass.
