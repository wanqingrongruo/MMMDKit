# MMMDKit SwiftUI Usage Tutorial

MMMDKit v2 exposes SwiftUI renderers only. See `Migration-v1-to-v2.en.md` for UIKit/AppKit migration notes.

## Installation

Recommended SPM product:

```swift
.product(name: "MMMDKit", package: "MMMDKit")
```

CocoaPods:

```ruby
pod "MMMDKit"
```

SPM uses `MMMDParserSwiftMarkdown` by default. CocoaPods uses the `MMMDParserCmark` fallback parser by default.

## Static Markdown

```swift
import SwiftUI
import MMMDKit

struct ArticleView: View {
    let markdown: String

    var body: some View {
        ScrollView {
            MarkdownText(markdown)
                .padding()
        }
    }
}
```

## Pre-parsed Documents

```swift
let parser = SwiftMarkdownParser()
let document = try parser.parse(markdown)

MarkdownDocumentView(document: document)
```

## Streaming

Delta mode is suitable for LLM token/chunk streams:

```swift
StreamingMarkdownText(source: deltaStream, inputMode: .delta)
```

Snapshot mode is suitable when each emission is the full text so far:

```swift
StreamingMarkdownText(source: snapshotStream, inputMode: .snapshot)
```

For full session control:

```swift
let session = StreamingMarkdownSession(parser: SwiftMarkdownParser())
StreamingMarkdownText(session: session)
```

## Custom Theme

```swift
var configuration = MarkdownConfiguration()
configuration.theme = MarkdownTheme(
    colors: MarkdownColors(
        text: "#24292F",
        secondaryText: "#57606A",
        link: "#0969DA",
        codeBackground: "#F6F8FA",
        tableBorder: "#D0D7DE"
    )
)

MarkdownText(markdown, configuration: configuration)
```

## Custom Actions

```swift
let configuration = MarkdownConfiguration(
    actions: MarkdownActions(
        onLinkTap: { url in
            print("link", url)
        },
        onImageTap: { image in
            print("image", image.url?.absoluteString ?? image.alt)
        },
        onCopyImageURL: { image in
            print("image url copied", image.url?.absoluteString ?? "")
        },
        onCopyTable: { text in
            print("table copied", text)
        }
    )
)
```

## Custom Capabilities

```swift
let configuration = MarkdownConfiguration(
    codeHighlighter: CachingCodeHighlighter(base: KeywordCodeHighlighter()),
    mathRenderer: FallbackMathRenderer(),
    imageLoader: CachingImageLoader(base: MyImageLoader()),
    localization: .english
)
```

Image loader example:

```swift
struct MyImageLoader: ImageLoader {
    func loadImageData(from url: URL) async throws -> Data {
        try Data(contentsOf: url)
    }
}
```

`CachingImageLoader` reuses loaded image data by URL. If loading fails, the default SwiftUI UI shows the failure reason and a retry button. Cache eviction can be configured by entry count, byte count, and FIFO/LRU strategy:

```swift
let loader = CachingImageLoader(
    base: MyImageLoader(),
    cacheConfiguration: ImageDataCacheConfiguration(
        maximumEntryCount: 200,
        maximumByteCount: 20 * 1024 * 1024,
        evictionStrategy: .leastRecentlyUsed
    )
)
```

## Layout And Large Content

The default SwiftUI renderer uses internal lazy scrolling, sticky headers, and platform font measurement for large tables. GFM table markers `:---`, `:---:`, and `---:` map to leading, center, and trailing alignment. Images are constrained to a default display height. Apps can tune those defaults:

```swift
let configuration = MarkdownConfiguration(
    layoutOptions: MarkdownLayoutOptions(
        tableMaximumVisibleRows: 30,
        tableMaximumHeight: 360,
        tableCellMinWidth: 120,
        tableCellMaxWidth: 260,
        imageMaximumHeight: 280,
        showsDefaultImagePreview: true
    )
)
```

If your app owns image preview UI, disable the built-in sheet and handle `onImageTap` yourself:

```swift
let configuration = MarkdownConfiguration(
    actions: MarkdownActions(onImageTap: { image in
        openCustomPreview(image)
    }),
    layoutOptions: .init(showsDefaultImagePreview: false)
)
```

## Snapshot Fixtures

SwiftUI snapshot tests verify PNG fixtures and golden metrics by default. Re-record PNG fixtures with:

```bash
MMMD_RECORD_SNAPSHOTS=1 swift test --filter SwiftUISnapshotTests
```

Generated fixtures live in `Tests/MMMDSwiftUITests/__Snapshots__/` and can be opened for visual review.

## Streaming Metrics

`MarkdownRenderDiff.metrics` includes:

- `chunkCount`
- `renderCount`
- `sourceLength`
- `parseDuration`
- `renderLatency`
- `elapsed`

Demos can use these values to render a streaming performance panel.
