import XCTest
@testable import MMMDUIKit
import MMMDCore

#if canImport(UIKit)
import UIKit

final class UIKitRendererSnapshotTests: XCTestCase {
    
    func testMarkdownViewHierarchySnapshot() {
        let view = MarkdownView()
        
        let document = MarkdownDocument(blocks: [
            .heading(level: 1, content: .init(text: "Title")),
            .paragraph(.init(text: "Hello World"))
        ])
        
        view.render(document)
        view.layoutIfNeeded()
        
        let hierarchy = buildViewHierarchyString(view)
        
        XCTAssertTrue(hierarchy.contains("TextBlockView") || hierarchy.contains("UITextView"), "Should contain text block view")
        XCTAssertTrue(hierarchy.contains("UIStackView"), "Should use a stack view for vertical layout")
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

        XCTAssertGreaterThan(result.size.width, 0)
        XCTAssertLessThanOrEqual(result.size.width, 320)
        XCTAssertGreaterThan(result.size.height, 0)
    }
    
    private func buildViewHierarchyString(_ view: UIView, indent: String = "") -> String {
        var result = indent + String(describing: type(of: view)) + "\n"
        for subview in view.subviews {
            result += buildViewHierarchyString(subview, indent: indent + "  ")
        }
        return result
    }
}
#endif
