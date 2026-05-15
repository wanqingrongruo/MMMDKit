import XCTest
import MMMDCore

final class CustomizationExamplesTests: XCTestCase {
    func testCustomParserExampleBuildsDocument() throws {
        let parser: MarkdownParser = PlainTextExampleParser()

        let document = try parser.parse("Hello custom parser", options: .init())

        XCTAssertEqual(document.blocks, [.paragraph(.init(text: "Hello custom parser"))])
    }

    func testCustomRendererRegistryExamplesStoreRendererNames() {
        var blockRegistry = BlockRendererRegistry()
        blockRegistry.register(kind: .custom, rendererName: "ProductCardBlockRenderer")

        var inlineRegistry = InlineRendererRegistry()
        inlineRegistry.register(kind: .custom, rendererName: "MentionInlineRenderer")

        let configuration = MarkdownConfiguration(
            blockRendererRegistry: blockRegistry,
            inlineRendererRegistry: inlineRegistry
        )

        XCTAssertEqual(configuration.blockRendererRegistry.rendererName(for: .custom), "ProductCardBlockRenderer")
        XCTAssertEqual(configuration.inlineRendererRegistry.rendererName(for: .custom), "MentionInlineRenderer")
    }

    func testPluginTransformExampleProducesCustomBlock() throws {
        let configuration = MarkdownConfiguration(plugins: [ProductCardPlugin()])
        let document = MarkdownDocument(blocks: [.paragraph(.init(text: "{{product:abc}}"))])

        let transformed = try configuration.transformedDocument(document)

        XCTAssertEqual(transformed.blocks, [.custom(.init(name: "productCard", payload: "abc"))])
    }

    func testCustomThemeExampleCanBeStoredInConfiguration() {
        let theme = MarkdownTheme(
            typography: .default,
            colors: MarkdownColors(
                text: "label",
                secondaryText: "secondaryLabel",
                link: "systemMint",
                codeBackground: "secondarySystemBackground",
                tableBorder: "separator"
            ),
            spacing: MarkdownSpacing(
                blockSpacing: 16,
                paragraphSpacing: 10,
                listIndent: 28,
                codePadding: 14
            ),
            codeTheme: .default
        )

        let configuration = MarkdownConfiguration(theme: theme, codeBlockMaximumWidth: 680)

        XCTAssertEqual(configuration.theme.colors.link, "systemMint")
        XCTAssertEqual(configuration.theme.spacing.blockSpacing, 16)
        XCTAssertEqual(configuration.codeBlockMaximumWidth, 680)
    }
}

private struct PlainTextExampleParser: MarkdownParser {
    func parse(_ source: String, options: ParseOptions) throws -> MarkdownDocument {
        MarkdownDocument(blocks: [.paragraph(.init(text: source))], source: source)
    }
}

private struct ProductCardPlugin: MarkdownPlugin {
    let name = "ProductCardPlugin"

    func transform(document: MarkdownDocument, context: PluginContext) throws -> MarkdownDocument {
        let blocks = document.blocks.map { block -> MarkdownBlock in
            guard case .paragraph(let content) = block else {
                return block
            }
            let text = MarkdownTextExtractor.plainText(from: content)
            guard text.hasPrefix("{{product:"), text.hasSuffix("}}") else {
                return block
            }
            let id = String(text.dropFirst("{{product:".count).dropLast(2))
            return .custom(.init(name: "productCard", payload: id))
        }
        return MarkdownDocument(blocks: blocks, source: document.source, blockSourceRanges: document.blockSourceRanges)
    }
}
