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

    func testStreamingDiffIncludesParseMetrics() {
        let processor = StreamingMarkdownProcessor(parser: CmarkMarkdownParser())
        var diffs: [MarkdownRenderDiff] = []
        processor.onDiff = { diffs.append($0) }

        processor.append("Hello")
        processor.append(" world")

        XCTAssertEqual(diffs.last?.metrics.chunkCount, 2)
        XCTAssertEqual(diffs.last?.metrics.sourceLength, "Hello world".count)
        XCTAssertGreaterThanOrEqual(diffs.last?.metrics.parseDuration ?? -1, 0)
        XCTAssertGreaterThanOrEqual(diffs.last?.metrics.elapsed ?? -1, 0)
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

    func testStreamingSessionAddsRenderMetrics() {
        let session = StreamingMarkdownSession(
            parser: CmarkMarkdownParser(),
            updateInterval: 0,
            deliveryQueue: .main
        )
        let expectation = expectation(description: "session emits render metrics")
        expectation.expectedFulfillmentCount = 2
        var diffs: [MarkdownRenderDiff] = []
        session.onUpdate = { diff in
            diffs.append(diff)
            expectation.fulfill()
        }

        session.append("Hello")
        session.finish()

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(diffs.map(\.metrics.renderCount), [1, 2])
        XCTAssertNotNil(diffs.last?.metrics.renderLatency)
    }
}
