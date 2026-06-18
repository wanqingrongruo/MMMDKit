# MMMDKit Demos

Demo 目录现在以 SwiftUI v2 示例为主。

## SwiftUIDemo

`SwiftUIDemo/SwiftUIDemoApp.swift` 包含：

- SwiftStreamingMarkdown sample 同款 demonstration：Kitchen Sink、Multi-paragraph、Tables、Math、Roboto Themed、Default。
- `Resources/Fixtures/*.md`：直接复用 SwiftStreamingMarkdown sample fixture 数据。
- Streamed / Static 切换、Light / Dark / Device 外观切换。
- 底部性能面板：chars、chunks、renders、elapsed、chars/sec、chunks/sec、parse、render lag。
- List Performance：500 条消息的 `LazyVStack` 列表场景，内容复用 fixture 数据。

接入方式：

1. 创建 iOS 或 macOS SwiftUI App。
2. 通过 SPM 添加本地 package：`../MMMDKit`。
3. 将 `SwiftUIDemo/SwiftUIDemoApp.swift` 和 `SwiftUIDemo/Resources` 加入 App target。
4. 选择 `MMMDKit` product。

旧 `iOSDemo/` 和 `macOSDemo/` 已从 v2 主线移除；迁移信息见 `../MMMDKit/Docs/Migration-v1-to-v2.md`。
