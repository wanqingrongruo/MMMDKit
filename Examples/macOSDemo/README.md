# macOS Demo

这个目录包含一个最小 AppKit macOS demo 源码文件。

运行方式：

1. 在 Xcode 中创建新的 macOS AppKit App。
2. 添加本地 `MMMDKit` package。
3. 引入 `MMMDParserCmark` 和 `MMMDAppKit` products。
4. 使用 `MMMDKitMacDemoApp.swift` 替换生成的 App 入口文件。

demo 不放进 package manifest，让核心 package 聚焦在可复用库 target 和测试上。
