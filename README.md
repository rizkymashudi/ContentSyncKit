# ContentSyncKit

A Swift package for content synchronization, built for reuse across apps with the same sync use case.

## Requirements

- Swift 6.2+
- iOS 26.2+

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/rizkymashudi/ContentSyncKit.git", from: "0.1.0")
]
```

Or in Xcode: **File > Add Package Dependencies…** and enter the repository URL.

## Usage

```swift
import ContentSyncKit
```

## Example app

`Example/ContentKitExample.xcodeproj` is a SwiftUI demo that exercises the package. It references the package locally (`relativePath = ".."`), so it always builds against the working-tree source — no version resolution step while developing.

```bash
open Example/ContentKitExample.xcodeproj
```

## Repository layout

```
.
├── Package.swift
├── Sources/ContentSyncKit/       # the package
├── Tests/ContentSyncKitTests/
└── Example/                      # SwiftUI demo app consuming the package
```

## Development

```bash
swift build
swift test
```
