# 代码风格

## 目标

MMMDKit 的代码风格以 Apple 平台原生开发习惯为基础，优先保证可读性、模块边界清晰和长期维护成本可控。

## 工具

项目提供两类配置：

- `.swiftlint.yml`：用于静态规则检查。
- `.swift-format`：用于 Swift 官方格式化工具。

当前不把这两个工具作为本地构建的强依赖，避免影响没有安装工具的贡献者。CI 后续可以在环境稳定后增加强校验。

## 注释规范

- 文档、注释、TODO 默认使用中文。
- 公开 API 后续需要补充中文文档注释。
- 注释解释设计意图，不重复代码字面含义。

## 命名规范

- 模块统一使用 `MMMD` 前缀。
- UIKit 类型使用 `MarkdownView`、`CodeBlockView` 这类平台自然命名。
- AppKit 类型在需要区分时使用 `NS` 后缀或 `MarkdownNSView` 形式。
- 协议命名表达能力，例如 `MarkdownParser`、`CodeHighlighter`、`MathRenderer`。

## 格式化建议

本地安装工具后可以运行：

```bash
swift-format format -i -r Sources Tests Examples
swiftlint lint
```

如果格式化结果影响可读性，可以优先保持清晰表达，再调整配置。
