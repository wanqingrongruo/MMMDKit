# childPlay

这个仓库同时包含 MMMDKit 库源码和独立 Demo 工程。仓库根目录只负责组织项目；真正的 Swift Package 位于 `MMMDKit/`。

## 目录结构

```text
childPlay/
  MMMDKit/        # Swift Package / CocoaPods 库源码
  MMMDKitDemos/   # iOS 与 macOS Demo 工程
```

## MMMDKit

`MMMDKit/` 是可被外部项目通过 Swift Package Manager 引入的库目录，包含：

- `Package.swift`
- `Sources/`
- `Tests/`
- `Docs/`
- `*.podspec`

更多库能力、接入方式和自定义说明请查看：

- `MMMDKit/README.md`
- `MMMDKit/Docs/UsageTutorial.md`

## MMMDKitDemos

`MMMDKitDemos/` 是独立 Demo 区域，不属于 Swift Package 内容，因此外部项目通过 SPM 引入 `MMMDKit` 时不会在 package 中看到 Demo 工程。

Demo 包含：

- `MMMDKitDemos/iOSDemo/`
- `MMMDKitDemos/macOSDemo/`
- `MMMDKitDemos/Shared/DemoMarkdownSamples.swift`

两个 Demo 都通过本地 Swift Package Manager 路径 `../../MMMDKit` 引入库。详情见：

- `MMMDKitDemos/README.md`

## 公式渲染差异

SPM 是当前推荐接入方式。通过 SPM 引入 `MMMDUIKit` / `MMMDAppKit` 时，会传递引入 SwiftMath，`$$...$$` block math 默认使用原生公式排版。

CocoaPods 仍可用于集成 MMMDKit 的核心模块和 UIKit/AppKit 渲染模块，但当前原生公式渲染依赖的 `mgriebling/SwiftMath` 主要通过 SPM 分发。因此 CocoaPods 集成时不会自动获得 SwiftMath，公式会 fallback 为 LaTeX 文本显示，除非业务侧自行提供 `MarkdownConfiguration.mathRenderer` 或 vendoring 公式渲染实现。

## 常用验证命令

```bash
cd MMMDKit
swift build

cd ../MMMDKitDemos/iOSDemo
xcodebuild build -scheme MMMDKitiOSDemo -destination 'generic/platform=iOS Simulator' -quiet

cd ../macOSDemo
xcodebuild build -scheme MMMDKitMacDemo -destination 'platform=macOS' -quiet
```

## 提交说明

当前 git 根目录是仓库根 `childPlay/`，不是 `MMMDKit/`。如果使用 SourceTree 或其他 Git 客户端，请打开 `childPlay/` 作为工作副本根目录。
