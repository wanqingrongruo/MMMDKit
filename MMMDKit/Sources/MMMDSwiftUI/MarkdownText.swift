import Foundation
import MMMDCore
#if canImport(MMMDParserSwiftMarkdown)
import MMMDParserSwiftMarkdown
#elseif canImport(MMMDParserCmark)
import MMMDParserCmark
#endif
import SwiftUI

public struct SwiftUIMarkdownContext: Sendable {
    public var configuration: MarkdownConfiguration

    public init(configuration: MarkdownConfiguration) {
        self.configuration = configuration
    }
}

/// SwiftUI-only Markdown entry point for static source text.
public struct MarkdownText: View {
    private let markdown: String
    private let configuration: MarkdownConfiguration
    private let parser: any MarkdownParser
    @State private var document = MarkdownDocument(blocks: [])

    public init(
        _ markdown: String,
        configuration: MarkdownConfiguration = .init(),
        parser: (any MarkdownParser)? = nil
    ) {
        self.markdown = markdown
        self.configuration = configuration
        self.parser = parser ?? Self.defaultParser()
    }

    public var body: some View {
        MarkdownDocumentView(document: document, configuration: configuration)
            .task(id: markdown) {
                let parsed = (try? parser.parse(markdown, options: .init())) ?? MarkdownDocument(blocks: [], source: markdown)
                document = parsed
            }
    }

    private static func defaultParser() -> any MarkdownParser {
        #if canImport(MMMDParserSwiftMarkdown)
        return SwiftMarkdownParser()
        #elseif canImport(MMMDParserCmark)
        return CmarkMarkdownParser()
        #else
        fatalError("MMMDKit requires a parser module.")
        #endif
    }
}

/// SwiftUI renderer for a pre-parsed `MarkdownDocument`.
public struct MarkdownDocumentView: View {
    private let document: MarkdownDocument
    private let configuration: MarkdownConfiguration
    @Environment(\.openURL) private var openURL

    public init(document: MarkdownDocument, configuration: MarkdownConfiguration = .init()) {
        self.document = document
        self.configuration = configuration
    }

    public var body: some View {
        let transformed = (try? configuration.transformedDocument(document)) ?? document
        let context = SwiftUIMarkdownContext(configuration: configuration)

        VStack(alignment: .leading, spacing: configuration.theme.spacing.blockSpacing) {
            ForEach(Array(transformed.blocks.enumerated()), id: \.offset) { _, block in
                MarkdownBlockView(block: block, context: context)
            }
        }
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.openURL, OpenURLAction { url in
            if let handler = configuration.actions.onLinkTap {
                handler(url)
                return .handled
            }
            return .systemAction(url)
        })
        .accessibilityElement(children: .contain)
    }
}
