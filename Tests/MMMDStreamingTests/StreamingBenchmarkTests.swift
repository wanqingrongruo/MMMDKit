import XCTest
import MMMDCore
import MMMDStreaming
import MMMDParserCmark

final class StreamingBenchmarkTests: XCTestCase {
    
    func testStreamingBenchmarkPerformance() throws {
        let parser = CmarkMarkdownParser()
        let processor = StreamingMarkdownProcessor(parser: parser)
        
        let sampleTokens = generateTokens(count: 200)
        
        measure {
            processor.reset()
            for token in sampleTokens {
                processor.append(token)
            }
            processor.finish()
        }
    }
    
    private func generateTokens(count: Int) -> [String] {
        let snippet = "This is a **streaming** test token. "
        return Array(repeating: snippet, count: count)
    }
}
