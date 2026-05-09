# 示例

示例目录包含通过 CocoaPods 接入 MMMDKit 的原生 App 工程和测试数据。

共享测试数据位于：

- `Examples/Shared/DemoMarkdownSamples.swift`

这个文件需要同时加入 iOS demo target 和 macOS demo target。

## iOSDemo

进入 `Examples/iOSDemo` 执行：

```bash
pod install
```

之后使用 `MMMDKitiOSDemo.xcworkspace` 打开工程运行。

工程已经包含：

- `MMMDKitiOSDemo.xcodeproj`
- `MMMDKitiOSDemoApp.swift`
- `../Shared/DemoMarkdownSamples.swift`

需要引入：

- `MMMDCore`
- `MMMDParserCmark`
- `MMMDHighlighter`
- `MMMDMath`
- `MMMDHTML`
- `MMMDUIKit`

## macOSDemo

进入 `Examples/macOSDemo` 执行：

```bash
pod install
```

之后使用 `MMMDKitMacDemo.xcworkspace` 打开工程运行。

工程已经包含：

- `MMMDKitMacDemo.xcodeproj`
- `MMMDKitMacDemoApp.swift`
- `../Shared/DemoMarkdownSamples.swift`

需要引入：

- `MMMDCore`
- `MMMDParserCmark`
- `MMMDHighlighter`
- `MMMDMath`
- `MMMDHTML`
- `MMMDAppKit`
