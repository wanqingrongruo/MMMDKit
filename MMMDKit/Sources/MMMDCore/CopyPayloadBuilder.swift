import Foundation

public enum CopyPayloadBuilder {
    public static func payload(for document: MarkdownDocument) -> CopyPayload {
        CopyPayload(
            plainText: MarkdownTextExtractor.plainText(from: document),
            markdown: document.source.isEmpty ? MarkdownTextExtractor.plainText(from: document) : document.source
        )
    }

    public static func payload(for codeBlock: CodeBlock) -> CopyPayload {
        let markdown: String
        if let language = codeBlock.language, !language.isEmpty {
            markdown = "```\(language)\n\(codeBlock.content)\n```"
        } else {
            markdown = "```\n\(codeBlock.content)\n```"
        }

        return CopyPayload(plainText: codeBlock.content, markdown: markdown)
    }
}
