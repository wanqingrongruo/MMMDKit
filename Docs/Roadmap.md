# MMMDKit 路线图

## Phase 0：基础骨架

目标：验证项目结构、核心协议和基础测试可以正常编译运行。

交付：

- Swift Package 骨架。
- 支持 subspec 的 CocoaPods podspec。
- `MMMDCore` 文档模型和协议。
- 解析器占位适配层。
- 基础流式处理器。
- UIKit iOS demo 与 AppKit macOS demo 源码目录。
- 基础单元测试。

验收：

- `swift test` 在 macOS 上通过。
- 所有非 UI 模块可编译。
- demo 源码引用公开 API。

## Phase 1：MVP 渲染器

目标：让 MMMDKit 可以支撑基础 AI Chat 消息渲染。

交付：

- 接入 cmark-gfm 的 GFM 解析。
- 支持段落、标题、斜体、粗体、链接、列表、引用、分割线、inline code 和 fenced code block。
- 基于 `UICollectionView` 的 UIKit block 宿主。
- 基于 `NSCollectionView` 的 AppKit block 宿主。
- 动态字体支持。
- 基础 VoiceOver 语义。
- 代码块复制。
- 整条消息复制。
- Layout cache。
- 只更新不稳定尾块的流式解析器。

验收：

- 流式输出不闪烁。
- 用户手动滚动时不被强制打断。
- 代码块闭合后再做最终高亮。
- 常见 AI 回答渲染流畅。

## Phase 2：复杂 Block

目标：支持 AI 应用常见复杂内容。

交付：

- 异步代码高亮与主题。
- 带 toolbar 的原生代码块组件。
- 支持横向滚动的原生表格 block。
- inline/display LaTeX renderer 协议。
- HTML renderer 协议和 WebView fallback。
- 图片加载协议。
- 链接和图片点击回调。
- 代码、表格、数学公式、图片、HTML block 的无障碍描述。

验收：

- 表格不破坏主滚动。
- LaTeX 失败时降级为可读源码。
- 复杂 HTML 隔离到 fallback block。
- 高亮不阻塞主线程滚动。

## Phase 3：自定义与插件

目标：每个模块都能独立使用，并支持业务自定义。

交付：

- 稳定的 `MarkdownConfiguration`。
- 自定义 parser。
- 自定义 block renderer 注册。
- 自定义 inline renderer 注册。
- 自定义 theme。
- 自定义 highlighter。
- 自定义 math renderer。
- 自定义 HTML renderer。
- 插件 transform pipeline。
- Mention、Mermaid、自定义卡片示例。

验收：

- 用户可以不 fork 库就替换代码块 renderer。
- 用户可以只使用 `MMMDParserCmark`。
- 用户可以只使用 `MMMDHighlighter`。
- 插件可以新增自定义 block 类型。

## Phase 4：选择、复制与规模化

目标：接近成熟商业 AI App 的使用体验。

交付：

- 跨 block 选择方案调研与实现。
- 更细粒度复制 payload。
- 大文档虚拟化。
- 超大代码块虚拟化。
- 大表格虚拟化。
- 可选 Tree-sitter highlighter。
- 持久化 layout cache。
- Snapshot tests。
- 性能 benchmark。

验收：

- 1 MB Markdown 文档可用。
- 500 条聊天消息滚动稳定。
- 超大代码块不阻塞主线程。
- 复制和选择体验接近系统文本。
