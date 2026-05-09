# iOS Demo

这个目录包含一个最小 UIKit iOS demo 源码文件。

运行方式：

1. 在 Xcode 中创建新的 iOS UIKit App。
2. 添加本地 `MMMDKit` package。
3. 引入 `MMMDParserCmark` 和 `MMMDUIKit` products。
4. 使用 `MMMDKitiOSDemoApp.swift` 替换生成的 App 入口文件。

demo 不放进 package manifest，避免库测试时强制触发 iOS App 构建。
