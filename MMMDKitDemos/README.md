# 示例

示例目录包含通过 Swift Package Manager 接入 MMMDKit 的原生 App 源码和测试数据。

共享测试数据位于：

- `Shared/DemoMarkdownSamples.swift`

这个文件需要同时加入 iOS demo target 和 macOS demo target。

## 接入方式

Demo 现在推荐使用 SPM 本地包接入：

1. 在 Xcode 中创建 iOS 或 macOS App 工程。
2. 选择 `File > Add Package Dependencies...`。
3. 添加本地 package 路径：同级目录 `../MMMDKit`。
4. 将对应 demo 源码文件加入 App target：
   - iOS: `iOSDemo/*.swift`
   - macOS: `macOSDemo/*.swift`
   - 共享数据: `Shared/DemoMarkdownSamples.swift`

## iOSDemo

需要引入：

- `MMMDCore`
- `MMMDParserCmark`
- `MMMDHighlighter`
- `MMMDMath`
- `MMMDHTML`
- `MMMDUIKit`
- `SwiftMath`（通过 MMMDKit 的 SPM 依赖传递引入，用于原生公式渲染）

## macOSDemo

需要引入：

- `MMMDCore`
- `MMMDParserCmark`
- `MMMDHighlighter`
- `MMMDMath`
- `MMMDHTML`
- `MMMDAppKit`
- `SwiftMath`（通过 MMMDKit 的 SPM 依赖传递引入，用于原生公式渲染）

macOS demo 的消息列表使用预计算布局模型：先通过 `MarkdownLayoutEngine.measure(...)` 得到 Markdown 内容尺寸，再组合标题和气泡内边距，最后由 `NSCollectionView` 直接读取模型高度。这样可以避免窗口 resize 或流式刷新时在 delegate 中反复测量。

## CocoaPods 注意事项

CocoaPods 仍可用于集成 MMMDKit 的核心模块和 UIKit/AppKit 渲染模块，但当前原生公式渲染依赖的 `mgriebling/SwiftMath` 主要通过 SPM 分发。  
因此 CocoaPods 集成时不会自动获得 SwiftMath，公式会回退到 LaTeX 文本 fallback，除非业务侧自行提供 `MarkdownConfiguration.mathRenderer` 或额外 vendoring 公式渲染实现。
