# 无障碍约定

## 目标

MMMDKit 的基础 block renderer 默认提供 VoiceOver 可读标签。复杂交互后续通过更细粒度的 accessibility element 扩展。

## 当前覆盖

- 段落：使用纯文本作为 accessibility label。
- 标题：使用纯文本作为 accessibility label，UIKit 侧标记为 header trait。
- 列表：每个列表项包含 marker 和正文。
- 引用块：使用引用内容纯文本。
- 代码块：包含语言和代码内容。
- 链接：由系统文本组件提供链接可访问性，并通过 `onLinkTap` 回调业务。

## 后续增强

- AppKit 标题语义需要更完整的 role/attribute 映射。
- 表格需要声明行列数量。
- LaTeX 需要提供可读公式文本。
- 图片需要使用 alt text。
- 代码块需要支持“复制代码”无障碍动作。
