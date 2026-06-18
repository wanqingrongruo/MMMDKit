# MMMDKit v2 TODO

## 已完成

- [x] SPM 产品切到 SwiftUI-only。
- [x] 移除公开 `MMMDUIKit` / `MMMDAppKit` products。
- [x] 移除 UIKit/AppKit podspec。
- [x] 新增 `MMMDSwiftUI` product 和 podspec。
- [x] 新增 `MMMDParserSwiftMarkdown`。
- [x] SPM 默认使用 `swift-markdown` parser。
- [x] CocoaPods 保留 `MMMDParserCmark` fallback parser。
- [x] 新增 `MarkdownText`、`MarkdownDocumentView`、`StreamingMarkdownText`。
- [x] 实现 SwiftUI paragraph、heading、list、blockquote、code、table、math、image、HTML fallback。
- [x] 增加 incomplete Markdown 第一版 rewrite。
- [x] 增加 streaming metrics。
- [x] 默认主题切到 SwiftStreamingMarkdown 风格。
- [x] 删除旧视觉基线主题代码。
- [x] 增加 `MarkdownLocalization`。
- [x] 增加 SwiftUI demo 源码。
- [x] 生成新的 iOS/macOS SwiftUI demo Xcode 工程。
- [x] README / Usage / Migration 双语文档。
- [x] 做 CocoaPods install 级别验证。
- [x] 为 `MMMDSwiftUI` 增加 snapshot test foundation。
- [x] 增强 table layout 和大表格 lazy/限高处理。
- [x] 增强 code highlighter 缓存。
- [x] 增强图片预览默认 UI 和图片 URL 复制回调。
- [x] 将 SwiftUI snapshot test foundation 扩展为 golden metrics snapshot。
- [x] 增强 table sticky header 和列宽估算。
- [x] 增强图片加载缓存和失败重试 UI。
- [x] 将 golden metrics snapshot 扩展为可录制/可审查的 PNG golden fixtures。
- [x] 增强 table 精确列宽测量和列对齐策略。
- [x] 增强图片加载进度、失败原因展示和缓存淘汰策略配置。
- [x] 修复 SwiftUI demo iOS launch screen 全屏显示，并将首屏改为 Markdown/Streaming 示例。
- [x] 修复 demo 流式输出自动滚动。
- [x] 修复 demo 性能监控面板下滑收起手势。
- [x] 修复小屏/列表场景表格横向滚动位置复用和默认列宽。
- [x] 修复 SwiftStreamingMarkdown 单行 `$$...$$` 公式示例解析。
- [x] 增强公式 SwiftUI fallback 展示，避免按代码块样式显示。
- [x] 将 SwiftUI demo 主界面改为 SwiftStreamingMarkdown 式主列表/详情/设置页组织。
- [x] 增加 demo Markdown Theme 设置，覆盖 Automatic/System/Roboto/Presentation/Midnight/Sepia。
- [x] 将 List Performance 改为二级页面，并增加多个列表 Markdown 性能测试场景。
- [x] 修复 SwiftUI 表格单元格 padding 导致的列宽和分隔线错位。
- [x] 修复数学块未渲染阶段显示 raw LaTeX 的兜底样式。
- [x] 增加 SwiftUI demo 图片资源加载，支持 bundle 图片和远程图片失败重试。
- [x] 调整 demo 流式输出跟随逻辑，用户手动滚动后取消自动滚动。
- [x] 参考 SwiftStreamingMarkdown 修复深层嵌套 list 的缩进、marker 和 fallback 解析。
- [x] 增加独立 Images demo，并启用 Markdown 文档级文本选择复制。
- [x] `swift build` 通过。
- [x] `swift test` 基础回归通过。

## 后续

- [x] 删除旧 UIKit/AppKit 源码和 demo 工程。
- [x] 完整清理旧专题文档中的 v1 叙述。
- [ ] 增加 PNG snapshot 差异报告或审查脚本。
- [ ] 增强 table 列冻结、列 resize 和更复杂单元格测量。
- [ ] 增强图片加载真实进度回调和取消加载能力。
