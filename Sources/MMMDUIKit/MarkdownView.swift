import Foundation
import MMMDCore

#if canImport(UIKit)
import UIKit

open class MarkdownView: UIView {
    public private(set) var document = MarkdownDocument(blocks: [])
    public var configuration = MarkdownConfiguration()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isAccessibilityElement = false
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isAccessibilityElement = false
    }

    open func render(_ document: MarkdownDocument) {
        self.document = document
        accessibilityLabel = MarkdownTextExtractor.plainText(from: document)
        setNeedsLayout()
    }
}
#else
public final class MarkdownView {
    public private(set) var document = MarkdownDocument(blocks: [])
    public var configuration = MarkdownConfiguration()

    public init() {}

    public func render(_ document: MarkdownDocument) {
        self.document = document
    }
}
#endif
