import Foundation
import MMMDCore

public final class CmarkMarkdownParser: MarkdownParser {
    private let bridge: CmarkBridge

    public convenience init() {
        self.init(bridge: CmarkBridge())
    }

    init(bridge: CmarkBridge) {
        self.bridge = bridge
    }

    public func parse(_ source: String, options: ParseOptions = .init()) throws -> MarkdownDocument {
        let rootNode = try bridge.parse(source, options: options)
        return CmarkNodeConverter.document(from: rootNode, source: source)
    }
}
