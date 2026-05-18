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

    func testStreamingSessionAcceptsIncrementalText() {
        let session = StreamingMarkdownSession(
            parser: CmarkMarkdownParser(),
            updateInterval: 0,
            deliveryQueue: .main
        )
        let expectation = expectation(description: "session emits streaming and finished updates")
        expectation.expectedFulfillmentCount = 2
        var diffs: [MarkdownRenderDiff] = []
        session.onUpdate = { diff in
            diffs.append(diff)
            expectation.fulfill()
        }

        session.append("# Title\n\n")
        session.finish()

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(diffs.first?.phase, .streaming)
        XCTAssertEqual(diffs.last?.phase, .finished)
        XCTAssertEqual(diffs.last?.document.source, "# Title\n\n")
    }
}
