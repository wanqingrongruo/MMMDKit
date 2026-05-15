# 跨 Block 选择验证

在基于 Native View 树（UICollectionView/NSCollectionView）渲染复杂 Markdown 时，支持跨 Block 文本选择是一个业界难题。我们在本阶段进行了原型验证与技术方案选型。

## 技术挑战

1. **离散的视图层级**
   当我们将文本分割成多个 `UILabel`、`NSTextField` 以及包含 `UIScrollView` 的表格、代码块时，原生的文本选择器无法跨越视图边界。
2. **事件冲突**
   如果在整个消息上方叠加一个透明的 `UITextView` 来接管所有的手势和选择绘制，会导致底层需要交互的 Block（例如支持横向滚动的代码块、表格、可点击的链接）无法正常接收触摸事件。

## 可选方案与验证

### 方案 A：透明 UITextView/NSTextView 遮罩
- **机制**：在渲染整个 `MarkdownView` 时，在背后（或通过 HitTest 转发的前景）放置一个排版一致的隐藏 TextView。用户其实是在选隐藏的 TextView，但视觉上看起来像是在选前景内容。
- **缺点**：由于包含复杂的内联组件和滚动组件，无法保证隐藏 TextView 的排版和前景绝对一致。滚动组件会导致选区失效。

### 方案 B：使用底层的 TextKit/TextKit 2
- **机制**：完全抛弃按 Block 构建视图，而是使用单一的 `UITextView`，通过自定义 `NSTextAttachment` 来插入所有的复杂块（代码、表格）。
- **缺点**：这违背了我们“Block Model 保持稳定、基于原生组件分层渲染”的设计原则。复杂的交互和嵌套滚动在 `NSTextAttachment` 中极难实现，并且性能存在瓶颈。

### 方案 C：使用 iOS 17 / macOS 14+ 的选区 API
- **机制**：利用 `UITextSelectionDisplayInteraction` 等新 API 自定义选择句柄和选区高亮绘制。
- **缺点**：不兼容目标环境（iOS 15.0 / macOS 12.0），且需要自己实现文字层面的 Hit Testing。

### 方案 D：退而求其次（当前方案）
考虑到此框架主要用于 AI Chat 场景，用户的复制行为大多是**整条复制**或**特定代码块复制**。
- 支持整个 `MarkdownDocument` 的快捷复制（已实现）。
- 支持代码块的独立一键复制（已实现）。
- 如果用户需要在普通文本中做局部选择，系统默认支持在单个 `UILabel` / `NSTextField` (selectable) 内部的选择。跨段落暂时不提供无缝连续选择。

## 结论

在当前版本（iOS 15 / macOS 12）及 Block 视图拆分的架构下，原生的跨 View 连续文本选择成本过高且体验不佳。我们的策略是：
1. **强化块级复制**：提供整段消息、代码块的一键复制能力，这能覆盖 95% 的 AI 场景需求。
2. **块内选择**：确保普通段落文本框开启 `isSelectable`（macOS）或提供菜单交互，允许用户选块内的文字。

因此，跨 Block 选区的全面支持暂不列入当前架构必保功能，后续如果基于 SwiftUI 的 Text 选择有突破，再考虑迁移。
