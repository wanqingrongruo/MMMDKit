import Foundation

public struct ParseOptions: Equatable, Sendable {
    public var enablesGFM: Bool
    public var preservesSourceRanges: Bool

    public init(enablesGFM: Bool = true, preservesSourceRanges: Bool = true) {
        self.enablesGFM = enablesGFM
        self.preservesSourceRanges = preservesSourceRanges
    }
}

public protocol MarkdownParser {
    func parse(_ source: String, options: ParseOptions) throws -> MarkdownDocument
}

public struct PluginContext: Sendable {
    public var configuration: MarkdownConfiguration

    public init(configuration: MarkdownConfiguration) {
        self.configuration = configuration
    }
}

public protocol MarkdownPlugin: Sendable {
    var name: String { get }
    func transform(document: MarkdownDocument, context: PluginContext) throws -> MarkdownDocument
}

public struct RenderContext: Sendable {
    public var theme: MarkdownTheme
    public var environment: RenderEnvironment

    public init(theme: MarkdownTheme = .default, environment: RenderEnvironment = .init()) {
        self.theme = theme
        self.environment = environment
    }
}

public struct RenderEnvironment: Equatable, Sendable {
    public var contentWidth: Double
    public var scale: Double
    public var dynamicTypeSize: String
    public var colorScheme: String

    public init(
        contentWidth: Double = 0,
        scale: Double = 2,
        dynamicTypeSize: String = "large",
        colorScheme: String = "light"
    ) {
        self.contentWidth = contentWidth
        self.scale = scale
        self.dynamicTypeSize = dynamicTypeSize
        self.colorScheme = colorScheme
    }
}

public protocol CodeHighlighter {
    func highlight(code: String, language: String?, theme: CodeTheme) async throws -> HighlightResult
}

public protocol MathRenderer {
    func render(latex: String, displayMode: Bool, environment: MathEnvironment) async throws -> MathRenderResult
}

public protocol HTMLRenderer {
    func capability(for html: HTMLBlock) -> HTMLRenderCapability
}

public struct MarkdownActions: Sendable {
    public var onLinkTap: (@Sendable (URL) -> Void)?
    public var onCopyCode: (@Sendable (_ code: String, _ language: String?) -> Void)?
    public var onHeightChange: (@Sendable (Double) -> Void)?

    public init(
        onLinkTap: (@Sendable (URL) -> Void)? = nil,
        onCopyCode: (@Sendable (_ code: String, _ language: String?) -> Void)? = nil,
        onHeightChange: (@Sendable (Double) -> Void)? = nil
    ) {
        self.onLinkTap = onLinkTap
        self.onCopyCode = onCopyCode
        self.onHeightChange = onHeightChange
    }
}

public struct MarkdownConfiguration: Sendable {
    public var theme: MarkdownTheme
    public var plugins: [MarkdownPlugin]
    public var actions: MarkdownActions
    public var blockRendererRegistry: BlockRendererRegistry

    public init(
        theme: MarkdownTheme = .default,
        plugins: [MarkdownPlugin] = [],
        actions: MarkdownActions = .init(),
        blockRendererRegistry: BlockRendererRegistry = .init()
    ) {
        self.theme = theme
        self.plugins = plugins
        self.actions = actions
        self.blockRendererRegistry = blockRendererRegistry
    }
}

public struct BlockRendererRegistry: Sendable {
    private var rendererNames: [MarkdownBlockKind: String]

    public init(rendererNames: [MarkdownBlockKind: String] = [:]) {
        self.rendererNames = rendererNames
    }

    public mutating func register(kind: MarkdownBlockKind, rendererName: String) {
        rendererNames[kind] = rendererName
    }

    public func rendererName(for kind: MarkdownBlockKind) -> String? {
        rendererNames[kind]
    }
}
