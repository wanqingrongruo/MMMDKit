import Foundation

public struct CodeTheme: Equatable, Sendable {
    public var name: String
    public var foregroundColor: String
    public var backgroundColor: String
    public var tokenStyles: [String: CodeTokenStyle]

    public init(
        name: String,
        foregroundColor: String = "label",
        backgroundColor: String = "secondarySystemBackground",
        tokenStyles: [String: CodeTokenStyle] = [:]
    ) {
        self.name = name
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.tokenStyles = tokenStyles
    }

    public static let github = CodeTheme(
        name: "github",
        foregroundColor: "label",
        backgroundColor: "secondarySystemBackground",
        tokenStyles: [
            "keyword": .init(foregroundColor: "systemPurple", fontTraits: ["bold"]),
            "string": .init(foregroundColor: "systemRed"),
            "number": .init(foregroundColor: "systemOrange"),
            "comment": .init(foregroundColor: "secondaryLabel", fontTraits: ["italic"])
        ]
    )

    public static let dark = CodeTheme(
        name: "dark",
        foregroundColor: "white",
        backgroundColor: "black",
        tokenStyles: [
            "keyword": .init(foregroundColor: "systemPurple", fontTraits: ["bold"]),
            "string": .init(foregroundColor: "systemGreen"),
            "number": .init(foregroundColor: "systemOrange"),
            "comment": .init(foregroundColor: "secondaryLabel", fontTraits: ["italic"])
        ]
    )

    public static let `default` = CodeTheme.github
}

public struct CodeTokenStyle: Equatable, Sendable {
    public var foregroundColor: String
    public var fontTraits: [String]

    public init(foregroundColor: String, fontTraits: [String] = []) {
        self.foregroundColor = foregroundColor
        self.fontTraits = fontTraits
    }
}

public struct HighlightResult: Equatable, Sendable {
    public var language: String?
    public var tokens: [HighlightToken]

    public init(language: String?, tokens: [HighlightToken]) {
        self.language = language
        self.tokens = tokens
    }
}

public struct HighlightToken: Equatable, Sendable {
    public var text: String
    public var scope: String?

    public init(text: String, scope: String? = nil) {
        self.text = text
        self.scope = scope
    }
}

public struct MathEnvironment: Equatable, Sendable {
    public var scale: Double
    public var colorScheme: String

    public init(scale: Double = 2, colorScheme: String = "light") {
        self.scale = scale
        self.colorScheme = colorScheme
    }
}

public struct MathRenderResult: Equatable, Sendable {
    public enum Representation: Equatable, Sendable {
        case plainText(String)
        case svg(String)
        case imageData(Data)
    }

    public var representation: Representation
    public var accessibilityLabel: String

    public init(representation: Representation, accessibilityLabel: String) {
        self.representation = representation
        self.accessibilityLabel = accessibilityLabel
    }
}

public enum HTMLRenderCapability: Equatable, Sendable {
    case nativeInline
    case nativeBlock
    case webViewFallback
    case unsupported
}

public struct AccessibilityNode: Equatable, Sendable {
    public var label: String
    public var traits: [String]

    public init(label: String, traits: [String] = []) {
        self.label = label
        self.traits = traits
    }
}

public struct CopyPayload: Equatable, Sendable {
    public var plainText: String
    public var markdown: String

    public init(plainText: String, markdown: String) {
        self.plainText = plainText
        self.markdown = markdown
    }
}
