import XCTest
import MMMDCore
import MMMDParserCmark

final class PerformanceTests: XCTestCase {
    
    func testLargeMarkdownParsingPerformance() throws {
        let parser = CmarkMarkdownParser()
        let largeMarkdown = generateLargeMarkdown(repeating: 1000)
        
        measure {
            _ = try? parser.parse(largeMarkdown, options: .init())
        }
    }
    
    private func generateLargeMarkdown(repeating times: Int) -> String {
        let template = """
        # Heading 1
        
        This is a paragraph with **strong** and *emphasis* text.
        
        - List item 1
        - List item 2
        
        > Blockquote
        > with multiple lines
        
        ```swift
        func test() {
            print("Hello World")
        }
        ```
        
        | Header 1 | Header 2 |
        | --- | --- |
        | Cell 1 | Cell 2 |
        
        """
        
        return Array(repeating: template, count: times).joined(separator: "\n\n")
    }
}
