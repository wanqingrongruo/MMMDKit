import Foundation
import MMMDCore

/// 基于 cmark 适配层的 Markdown 解析器。
///
/// 该类型是 MMMDKit 默认推荐的解析入口，负责把 Markdown 字符串转换为 `MarkdownDocument`。
/// 当前桥接层会优先使用可用的 cmark 实现，并在必要时使用内置 fallback 解析能力。
public final class CmarkMarkdownParser: MarkdownParser {
    private let bridge: CmarkBridge

    /// 创建默认 cmark 解析器。
    public convenience init() {
        self.init(bridge: CmarkBridge())
    }

    init(bridge: CmarkBridge) {
        self.bridge = bridge
    }

    /// 解析 Markdown 字符串。
    /// - Parameters:
    ///   - source: 原始 Markdown 文本。
    ///   - options: 解析选项，例如是否保留 source range。
    /// - Returns: 可被渲染层消费的 Markdown 文档模型。
    public func parse(_ source: String, options: ParseOptions = .init()) throws -> MarkdownDocument {
        let rootNode = try bridge.parse(source, options: options)
        return CmarkNodeConverter.document(from: rootNode, source: source)
    }
}
