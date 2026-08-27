# ContentSyncKit Testing Guideline

Use this guideline when adding or changing tests. Keep scope focused on the behavior under
change. No live network, no credentials, no environment-specific data.

ContentSyncKit is a distributable SDK, not an app. There is no presentation layer to test —
the outermost thing under test is `ContentSyncClient`, and the Example app exists to prove
integration, not to carry the test suite.

## Frameworks

| Type | Framework | Use case |
|------|-----------|----------|
| Unit tests | XCTest | Facade, repository implementations, mappers, middleware, cache, assemblers |
| Integration tests | XCTest | `NetworkClient` against `URLProtocol` stubs, storage adapters, end-to-end sync through fakes |
| Example app tests | XCTest | Proof the public API composes from a real consumer's position |

XCTest throughout — see [ADR-0007](../adr/0007-xctest-over-swift-testing.md). The deployment
floor is iOS 15 and XCTest is supported across it.

Snapshot testing is deliberately absent: the package ships no UI. If the Example app grows
views worth pinning, add `swift-snapshot-testing` to *its* test target only — never to the
package target, which stays dependency-free.

## Test-Driven Development

Follow Red-Green-Refactor whenever the behavior is clear:

```text
1. Red: write a failing test
2. Green: write the smallest implementation that passes
3. Refactor: clean up while tests stay green
```

Rules:

- The Red step must actually fail, and fail for the reason you expect. A test that passes
  before the implementation exists is testing nothing. Run it and read the failure.
- Write one failing test at a time. A batch of red tests hides which change made which pass.
- The Green step is allowed to be embarrassing. Hardcode, then refactor under green.
- For bug fixes, the regression test *is* the Red step: reproduce the reported scenario, watch
  it fail, then fix.
- For investigations and risky refactors, add characterization tests that pin current behavior
  *before* changing anything. They are the safety net, not the specification.

Where behavior is genuinely unclear — an unspecified conflict-resolution rule, an ambiguous
error case — stop and ask rather than encoding a guess as a passing test.

## Where tests live

Mirror the source layer, one test file per unit under test:

```text
Tests/ContentSyncKitTests/
  SDK/            ContentSyncClientTests.swift
  Domain/         SyncPolicyTests.swift
  Data/
    Mapping/      ContentItemMapperTests.swift
    Repositories/ DefaultContentRepositoryTests.swift
    Cache/        ContentCacheTests.swift
  CoreNetwork/    NetworkClientTests.swift, MiddlewareTests.swift
  Dependencies/   ModuleAssemblerTests.swift
  Helpers/        XCTestCase+MemoryLeakTracking.swift, URLProtocolStub.swift, Fixtures/
```

Tests use `@testable import ContentSyncKit`. This is the reason repository protocols stay
`internal` rather than being made `public` for testability — see `ARCHITECTURE.md`.

## The makeSUT pattern

Build the System Under Test and its doubles in one helper. Every test then reads as arrange,
act, assert without construction noise.

```swift
final class DefaultContentRepositoryTests: XCTestCase {
    func test_fetchContent_whenRemoteSucceeds_returnsMappedItems() async throws {
        // Arrange
        let (sut, remote, _) = makeSUT()
        remote.fetchResult = .success([.fixture(id: "a"), .fixture(id: "b")])

        // Act
        let items = try await sut.fetchContent(for: .fixture())

        // Assert
        XCTAssertEqual(
            items.map(\.id),
            ["a", "b"],
            "Expected fetchContent to return one domain item per DTO returned by the remote data source."
        )
    }

    // MARK: - Helpers

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: DefaultContentRepository, remote: RemoteContentDataSourceSpy, cache: ContentCacheSpy) {
        let remote = RemoteContentDataSourceSpy()
        let cache = ContentCacheSpy()
        let sut = DefaultContentRepository(remote: remote, cache: cache)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(remote, file: file, line: line)
        trackForMemoryLeaks(cache, file: file, line: line)
        return (sut, remote, cache)
    }
}
```

`makeSUT` returns the SUT plus only the doubles the tests actually assert against. Adding a
collaborator to a type changes one helper, not thirty tests.

## Memory leaks

Track every class- or actor-based SUT and collaborator. Both are reference types and both can
be retained by an escaping closure or a `Task` that outlives the test.

