# Migration v1 to v2

MMMDKit v2 is a SwiftUI-only breaking rewrite. The v1 UIKit/AppKit renderers are no longer maintained as public APIs.

## Module Replacements

| v1 | v2 |
| --- | --- |
| `MMMDUIKit` | `MMMDSwiftUI` |
| `MMMDAppKit` | `MMMDSwiftUI` |
| `MarkdownView` | `MarkdownText` or `MarkdownDocumentView` |
| `MarkdownNSView` | `MarkdownText` or `MarkdownDocumentView` |
| `MarkdownCollectionViewHost` | SwiftUI `ScrollView` / `List` / `LazyVStack` with `MarkdownText` |
| `MarkdownLayoutEngine` | SwiftUI adaptive layout; use demo metrics for list performance |

## Static Rendering

v1:

```swift
let parser = CmarkMarkdownParser()
let document = try parser.parse(markdown)
markdownView.render(document)
```

v2:

```swift
MarkdownText(markdown, configuration: configuration)
```

If your app already has a parsed document:

```swift
let document = try SwiftMarkdownParser().parse(markdown)
MarkdownDocumentView(document: document, configuration: configuration)
```

## Streaming

v2 supports both delta and snapshot inputs:

```swift
StreamingMarkdownText(source: stream, inputMode: .delta)
StreamingMarkdownText(source: stream, inputMode: .snapshot)
```

For full session control:

```swift
let session = StreamingMarkdownSession(parser: SwiftMarkdownParser())
StreamingMarkdownText(session: session)
```

## Parser Behavior

- SPM uses `MMMDParserSwiftMarkdown` by default.
- CocoaPods uses the `MMMDParserCmark` fallback parser by default.
- Prefer SPM when you need the default `swift-markdown` GFM behavior.

## Customization

These capabilities remain configurable through `MarkdownConfiguration`:

- `codeHighlighter`
- `mathRenderer`
- `imageLoader`
- `actions`
- `plugins`
- `localization`
- `theme`

## Notes

- v2 does not guarantee source compatibility with v1 UIKit/AppKit call sites.
- The old UIKit/AppKit sources and demos have been removed from the v2 mainline. Migrate to `MMMDSwiftUI`.
- The default theme now follows the SwiftStreamingMarkdown-inspired style. The previous visual baseline is no longer kept as a built-in API.
