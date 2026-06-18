# 超大内容虚拟化设计 (Virtualization)

在 AI 场景下，流式输出的代码块和表格可能非常巨大（如数千行代码或数百列表格）。如果我们在外层的 SwiftUI `List` / `ScrollView` / `LazyVStack` 中直接将整个代码块或表格完全展开（撑开到实际高度），会导致：
1. 内存暴涨：所有的子视图（如表格单元格文本视图）和完整的高亮 `AttributedString` 都被加载到内存中。
2. 布局卡顿：外层列表在计算估算高度或执行流式插入动画时，超大内容的约束计算会阻塞主线程。

为了解决这些问题，MMMDKit 提出了以下虚拟化（Virtualization）策略。

## 方案 A：容器内滚动与限高（最简接入）

对于超大代码块或表格，不让它们在外部消息列表中完全展开，而是**限制最大高度**，并在内部开启滚动。

### 实现方式
在 `MarkdownConfiguration` 注册自定义渲染器，为代码块和表格增加高度限制：
```swift
// 伪代码示例：在自定义 SwiftUI CodeBlock renderer 中
ScrollView([.horizontal, .vertical]) {
    CodeBlockContent(code)
}
.frame(maxHeight: 300)
```
*优点*：实现简单，有效控制了单个 Cell 的高度和测量成本。
*缺点*：内部滚动会与外部消息列表的滚动产生手势冲突（需要处理嵌套滚动），且大文本本身生成 AttributeString 的开销未消除。

## 方案 B：AST 拆分虚拟化（推荐）

利用 MMMDKit 的 `MarkdownPlugin` 机制，在渲染管线的早期，将超大 Block 拆分成多个更细粒度的 Block。外层 SwiftUI `List` 或 `LazyVStack` 可以只创建可见区域附近的视图。

### 代码块拆分
实现一个 `CodeVirtualizationPlugin`：
1. 检测到行数超过 100 行的 `.code` 块。
2. 将其拆分为 `.codeHeader`、多个 `.codeLineChunk`（例如每 20 行一个 Block）、`.codeFooter`。
3. 注册对应的 Block Renderer。外层列表会自动回收不可见的 `codeLineChunk` Cell。

### 表格拆分
实现一个 `TableVirtualizationPlugin`：
1. 检测到行数超过 50 行的 `.table` 块。
2. 将其拆分为 `.tableHeader` 和 多个 `.tableRowChunk`。
3. 业务层甚至可以将表格转为单独的“点击查看详情” Block，点击后在新页面用全屏 SwiftUI `List` / `Grid` 虚拟化渲染。

## 方案 C：内嵌专用 SwiftUI 容器 (复杂交互)

如果必须在当前消息流中展示完整的横竖双向滚动表格，且数据量极大。
- 放弃一次性 `VStack` / `Grid` 组装表格，将表格渲染替换为专用 SwiftUI 虚拟化容器。
- 对于极其庞大的代码块，将其拆成按行或按 chunk 渲染的 lazy 内容。
由于嵌套滑动和状态管理的复杂性，一般仅在业务明确要求桌面级数据展示时才采用此方案。

## 总结

MMMDKit 作为一个 SwiftUI-only 基础渲染框架，默认实现优先保证结构简单、行为可预期和跨平台一致。
面对超大内容的业务场景，**推荐使用 方案 A（限高嵌套滚动）或 方案 B（AST 拆分）**，通过 `MarkdownConfiguration` 注册自定义 Plugin 和 Renderer 即可完成替换，无需修改框架核心代码。
