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
        XCTAssertFalse(hierarchy.contains("NSStackView"), "MarkdownNSView should use the unified frame layout instead of stack-driven sizing")
        XCTAssertTrue(view.isFlipped, "Frame-driven Markdown layout should use top-left coordinates on AppKit")
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

    func testMarkdownLayoutEngineIncludesCodeAndTableContentHeight() {
        let document = MarkdownDocument(blocks: [
            .code(.init(language: "swift", content: "let a = 1\nlet b = 2\nprint(a + b)")),
            .table(.init(
                header: [.init(text: "名称"), .init(text: "说明")],
                rows: [
                    [.init(text: "MarkdownNSView"), .init(text: "AppKit 渲染入口")],
                    [.init(text: "CodeBlockView"), .init(text: "代码块渲染")]
                ]
            ))
        ])

        let result = MarkdownLayoutEngine.measure(
            document: document,
            fittingWidth: 360,
            configuration: .init()
        )

        XCTAssertGreaterThan(result.size.height, 160)
    }

    func testMarkdownNSViewIntrinsicHeightMatchesLayoutEngine() {
        let document = MarkdownDocument(blocks: [
            .paragraph(.init(text: "这是一段用于验证 macOS intrinsicContentSize 的长文本，应该能根据给定宽度自动换行并撑开高度。")),
            .blockquote([.paragraph(.init(text: "引用内容也应该进入统一测量链路。"))]),
            .math(.init(latex: #"f(x)=\int_{-\infty}^{\infty} \hat f(\xi)e^{2\pi i \xi x} d\xi"#, displayMode: true)),
            .image(.init(alt: "示例图片", url: URL(string: "mmmd-demo://architecture")))
        ])
        let configuration = MarkdownConfiguration()
        let measured = MarkdownLayoutEngine.measure(
            document: document,
            fittingWidth: 360,
            configuration: configuration
        )

        let view = MarkdownNSView(frame: NSRect(x: 0, y: 0, width: 360, height: measured.size.height))
        view.configuration = configuration
        view.render(document)
        view.layoutSubtreeIfNeeded()

        XCTAssertEqual(view.intrinsicContentSize.height, measured.size.height, accuracy: 1)
        XCTAssertGreaterThan(measured.size.height, 260)
    }

    func testMarkdownNSViewPlacesTextBeforeFollowingBlocks() {
        let document = MarkdownDocument(blocks: [
            .paragraph(.init(text: "第一段文字必须在顶部显示。")),
            .code(.init(language: "swift", content: "let value = 1")),
            .paragraph(.init(text: "最后一段文字必须在代码块之后显示。"))
        ])
        let configuration = MarkdownConfiguration()
        let measured = MarkdownLayoutEngine.measure(document: document, fittingWidth: 320, configuration: configuration)
        let view = MarkdownNSView(frame: NSRect(x: 0, y: 0, width: 320, height: measured.size.height))
        view.configuration = configuration
        view.render(document)
        view.layoutSubtreeIfNeeded()

        XCTAssertGreaterThanOrEqual(view.subviews.count, 3)
        XCTAssertEqual(view.subviews[0].frame.minY, 0, accuracy: 0.5)
        XCTAssertLessThan(view.subviews[0].frame.maxY, view.subviews[1].frame.minY)
        XCTAssertLessThan(view.subviews[1].frame.maxY, view.subviews[2].frame.minY)
    }

    func testMarkdownNSViewTextViewsHaveVisibleFrames() {
        let document = MarkdownDocument(blocks: [
            .paragraph(.init(text: "家长消息正文必须显示。")),
            .code(.init(language: "swift", content: "let visible = true\nprint(visible)")),
            .table(.init(
                header: [.init(text: "任务项"), .init(text: "完成奖励")],
                rows: [[.init(text: "独立穿衣"), .init(text: "星星 x 1")]]
            ))
        ])
        let measured = MarkdownLayoutEngine.measure(document: document, fittingWidth: 420, configuration: .init())
        let view = MarkdownNSView(frame: NSRect(x: 0, y: 0, width: 420, height: measured.size.height))
        view.render(document)
        view.layoutSubtreeIfNeeded()

        let textViews = collectTextViews(in: view)
        XCTAssertGreaterThanOrEqual(textViews.count, 2)
        XCTAssertTrue(
            textViews.contains { $0.string.contains("家长消息正文必须显示") && $0.frame.width > 1 && $0.frame.height > 1 },
            debugTextViews(textViews)
        )
        XCTAssertTrue(
            textViews.contains { $0.string.contains("let visible") && $0.frame.width > 1 && $0.frame.height > 1 },
            debugTextViews(textViews)
        )
    }

    func testMarkdownCollectionViewHostSharesMeasurementPath() {
        let host = MarkdownCollectionViewHost(frame: NSRect(x: 0, y: 0, width: 420, height: 500))
        let document = MarkdownDocument(blocks: [
            .paragraph(.init(text: "Collection host should reuse the same render plan.")),
            .code(.init(language: "swift", content: "let text = \"hello\"\nprint(text)")),
            .table(.init(
                header: [.init(text: "A"), .init(text: "B")],
                rows: [[.init(text: "1"), .init(text: "2")]]
            ))
        ])

        host.render(document, configuration: .init())
        host.layoutSubtreeIfNeeded()

        let hierarchy = buildViewHierarchyString(host)
        XCTAssertTrue(hierarchy.contains("NSCollectionView"))
    }
    
    private func buildViewHierarchyString(_ view: NSView, indent: String = "") -> String {
        var result = indent + String(describing: type(of: view)) + "\n"
        for subview in view.subviews {
            result += buildViewHierarchyString(subview, indent: indent + "  ")
        }
        return result
    }

    private func collectTextViews(in view: NSView) -> [NSTextView] {
        var result: [NSTextView] = []
        if let textView = view as? NSTextView {
            result.append(textView)
        }
        for subview in view.subviews {
            result.append(contentsOf: collectTextViews(in: subview))
        }
        return result
    }

    private func debugTextViews(_ textViews: [NSTextView]) -> String {
        textViews
            .map { "frame=\($0.frame), text=\($0.string.prefix(40))" }
            .joined(separator: "\n")
    }
}
#endif
