import Foundation

public struct MarkdownTheme: Equatable, Sendable {
    public var typography: MarkdownTypography
    public var colors: MarkdownColors
    public var spacing: MarkdownSpacing
    public var codeTheme: CodeTheme

    public init(
        typography: MarkdownTypography = .default,
        colors: MarkdownColors = .default,
        spacing: MarkdownSpacing = .default,
        codeTheme: CodeTheme = .default
    ) {
        self.typography = typography
        self.colors = colors
        self.spacing = spacing
        self.codeTheme = codeTheme
    }

    public static let `default` = MarkdownTheme()
}

public struct MarkdownTypography: Equatable, Sendable {
    public var body: FontToken
    public var code: FontToken
    public var heading1: FontToken
    public var heading2: FontToken

    public init(
        body: FontToken,
        code: FontToken,
        heading1: FontToken,
        heading2: FontToken
    ) {
        self.body = body
        self.code = code
        self.heading1 = heading1
        self.heading2 = heading2
    }

    public static let `default` = MarkdownTypography(
        body: .init(textStyle: "body", pointSize: 17, weight: "regular"),
        code: .init(textStyle: "body", pointSize: 15, weight: "regular", design: "monospaced"),
        heading1: .init(textStyle: "title2", pointSize: 22, weight: "semibold"),
        heading2: .init(textStyle: "title3", pointSize: 20, weight: "semibold")
    )
}

public struct FontToken: Equatable, Sendable {
    public var textStyle: String
    public var pointSize: Double
    public var weight: String
    public var design: String

    public init(textStyle: String, pointSize: Double, weight: String, design: String = "default") {
        self.textStyle = textStyle
        self.pointSize = pointSize
        self.weight = weight
        self.design = design
    }
}

public struct MarkdownColors: Equatable, Sendable {
    public var text: String
    public var secondaryText: String
    public var link: String
    public var codeBackground: String
    public var tableBorder: String

    public init(
        text: String,
        secondaryText: String,
        link: String,
        codeBackground: String,
        tableBorder: String
    ) {
        self.text = text
        self.secondaryText = secondaryText
        self.link = link
        self.codeBackground = codeBackground
        self.tableBorder = tableBorder
    }

    public static let `default` = MarkdownColors(
        text: "label",
        secondaryText: "secondaryLabel",
        link: "systemBlue",
        codeBackground: "secondarySystemBackground",
        tableBorder: "separator"
    )
}

public struct MarkdownSpacing: Equatable, Sendable {
    public var blockSpacing: Double
    public var paragraphSpacing: Double
    public var listIndent: Double
    public var codePadding: Double

    public init(blockSpacing: Double, paragraphSpacing: Double, listIndent: Double, codePadding: Double) {
        self.blockSpacing = blockSpacing
        self.paragraphSpacing = paragraphSpacing
        self.listIndent = listIndent
        self.codePadding = codePadding
    }

    public static let `default` = MarkdownSpacing(
        blockSpacing: 12,
        paragraphSpacing: 8,
        listIndent: 24,
        codePadding: 12
    )
}
