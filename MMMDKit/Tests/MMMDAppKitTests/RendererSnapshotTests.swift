import XCTest
@testable import MMMDAppKit
import MMMDCore

#if canImport(AppKit)
import AppKit

final class RendererSnapshotTests: XCTestCase {
    
    func testMarkdownNSViewHierarchySnapshot() {
        let view = MarkdownNSView()
        
        let document = MarkdownDocument(blocks: [
            .heading(level: 1, content: .init(text: "Title")),
            .paragraph(.init(text: "Hello World"))
        ])
        
        view.render(document)
        view.layoutSubtreeIfNeeded()
        
        // Pseudo-snapshot: we verify the generated view hierarchy string.
        // In a real project, you would use swift-snapshot-testing to compare images.
        let hierarchy = buildViewHierarchyString(view)
        print("HIERARCHY:\\n\\(hierarchy)")
        
        XCTAssertTrue(hierarchy.contains("TextBlockView") || hierarchy.contains("NSTextView"), "Should contain text block view")
        XCTAssertTrue(hierarchy.contains("NSStackView"), "Should use a stack view for vertical layout")
    }

    func testMarkdownLayoutEngineMeasuresDocument() {
        let document = MarkdownDocument(blocks: [
            .heading(level: 1, content: .init(text: "Title")),
            .paragraph(.init(text: "Hello World")),
            .code(.init(language: "swift", content: "let value = 1"))
        ])

        let result = MarkdownLayoutEngine.measure(
            document: document,
            fittingWidth: 320,
            configuration: .init()
        )

        XCTAssertEqual(result.size.width, 320)
        XCTAssertGreaterThan(result.size.height, 0)
    }
    
    private func buildViewHierarchyString(_ view: NSView, indent: String = "") -> String {
        var result = indent + String(describing: type(of: view)) + "\n"
        for subview in view.subviews {
            result += buildViewHierarchyString(subview, indent: indent + "  ")
        }
        return result
    }
}
#endif
