# cmark-gfm 构建接入方案

## 目标

`MMMDParserCmark` 最终要使用 GitHub Flavored Markdown 的官方 C 实现 `cmark-gfm` 作为解析核心，并把解析结果转换为 `MMMDCore.MarkdownDocument`。

接入目标：

- 支持 iOS 15+、iPadOS 15+、macOS 12+。
- 支持 Swift Package Manager。
- 支持 CocoaPods 分模块引入。
- 不把 cmark-gfm 的 C 类型暴露到公开 Swift API。
- 允许未来替换 parser，不影响上层 renderer 和 streaming 模块。

## 推荐目录结构

```text
Sources/
  CMMDCmarkGFM/
    include/
      CMMDCmarkGFM.h
    shim/
      MMDCmarkGFMShim.h
      MMDCmarkGFMShim.c
    cmark-gfm/
      src/
      extensions/
  MMMDParserCmark/
    CmarkMarkdownParser.swift
    CmarkNodeBridge.swift
    CmarkInlineBridge.swift
    CmarkBlockBridge.swift
```

`CMMDCmarkGFM` 是 C target，只负责封装 cmark-gfm。`MMMDParserCmark` 是 Swift target，只依赖 `MMMDCore` 和 `CMMDCmarkGFM`。

## SwiftPM 接入方式

后续在 `Package.swift` 中增加一个 C target：

```swift
.target(
    name: "CMMDCmarkGFM",
    path: "Sources/CMMDCmarkGFM",
    publicHeadersPath: "include",
    cSettings: [
        .headerSearchPath("cmark-gfm/src"),
        .headerSearchPath("cmark-gfm/extensions"),
        .define("CMARK_GFM_STATIC_DEFINE")
    ]
),
.target(
    name: "MMMDParserCmark",
    dependencies: [
        "MMMDCore",
        "CMMDCmarkGFM"
    ]
)
```

如果直接引入完整 cmark-gfm 源码导致 SwiftPM 编译配置过重，可以先用 `shim` 层暴露最小 API，再逐步补齐 extension 支持。

## CocoaPods 接入方式

`MMMDKit/ParserCmark` subspec 后续需要包含 C 源码和 public header：

```ruby
ss.source_files = [
  "Sources/MMMDParserCmark/**/*.swift",
  "Sources/CMMDCmarkGFM/**/*.{h,c}"
]
ss.public_header_files = "Sources/CMMDCmarkGFM/include/**/*.h"
ss.pod_target_xcconfig = {
  "HEADER_SEARCH_PATHS" => "$(PODS_TARGET_SRCROOT)/Sources/CMMDCmarkGFM/cmark-gfm/src $(PODS_TARGET_SRCROOT)/Sources/CMMDCmarkGFM/cmark-gfm/extensions"
}
```

如果后续使用 vendored static library，需要单独验证模拟器、真机、macOS 三个平台的 slice。

## 解析桥接流程

```text
Markdown String
  -> cmark_parser_new
  -> cmark_parser_attach_syntax_extension(table / strikethrough / tasklist / autolink)
  -> cmark_parser_feed
  -> cmark_parser_finish
  -> cmark_node tree
  -> CmarkNodeBridge
  -> MarkdownDocument
```

Swift 层只处理 `MarkdownDocument`，不持有裸 `cmark_node`。C 侧生命周期必须集中管理，避免节点树泄漏。

## GFM Extension 优先级

第一批接入：

- table
- strikethrough
- tasklist
- autolink
- fenced code block info string

第二批接入：

- source range
- footnote
- raw HTML block 分类
- custom extension hook

## Source Range 策略

`MMMDCore` 后续需要添加 `SourceRange`：

```swift
public struct SourceRange: Equatable, Sendable {
    public var startLine: Int
    public var startColumn: Int
    public var endLine: Int
    public var endColumn: Int
}
```

每个 block 和 inline node 可以可选携带 source range。Streaming 模块可以利用 source range 判断稳定块和不稳定尾块。

## 风险与处理

- cmark-gfm 构建参数较多：先用最小 shim 编译通过，再扩展 extension。
- CocoaPods 与 SwiftPM 的 header search path 不一致：CI 需要分别验证。
- C 生命周期容易泄漏：所有 `cmark_node_free` 和 parser free 必须集中在 bridge 层。
- HTML 支持边界复杂：parser 只识别 HTML block/inline，渲染策略交给 `MMMDHTML`。
- GFM table 到原生 table model 的转换需要保留对齐方式，后续为 `TableBlock` 添加 alignment 字段。

## 实施顺序

1. 新建 `CMMDCmarkGFM` C target。
2. 添加最小 shim，先支持普通 Markdown AST 遍历。
3. 修改 `MMMDParserCmark` 依赖 `CMMDCmarkGFM`。
4. 实现 heading、paragraph、code、list、blockquote 的 bridge。
5. 接入 GFM extensions。
6. 为 table、tasklist、strikethrough 添加测试。
7. 在 CocoaPods subspec 中纳入 C 源码。
8. CI 同时验证 SwiftPM 和 CocoaPods lint。
