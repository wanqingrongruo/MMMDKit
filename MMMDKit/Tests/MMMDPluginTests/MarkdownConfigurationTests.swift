import XCTest
import MMMDCore

final class MarkdownConfigurationTests: XCTestCase {
    func testBlockRendererRegistryStoresRendererNames() {
        var registry = BlockRendererRegistry()

        registry.register(kind: .code, rendererName: "CustomCodeRenderer")

        XCTAssertEqual(registry.rendererName(for: .code), "CustomCodeRenderer")
        XCTAssertNil(registry.rendererName(for: .table))
    }

    func testCodeBlockMaximumWidthIsConfigurable() {
        let defaultConfiguration = MarkdownConfiguration()
        XCTAssertEqual(defaultConfiguration.codeBlockMaximumWidth, 760)

        let unconstrainedConfiguration = MarkdownConfiguration(codeBlockMaximumWidth: nil)
        XCTAssertNil(unconstrainedConfiguration.codeBlockMaximumWidth)

        let customConfiguration = MarkdownConfiguration(codeBlockMaximumWidth: 640)
        XCTAssertEqual(customConfiguration.codeBlockMaximumWidth, 640)
    }

    func testLayoutOptionsAreConfigurable() {
        let defaultConfiguration = MarkdownConfiguration()
        XCTAssertEqual(defaultConfiguration.layoutOptions.tableMaximumVisibleRows, 40)
        XCTAssertEqual(defaultConfiguration.layoutOptions.tableCellMinWidth, 44)
        XCTAssertEqual(defaultConfiguration.layoutOptions.tableCellMaxWidth, 200)
        XCTAssertEqual(defaultConfiguration.layoutOptions.imageMaximumHeight, 320)
        XCTAssertTrue(defaultConfiguration.layoutOptions.showsDefaultImagePreview)

        let customConfiguration = MarkdownConfiguration(
            layoutOptions: .init(
                tableMaximumVisibleRows: nil,
                tableMaximumHeight: nil,
                tableCellMinWidth: 90,
                tableCellMaxWidth: 180,
                imageMaximumHeight: nil,
                showsDefaultImagePreview: false
            )
        )
        XCTAssertNil(customConfiguration.layoutOptions.tableMaximumVisibleRows)
        XCTAssertNil(customConfiguration.layoutOptions.tableMaximumHeight)
        XCTAssertEqual(customConfiguration.layoutOptions.tableCellMinWidth, 90)
        XCTAssertEqual(customConfiguration.layoutOptions.tableCellMaxWidth, 180)
        XCTAssertNil(customConfiguration.layoutOptions.imageMaximumHeight)
        XCTAssertFalse(customConfiguration.layoutOptions.showsDefaultImagePreview)
    }
}
