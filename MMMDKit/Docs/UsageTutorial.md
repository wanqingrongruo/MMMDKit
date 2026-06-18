# MMMDKit SwiftUI 使用教程

MMMDKit v2 只暴露 SwiftUI 渲染入口。UIKit/AppKit 旧入口请参考 `Migration-v1-to-v2.md`。

## 安装

SPM 推荐使用 umbrella product：

```swift
.product(name: "MMMDKit", package: "MMMDKit")
```

CocoaPods：

```ruby
pod "MMMDKit"
```

注意：SPM 默认使用 `MMMDParserSwiftMarkdown`，CocoaPods 默认使用 `MMMDParserCmark` fallback parser。

## 静态 Markdown

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

## 预解析文档

```swift
let parser = SwiftMarkdownParser()
let document = try parser.parse(markdown)

MarkdownDocumentView(document: document)
```

## 流式输出

Delta 模式适合 LLM token/chunk：

```swift
StreamingMarkdownText(source: deltaStream, inputMode: .delta)
```

Snapshot 模式适合每次输出完整文本：

```swift
StreamingMarkdownText(source: snapshotStream, inputMode: .snapshot)
```

如果业务已经持有 session：

```swift
let session = StreamingMarkdownSession(parser: SwiftMarkdownParser())
StreamingMarkdownText(session: session)
```

## 自定义样式

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

## 自定义交互

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

## 自定义能力

```swift
let configuration = MarkdownConfiguration(
    codeHighlighter: CachingCodeHighlighter(base: KeywordCodeHighlighter()),
    mathRenderer: FallbackMathRenderer(),
    imageLoader: CachingImageLoader(base: MyImageLoader()),
    localization: .simplifiedChinese
)
```

实现图片加载器：

```swift
struct MyImageLoader: ImageLoader {
    func loadImageData(from url: URL) async throws -> Data {
        try Data(contentsOf: url)
    }
}
```

`CachingImageLoader` 会按 URL 复用已加载的图片数据；如果图片加载失败，默认 SwiftUI UI 会展示失败原因和重试按钮。缓存淘汰策略可以按条数、字节数和 FIFO/LRU 配置：

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

## 布局与大内容

默认 SwiftUI renderer 会对大表格启用内部 lazy 滚动和 sticky header，并使用平台字体测量内容宽度。GFM 表格中的 `:---`、`:---:`、`---:` 会映射到 leading、center、trailing 列对齐；图片会限制默认展示高度。业务可以按场景调整：

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

如果业务要完全自定义图片预览，可以关闭内置 sheet，并通过 `onImageTap` 接管：

```swift
let configuration = MarkdownConfiguration(
    actions: MarkdownActions(onImageTap: { image in
        openCustomPreview(image)
    }),
    layoutOptions: .init(showsDefaultImagePreview: false)
)
```

## Snapshot Fixtures

SwiftUI snapshot 测试默认会校验 PNG fixture 是否存在，并用 golden metrics 检查渲染范围。需要重新录制图片时运行：

```bash
MMMD_RECORD_SNAPSHOTS=1 swift test --filter SwiftUISnapshotTests
```

录制结果位于 `Tests/MMMDSwiftUITests/__Snapshots__/`，可以直接打开 PNG 审查。

## 流式指标

`MarkdownRenderDiff.metrics` 包含：

- `chunkCount`
- `renderCount`
- `sourceLength`
- `parseDuration`
- `renderLatency`
- `elapsed`

Demo 可以用这些指标展示 streaming 性能面板。
