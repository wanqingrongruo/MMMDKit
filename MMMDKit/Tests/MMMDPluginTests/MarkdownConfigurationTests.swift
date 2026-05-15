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
}
