import XCTest
import MMMDCore

final class MarkdownConfigurationTests: XCTestCase {
    func testBlockRendererRegistryStoresRendererNames() {
        var registry = BlockRendererRegistry()

        registry.register(kind: .code, rendererName: "CustomCodeRenderer")

        XCTAssertEqual(registry.rendererName(for: .code), "CustomCodeRenderer")
        XCTAssertNil(registry.rendererName(for: .table))
    }
}
