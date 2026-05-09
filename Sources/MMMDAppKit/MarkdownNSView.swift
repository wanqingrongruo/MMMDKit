import Foundation
import MMMDCore

#if canImport(AppKit)
import AppKit

open class MarkdownNSView: NSView {
    public private(set) var document = MarkdownDocument(blocks: [])
    public var configuration = MarkdownConfiguration()

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(false)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setAccessibilityElement(false)
    }

    open func render(_ document: MarkdownDocument) {
        self.document = document
        setAccessibilityLabel(MarkdownTextExtractor.plainText(from: document))
        needsLayout = true
    }
}
#else
public final class MarkdownNSView {
    public private(set) var document = MarkdownDocument(blocks: [])
    public var configuration = MarkdownConfiguration()

    public init() {}

    public func render(_ document: MarkdownDocument) {
        self.document = document
    }
}
#endif
