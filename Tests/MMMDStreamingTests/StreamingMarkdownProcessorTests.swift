import XCTest
import MMMDCore
import MMMDParserCmark
import MMMDStreaming

final class StreamingMarkdownProcessorTests: XCTestCase {
    func testStreamingEmitsUnstableTailUntilFinished() {
        let processor = StreamingMarkdownProcessor(parser: CmarkMarkdownParser())
        var diffs: [MarkdownRenderDiff] = []
        processor.onDiff = { diffs.append($0) }

        processor.append("# Title\n\n")
        processor.append("Body")
        processor.finish()

        XCTAssertFalse(diffs.isEmpty)
        XCTAssertEqual(diffs.last?.phase, .finished)
        XCTAssertEqual(diffs.last?.stableBlockCount, diffs.last?.document.blocks.count)
    }
}
