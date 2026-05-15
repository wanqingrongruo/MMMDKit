import XCTest
import MMMDCore
import MMMDHTML

final class HTMLAndLayoutTests: XCTestCase {
    func testHTMLSanitizerRemovesScriptAndEventHandlers() {
        let sanitizer = HTMLSanitizer()

        let result = sanitizer.sanitize(#"<div onclick="run()">Hi<script>alert(1)</script></div>"#)

        XCTAssertEqual(result, "<div>Hi</div>")
    }

    func testLayoutCacheInvalidatesByPredicate() {
        let cache = LayoutCache()
        let key = LayoutCacheKey(blockIndex: 0, environment: .init(contentWidth: 320), theme: .default)
        cache.store(.init(width: 320, height: 44), for: key)

        XCTAssertEqual(cache.value(for: key), .init(width: 320, height: 44))

        cache.invalidate { $0.contentWidth == 320 }

        XCTAssertNil(cache.value(for: key))
    }
}