```swift
extension XCTestCase {
    func trackForMemoryLeaks(
        _ instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Instance should have been deallocated. Potential retain cycle.",
                file: file,
                line: line
            )
        }
    }
}
```

Lives in `Tests/ContentSyncKitTests/Helpers/XCTestCase+MemoryLeakTracking.swift`. **This helper
does not exist yet — create it with the first real test.**

Do not track value types: `Domain` entities, DTOs, `Configuration`, `SyncError`, and assemblers
are all structs or enums and cannot leak.

## Test doubles

Spies conform to the `Domain` repository protocol, never to a concrete type. This is the payoff
for defining those protocols in `Domain` at all.

```swift
final class ContentRepositorySpy: ContentRepository, @unchecked Sendable {
    private(set) var fetchContentCallCount = 0
    private(set) var receivedManifests: [Manifest] = []
    var fetchContentResult: Result<[ContentItem], Error> = .success([])

    func fetchContent(for manifest: Manifest) async throws -> [ContentItem] {
        fetchContentCallCount += 1
        receivedManifests.append(manifest)
        return try fetchContentResult.get()
    }
}
```

- **Spy** when the test asserts calls or captured input. Default choice.
- **Stub** when the test only needs canned data and does not care how it was reached.
- Do not mock what you do not own. `URLSession` is stubbed at the `URLProtocol` seam, not wrapped
  in a protocol invented for the test.
- `@unchecked Sendable` on a spy is acceptable — tests are single-threaded against it — but it
  needs the same written justification as production code if the spy is driven concurrently.

### Fixtures

Every entity and DTO gets a `.fixture()` with defaulted parameters, in `Helpers/Fixtures/`:

```swift
extension ContentItem {
    static func fixture(
        id: String = "item-id",
        checksum: String = "checksum",
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> ContentItem {
        ContentItem(id: id, checksum: checksum, updatedAt: updatedAt)
    }
}
```

Fixed defaults, never `Date()`, never `UUID()`. A test that cares about one field overrides that
one field, and the reader knows the rest is irrelevant.

## Naming

```text
test_[methodUnderTest]_[scenario]_[expectedBehavior]
```

```swift
func test_sync_whenManifestUnchanged_doesNotFetchContent()
func test_sync_whenRemoteFails_throwsSyncErrorTransport()
func test_fetchContent_whenCacheHit_doesNotCallRemote()
func test_map_whenChecksumMissing_throwsSyncErrorMalformedPayload()
```

Avoid `test_success`, `test_error`, `test_sync`.

## Assertions

Every assertion carries a descriptive failure message stating the expected behavior and where to
look. Do not rely on XCTest's generated diff as the only explanation.

```swift
XCTAssertEqual(
    remote.fetchCallCount,
    0,
    "Expected no remote fetch when the manifest checksum is unchanged; check the short-circuit in sync(_:)."
)
```

This applies to every assertion form — `XCTAssertEqual`, `XCTAssertTrue`, `XCTAssertFalse`,
`XCTAssertNil`, `XCTAssertNotNil`, `XCTUnwrap`, and `XCTAssertThrowsError`.

### Asserting errors

The public API fails with `SyncError` and nothing else. Assert the case, not the description:

```swift
func test_sync_whenRemoteFails_throwsSyncErrorTransport() async {
    let (sut, remote) = makeSUT()
    remote.fetchResult = .failure(URLError(.notConnectedToInternet))

    do {
        _ = try await sut.sync()
        XCTFail("Expected sync to throw when the remote data source fails.")
    } catch let error as SyncError {
        guard case .transport = error else {
            return XCTFail("Expected SyncError.transport, got \(error). Check the mapping in DefaultContentRepository.")
        }
    } catch {
        XCTFail("Expected SyncError, got \(type(of: error)). A transport error leaked past the Data boundary.")
    }
}
```

A test that catches a raw `URLError` or `DecodingError` from a public method is reporting an
architecture violation, not a test failure. Fix the mapping.

## Async and actor isolation

Mark the test `async` and `await` the method under test. Assert final state.

```swift
func test_sync_whenRemoteReturnsNewManifest_updatesLocalStore() async throws {
    let (sut, remote, store) = makeSUT()
    remote.manifestResult = .success(.fixture(checksum: "new"))

    try await sut.sync()

    let stored = await store.currentManifest
    XCTAssertEqual(
        stored?.checksum,
        "new",
        "Expected sync to persist the newly fetched manifest to the local store."
    )
}
```

