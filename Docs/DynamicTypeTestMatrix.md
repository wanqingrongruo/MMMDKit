# Dynamic Type 测试矩阵

## 目标

MMMDKit 的 UIKit/AppKit 渲染层必须在不同字号、不同内容类型和不同容器宽度下保持可读、不卡顿、不截断。

## iOS / iPadOS 测试档位

- `UIContentSizeCategory.medium`
- `UIContentSizeCategory.large`
- `UIContentSizeCategory.extraLarge`
- `UIContentSizeCategory.extraExtraLarge`
- `UIContentSizeCategory.extraExtraExtraLarge`
- `UIContentSizeCategory.accessibilityMedium`
- `UIContentSizeCategory.accessibilityLarge`
- `UIContentSizeCategory.accessibilityExtraLarge`

## macOS 测试场景

- 默认字体大小。
- 系统辅助功能放大文本。
- 窄窗口：320pt。
- 中等窗口：768pt。
- 宽窗口：1200pt。

## 内容类型

- 段落。
- 标题。
- 有序列表。
- 无序列表。
- 引用块。
- 代码块。
- 链接。
- 粗体和斜体。

## 验收标准

- 文本不被截断。
- 行高随系统字体变化。
- 代码块保持等宽字体。
- 列表 marker 与正文基线对齐。
- 引用块指示线高度覆盖完整内容。
- collection host 在字号变化后可以 reload 并重新测量。
