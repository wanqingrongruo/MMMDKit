# iOS Demo

这个目录包含一个 UIKit iOS demo 源码文件。Demo 推荐通过 Swift Package Manager 接入本地 `MMMDKit` package。

运行方式：

1. 在 Xcode 中创建 iOS App 工程。
2. 选择 `File > Add Package Dependencies...`。
3. 添加本地 package 路径：同级目录 `../../MMMDKit`。
4. 将 `MMMDKitiOSDemoApp.swift` 和 `../Shared/DemoMarkdownSamples.swift` 加入 App target。
5. 在 target 中链接 `MMMDCore`、`MMMDParserCmark`、`MMMDStreaming`、`MMMDHighlighter`、`MMMDMath`、`MMMDHTML`、`MMMDUIKit`。

SPM 会传递引入 SwiftMath，因此 demo 中的 block math 默认使用原生公式排版。

注意：如果改用 CocoaPods 集成，当前不会自动引入 `mgriebling/SwiftMath`，公式会退回 LaTeX 文本 fallback，除非你自行提供 `MarkdownConfiguration.mathRenderer`。
