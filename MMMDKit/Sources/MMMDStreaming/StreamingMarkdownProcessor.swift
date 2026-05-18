import Foundation
import MMMDCore

/// 单次流式解析后的渲染差异信息。
///
/// `document` 是当前完整 buffer 解析出的 Markdown 文档；`stableBlockCount`
/// 表示前多少个块在当前阶段可认为已经稳定，UI 层可据此避免对尾部未完成块做昂贵渲染。
public struct MarkdownRenderDiff: Equatable, Sendable {
    /// 流式解析所处阶段。
    public enum Phase: Equatable, Sendable {
        /// 仍在接收增量文本，最后一个块通常可能继续变化。
        case streaming
        /// 上游已经结束，当前文档所有块都可视为稳定。
        case finished
    }

    /// 当前已解析出的完整 Markdown 文档。
    public var document: MarkdownDocument
    /// 当前可视为稳定的块数量。
    public var stableBlockCount: Int
    /// 当前解析阶段。
    public var phase: Phase

    public init(document: MarkdownDocument, stableBlockCount: Int, phase: Phase) {
        self.document = document
        self.stableBlockCount = stableBlockCount
        self.phase = phase
    }
}

/// 面向流式文本的底层 Markdown 解析器。
///
/// 该类型只负责维护文本 buffer、调用 `MarkdownParser` 解析并输出 `MarkdownRenderDiff`。
/// 如果需要线程安全和节流更新，请优先使用更高层的 `StreamingMarkdownSession`。
public final class StreamingMarkdownProcessor {
    private let parser: MarkdownParser
    private let parseOptions: ParseOptions
    private var buffer = ""

    public var onDiff: ((MarkdownRenderDiff) -> Void)?

    /// 创建一个流式 Markdown 处理器。
    /// - Parameters:
    ///   - parser: 实际执行 Markdown 解析的解析器。
    ///   - parseOptions: 每次解析时使用的解析选项。
    public init(parser: MarkdownParser, parseOptions: ParseOptions = .init()) {
        self.parser = parser
        self.parseOptions = parseOptions
    }

    /// 追加一段新到达的 Markdown 文本，并立即输出一次 `.streaming` diff。
    public func append(_ delta: String) {
        buffer += delta
        emit(phase: .streaming)
    }

    /// 标记流式输入结束，并输出一次 `.finished` diff。
    public func finish() {
        emit(phase: .finished)
    }

    /// 清空内部 buffer，准备复用该处理器处理下一段流式内容。
    public func reset() {
        buffer.removeAll()
    }

    private func emit(phase: MarkdownRenderDiff.Phase) {
        guard let document = try? parser.parse(buffer, options: parseOptions) else {
            return
        }

        let stableCount: Int
        switch phase {
        case .streaming:
            stableCount = max(0, document.blocks.count - 1)
        case .finished:
            stableCount = document.blocks.count
        }

        onDiff?(.init(document: document, stableBlockCount: stableCount, phase: phase))
    }
}
