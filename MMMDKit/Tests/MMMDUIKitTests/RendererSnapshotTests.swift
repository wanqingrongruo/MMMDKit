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
    
    private func buildViewHierarchyString(_ view: UIView, indent: String = "") -> String {
        var result = indent + String(describing: type(of: view)) + "\n"
        for subview in view.subviews {
            result += buildViewHierarchyString(subview, indent: indent + "  ")
        }
        return result
    }
}
#endif
