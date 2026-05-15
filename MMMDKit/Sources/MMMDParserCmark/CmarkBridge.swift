import Foundation
import MMMDCore

enum CmarkBridgeError: Error {
    case emptyDocument
}

final class CmarkBridge {
    private let engine: CmarkParsingEngine

    init(engine: CmarkParsingEngine = FallbackCmarkParsingEngine()) {
        self.engine = engine
    }

    func parse(_ source: String, options: ParseOptions) throws -> CmarkNode {
        try engine.parse(source, options: options)
    }
}

protocol CmarkParsingEngine {
    func parse(_ source: String, options: ParseOptions) throws -> CmarkNode
}

struct FallbackCmarkParsingEngine: CmarkParsingEngine {
    func parse(_ source: String, options: ParseOptions) throws -> CmarkNode {
        CmarkFallbackNodeBuilder.buildDocument(from: source)
    }
}
