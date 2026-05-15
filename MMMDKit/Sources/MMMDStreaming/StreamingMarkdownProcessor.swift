import Foundation
import MMMDCore

public struct MarkdownRenderDiff: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
        case streaming
        case finished
    }

    public var document: MarkdownDocument
    public var stableBlockCount: Int
    public var phase: Phase

    public init(document: MarkdownDocument, stableBlockCount: Int, phase: Phase) {
        self.document = document
        self.stableBlockCount = stableBlockCount
        self.phase = phase
    }
}

public final class StreamingMarkdownProcessor {
    private let parser: MarkdownParser
    private let parseOptions: ParseOptions
    private var buffer = ""

    public var onDiff: ((MarkdownRenderDiff) -> Void)?

    public init(parser: MarkdownParser, parseOptions: ParseOptions = .init()) {
        self.parser = parser
        self.parseOptions = parseOptions
    }

    public func append(_ delta: String) {
        buffer += delta
        emit(phase: .streaming)
    }

    public func finish() {
        emit(phase: .finished)
    }

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
