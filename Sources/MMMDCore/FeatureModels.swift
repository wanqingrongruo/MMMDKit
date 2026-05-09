import Foundation

public struct CodeTheme: Equatable, Sendable {
    public var name: String

    public init(name: String) {
        self.name = name
    }

    public static let `default` = CodeTheme(name: "github")
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