Rules:

- Reading actor-isolated state in an assertion requires `await`. Hoist it into a `let` before the
  assertion so the failure message stays readable.
- **Never `Task.sleep` to wait for work.** If a test needs to observe an intermediate state,
  restructure the production code to expose a seam — an injected clock, an awaited handle — rather
  than racing it.
- Debounce, retry backoff, and scheduling take an injected clock or delay provider. A test that
  waits real seconds is a test that will flake in CI.
- Use `XCTestExpectation` only for genuine callback boundaries such as `URLProtocol`. Structured
  concurrency does not need it.

## Stubbing the network

`CoreNetwork` is tested against `URLProtocol`, never a live host:

```swift
final class URLProtocolStub: URLProtocol {
    nonisolated(unsafe) static var stub: (Data?, HTTPURLResponse?, Error?)?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        guard let stub = Self.stub else { return }
        if let error = stub.2 {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            if let response = stub.1 {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = stub.0 { client?.urlProtocol(self, didLoad: data) }
        }
        client?.urlProtocolDidFinishLoading(self)
    }
}
```

Register it on an ephemeral `URLSessionConfiguration` in `makeSUT` and clear the stub in
`tearDown`. Assert both directions: the request the client built, and the mapping of the response
it received.

## What to assert, by layer

| Layer | Assert |
|---|---|
| `SDK/` | Delegation to the right repository, `SyncError` mapping, that no orchestration logic has crept in |
| `Domain/` | Policy decisions and entity invariants. Pure functions, no doubles needed |
| `Data/` mapping | DTO to entity for valid input; the thrown `SyncError` for each malformed shape |
| `Data/` repositories | Request built correctly, response mapped, error mapped, cache hit avoids the remote call |
| `Data/` cache & storage | Eviction, capacity limits, round-trip persistence, behavior on a corrupt store |
| `CoreNetwork/` | Middleware ordering, retry and auth behavior, request construction, status-code mapping |
| `Dependencies/` | The assembler returns a graph that satisfies the protocol; wiring, not behavior |

## Determinism

Non-negotiable. A test must produce the same result on every machine, every run.

- No live network, no real host, no credentials.
- No `Date()` — inject a clock or use a fixed `Date(timeIntervalSince1970:)`.
- No `UUID()` in fixtures — use fixed strings.
- No `UserDefaults.standard`, no shared singletons. Use a unique suite per test or an injected store.
- No dependence on filesystem state outside a temp directory created and torn down per test.
- No ordering dependence between tests. Each test constructs its own SUT.

## Anti-patterns

- Asserting on private implementation details rather than observable behavior.
- Shared mutable fixtures reused across test cases.
- Tests that pass whether or not the fix is present — always watch the Red step fail.
- Weakening an assertion to make a suite green. Fix the code, or report the test as failing.
- Spies that assert nothing, existing only to satisfy an initializer. Use a stub.
- A test per public method regardless of risk. Cover branches and boundaries, not line count.

## Protected paths

Never read, search inside, print, or assert real values from:

- {{SECRET_PATHS}}

If a test needs configuration values, use safe fixtures or a redacted excerpt supplied by the user.

## Running tests

```sh
make verify                                         # build + test + lint + secret scan
make test                                           # package suite only
swift test --filter DefaultContentRepositoryTests   # one class, while debugging
make verify-example                                 # Example app
```

`make` is the portable contract — it works the same for any agent tool, any CI run, and any human.

Both must pass before any completion claim — see [ADR-0004](../adr/0004-verify-package-and-example-app.md).
Paste the result line; never claim green without it.

## Quality gates

- Every new or changed public facade method has tests for success, mapped failure, and the
  no-op path where one exists.
- Every repository implementation has tests with spied data sources.
- Every mapper with branching has table-style tests covering each malformed shape.
- Every middleware has tests for ordering and for its own failure mode.
- Bug fixes ship with a regression test that fails without the fix.
- Non-trivial setup goes through `makeSUT()`.
- Class- and actor-based SUTs are tracked for memory leaks.
- No test performs a real network call or requires real credentials.
- Tests are deterministic across machines, locales, time zones, and run order.
