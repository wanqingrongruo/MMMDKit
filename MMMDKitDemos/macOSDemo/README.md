# macOS Demo

这个目录包含 AppKit macOS demo。Demo 推荐通过 Swift Package Manager 接入本地 `MMMDKit` package。

当前 demo 分为静态数据和流式输出两个 tab，并把通用列表、消息气泡、图片加载和流式控制拆成独立文件。macOS 列表使用 `MacMessageLayoutModel` / `MacChatBubbleLayout` 预计算气泡尺寸，避免在 `NSCollectionView` 的 `sizeForItemAt` 中重复测量 Markdown。

运行方式：

1. 在 Xcode 中创建 macOS App 工程。
2. 选择 `File > Add Package Dependencies...`。
3. 添加本地 package 路径：同级目录 `../../MMMDKit`。
4. 将 `MMMDKitMacDemoApp.swift`、同目录下的 controller/component 文件，以及 `../Shared/DemoMarkdownSamples.swift` 加入 App target。
5. 在 target 中链接 `MMMDCore`、`MMMDParserCmark`、`MMMDStreaming`、`MMMDHighlighter`、`MMMDMath`、`MMMDHTML`、`MMMDAppKit`。

SPM 会传递引入 SwiftMath，因此 demo 中的 block math 默认使用原生公式排版。

注意：如果改用 CocoaPods 集成，当前不会自动引入 `mgriebling/SwiftMath`，公式会退回 LaTeX 文本 fallback，除非你自行提供 `MarkdownConfiguration.mathRenderer`。

主要文件：

- `MMMDKitMacDemoApp.swift`：App 入口、窗口和 tab 容器。
- `MacChatFeedViewController.swift`：共享 `NSCollectionView` 列表、配置、图片预览和滚动逻辑。
- `StaticMacChatFeedViewController.swift`：静态样例数据。
- `StreamingMacChatFeedViewController.swift`：流式输出示例。
- `ChatMessageComponents.swift`：消息 item、气泡视图和布局模型。
- `DemoImageLoader.swift`：本地 demo 图片加载器。
