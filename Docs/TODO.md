# MMMDKit TODO

## Phase 0

- [x] 创建仓库骨架。
- [x] 添加 Swift Package Manager 配置。
- [x] 添加支持 subspec 的 CocoaPods podspec。
- [x] 添加架构文档。
- [x] 添加路线图文档。
- [x] iOS demo 使用 UIKit。
- [x] macOS demo 使用 AppKit。
- [ ] 添加 cmark-gfm 构建接入方案。
- [ ] 添加 CI 配置。
- [ ] 添加 lint 和格式化规则。

## Phase 1

- [ ] 实现 cmark-gfm parser bridge。
- [ ] 在解析结果中保留 source range。
- [ ] 实现段落 renderer。
- [ ] 实现标题 renderer。
- [ ] 实现 inline emphasis 和 strong 渲染。
- [ ] 实现链接渲染和点击回调。
- [ ] 实现有序/无序列表渲染。
- [ ] 实现引用块渲染。
- [ ] 实现 fenced code block 渲染。
- [ ] 实现 UIKit collection view host。
- [ ] 实现 AppKit collection view host。
- [ ] 添加 Dynamic Type 测试矩阵。
- [ ] 添加基础 VoiceOver label。
- [ ] 添加整条消息复制。
- [ ] 添加代码块复制。

## Phase 2

- [ ] 实现异步语法高亮。
- [ ] 添加代码主题系统。
- [ ] 添加原生表格 block view。
- [ ] 添加 inline math 解析 hook。
- [ ] 添加 display math block renderer。
- [ ] 添加 HTML sanitizer。
- [ ] 添加 WebView fallback block。
- [ ] 添加图片加载协议。
- [ ] 添加 layout cache 失效测试。

## Phase 3

- [ ] 稳定 `MarkdownConfiguration`。
- [ ] 添加自定义 parser 示例。
- [ ] 添加自定义 block renderer 示例。
- [ ] 添加自定义 inline renderer 示例。
- [ ] 添加 plugin transform 示例。
- [ ] 添加自定义 theme 示例。
- [ ] 添加模块化 CocoaPods 验证。

## Phase 4

- [ ] 原型验证跨 block 选择。
- [ ] 添加大 Markdown 性能测试。
- [ ] 添加超大代码块虚拟化。
- [ ] 添加大表格虚拟化。
- [ ] 添加可选 Tree-sitter highlighter。
- [ ] 添加 renderer snapshot tests。
- [ ] 添加 AI chat benchmark 示例。
