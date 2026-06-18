# MMMDKit

这个仓库包含 MMMDKit 库源码和 Demo 源码。真正的 Swift Package 位于 `MMMDKit/`。

```text
MMMDKit/
  MMMDKit/        # Swift Package / CocoaPods 库源码
  MMMDKitDemos/   # SwiftUI demo 源码与共享样例
```

MMMDKit v2 是 SwiftUI-only 改造版本，不再公开 UIKit/AppKit 渲染模块。更多信息见：

- `MMMDKit/README.md`
- `MMMDKit/README.en.md`
- `MMMDKit/Docs/Migration-v1-to-v2.md`

## 常用验证命令

```bash
cd MMMDKit
swift build
swift test
```
