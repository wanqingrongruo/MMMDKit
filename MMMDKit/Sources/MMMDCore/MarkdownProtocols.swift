import Foundation

public struct ParseOptions: Equatable, Sendable {
    public var enablesGFM: Bool
    public var preservesSourceRanges: Bool
    public var speculativeRewrite: Bool
    public var incompleteMarkdownPolicy: IncompleteMarkdownPolicy

    public init(
        enablesGFM: Bool = true,
        preservesSourceRanges: Bool = true,
        speculativeRewrite: Bool = true,
        incompleteMarkdownPolicy: IncompleteMarkdownPolicy = .streamingFriendly
    ) {
        self.enablesGFM = enablesGFM
        self.preservesSourceRanges = preservesSourceRanges
        self.speculativeRewrite = speculativeRewrite
        self.incompleteMarkdownPolicy = incompleteMarkdownPolicy
    }
}

public enum IncompleteMarkdownPolicy: String, Equatable, Sendable {
    case disabled
    case streamingFriendly
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
    public var actions: MarkdownActions
    public var toolbarOptions: ToolbarOptions
    public var blockRendererRegistry: BlockRendererRegistry
    public var inlineRendererRegistry: InlineRendererRegistry
    public var codeHighlighter: (any CodeHighlighter)?
    public var mathRenderer: (any MathRenderer)?
    public var imageLoader: (any ImageLoader)?
    public var codeBlockMaximumWidth: Double?
    public var layoutOptions: MarkdownLayoutOptions
    public var localization: MarkdownLocalization

    public init(
        theme: MarkdownTheme = .default,
        environment: RenderEnvironment = .init(),
        actions: MarkdownActions = .init(),
        toolbarOptions: ToolbarOptions = .init(),
        blockRendererRegistry: BlockRendererRegistry = .init(),
        inlineRendererRegistry: InlineRendererRegistry = .init(),
        codeHighlighter: (any CodeHighlighter)? = nil,
        mathRenderer: (any MathRenderer)? = nil,
        imageLoader: (any ImageLoader)? = nil,
        codeBlockMaximumWidth: Double? = 760,
        layoutOptions: MarkdownLayoutOptions = .init(),
        localization: MarkdownLocalization = .default
    ) {
        self.theme = theme
        self.environment = environment
        self.actions = actions
        self.toolbarOptions = toolbarOptions
        self.blockRendererRegistry = blockRendererRegistry
        self.inlineRendererRegistry = inlineRendererRegistry
        self.codeHighlighter = codeHighlighter
        self.mathRenderer = mathRenderer
        self.imageLoader = imageLoader
        self.codeBlockMaximumWidth = codeBlockMaximumWidth
        self.layoutOptions = layoutOptions
        self.localization = localization
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

public protocol CodeHighlighter: Sendable {
    func highlight(code: String, language: String?, theme: CodeTheme) async throws -> HighlightResult
}

public protocol MathRenderer: Sendable {
    func render(latex: String, displayMode: Bool, environment: MathEnvironment) async throws -> MathRenderResult
}

public protocol HTMLRenderer {
    func capability(for html: HTMLBlock) -> HTMLRenderCapability
}

public protocol ImageLoader: Sendable {
    func loadImageData(from url: URL) async throws -> Data
}

/// 用户在 Markdown 视图上触发的交互行为回调集合
public struct MarkdownActions: Sendable {
    /// 当用户点击 Markdown 中的超链接时触发，参数为目标 URL
    public var onLinkTap: (@Sendable (URL) -> Void)?
    /// 当用户点击代码块的复制按钮时触发，参数分别为代码源码和该代码块的编程语言标识
    public var onCopyCode: (@Sendable (_ code: String, _ language: String?) -> Void)?
    /// 当用户点击代码块的下载按钮时触发，参数分别为代码源码和语言
    public var onDownloadCode: (@Sendable (_ code: String, _ language: String?) -> Void)?
    /// 当用户点击代码块的放大（全屏）按钮时触发
    public var onExpandCode: (@Sendable (_ code: String, _ language: String?) -> Void)?
    
    /// 当用户点击表格的复制按钮时触发，参数为该表格的纯文本/CSV或Markdown表示
    public var onCopyTable: (@Sendable (_ text: String) -> Void)?
    /// 当用户点击表格的下载按钮时触发
    public var onDownloadTable: (@Sendable (_ text: String) -> Void)?
    /// 当用户点击表格的放大（全屏）按钮时触发
    public var onExpandTable: (@Sendable (_ text: String) -> Void)?
    /// 当用户点击图片块时触发，业务侧可在此实现大图预览、保存或自定义浏览器
    public var onImageTap: (@Sendable (_ image: ImageBlock) -> Void)?
    /// 当用户从图片菜单复制 URL 时触发，业务侧可在此埋点或替换后续行为
    public var onCopyImageURL: (@Sendable (_ image: ImageBlock) -> Void)?

    /// 当视图内的动态内容（如异步图片加载完毕、公式渲染完成）导致容器高度发生变化时触发
    public var onHeightChange: (@Sendable (Double) -> Void)?

    public init(
        onLinkTap: (@Sendable (URL) -> Void)? = nil,
        onCopyCode: (@Sendable (_ code: String, _ language: String?) -> Void)? = nil,
        onDownloadCode: (@Sendable (_ code: String, _ language: String?) -> Void)? = nil,
        onExpandCode: (@Sendable (_ code: String, _ language: String?) -> Void)? = nil,
        onCopyTable: (@Sendable (_ text: String) -> Void)? = nil,
        onDownloadTable: (@Sendable (_ text: String) -> Void)? = nil,
        onExpandTable: (@Sendable (_ text: String) -> Void)? = nil,
        onImageTap: (@Sendable (_ image: ImageBlock) -> Void)? = nil,
        onCopyImageURL: (@Sendable (_ image: ImageBlock) -> Void)? = nil,
        onHeightChange: (@Sendable (Double) -> Void)? = nil
    ) {
        self.onLinkTap = onLinkTap
        self.onCopyCode = onCopyCode
        self.onDownloadCode = onDownloadCode
        self.onExpandCode = onExpandCode
        self.onCopyTable = onCopyTable
        self.onDownloadTable = onDownloadTable
        self.onExpandTable = onExpandTable
        self.onImageTap = onImageTap
        self.onCopyImageURL = onCopyImageURL
        self.onHeightChange = onHeightChange
    }
}

/// 控制 SwiftUI 默认渲染器的尺寸、虚拟化和预览行为。
public struct MarkdownLayoutOptions: Equatable, Sendable {
    /// 表格超过该行数时启用内部纵向 lazy 滚动。传入 nil 可关闭默认限制。
    public var tableMaximumVisibleRows: Int?
    /// 大表格启用内部纵向滚动时的最大高度。
    public var tableMaximumHeight: Double?
    /// 表格单元格最小宽度。
    public var tableCellMinWidth: Double
    /// 表格单元格最大宽度。
    public var tableCellMaxWidth: Double
    /// 图片默认展示的最大高度。传入 nil 可让图片按容器自然高度展示。
    public var imageMaximumHeight: Double?
    /// 是否启用内置图片预览 sheet。关闭后仅触发 `onImageTap`。
    public var showsDefaultImagePreview: Bool

    public init(
        tableMaximumVisibleRows: Int? = 40,
        tableMaximumHeight: Double? = 420,
        tableCellMinWidth: Double = 44,
        tableCellMaxWidth: Double = 200,
        imageMaximumHeight: Double? = 320,
        showsDefaultImagePreview: Bool = true
    ) {
        self.tableMaximumVisibleRows = tableMaximumVisibleRows
        self.tableMaximumHeight = tableMaximumHeight
        self.tableCellMinWidth = tableCellMinWidth
        self.tableCellMaxWidth = tableCellMaxWidth
        self.imageMaximumHeight = imageMaximumHeight
        self.showsDefaultImagePreview = showsDefaultImagePreview
    }
}

/// 控制工具栏（代码块、表格等）按钮显隐的配置项
public struct ToolbarOptions: Equatable, Sendable {
    /// 是否展示“复制”按钮，默认为 true
    public var showsCopy: Bool
    /// 是否展示“下载”按钮，默认为 false
    public var showsDownload: Bool
    /// 是否展示“放大/全屏”按钮，默认为 false
    public var showsExpand: Bool

    public init(
        showsCopy: Bool = true,
        showsDownload: Bool = false,
        showsExpand: Bool = false
    ) {
        self.showsCopy = showsCopy
        self.showsDownload = showsDownload
        self.showsExpand = showsExpand
    }
}

/// 渲染 Markdown 视图时的全局配置项
public struct MarkdownConfiguration: Sendable {
    /// 样式主题，控制字体、颜色、间距及代码高亮主题
    public var theme: MarkdownTheme
    /// 插件列表，用于在渲染前对 Markdown 抽象语法树 (AST) 进行预处理和转换
    public var plugins: [MarkdownPlugin]
    /// 交互事件的回调闭包集合，如点击链接、复制代码等
    public var actions: MarkdownActions
    /// 工具栏（代码块、表格等）按钮展示配置
    public var toolbarOptions: ToolbarOptions
    /// 块级元素的自定义渲染器注册表，用于扩展或覆盖默认的块级渲染规则（如自定义 HTML 块）
    public var blockRendererRegistry: BlockRendererRegistry
    /// 行内元素的自定义渲染器注册表，用于扩展或覆盖默认的行内渲染规则（如自定义标签）
    public var inlineRendererRegistry: InlineRendererRegistry
    /// 代码高亮器实现。如果不提供，代码块将仅以等宽字体展示纯文本
    public var codeHighlighter: (any CodeHighlighter)?
    /// 数学公式渲染器实现。如果不提供，公式块将仅展示 LaTeX 源码
    public var mathRenderer: (any MathRenderer)?
    /// 图片加载器实现。如果不提供，图片将无法从网络加载显示
    public var imageLoader: (any ImageLoader)?
    /// 代码块和表格等容器的最大允许宽度。超出该宽度时，容器内部允许水平滚动
    public var codeBlockMaximumWidth: Double?
    /// SwiftUI 默认渲染器的尺寸、虚拟化和预览行为配置
    public var layoutOptions: MarkdownLayoutOptions
    /// Markdown 组件内置按钮、无障碍描述和状态文本使用的本地化文案
    public var localization: MarkdownLocalization

    public init(
        theme: MarkdownTheme = .default,
        plugins: [MarkdownPlugin] = [],
        actions: MarkdownActions = .init(),
        toolbarOptions: ToolbarOptions = .init(),
        blockRendererRegistry: BlockRendererRegistry = .init(),
        inlineRendererRegistry: InlineRendererRegistry = .init(),
        codeHighlighter: (any CodeHighlighter)? = nil,
        mathRenderer: (any MathRenderer)? = nil,
        imageLoader: (any ImageLoader)? = nil,
        codeBlockMaximumWidth: Double? = 760,
        layoutOptions: MarkdownLayoutOptions = .init(),
        localization: MarkdownLocalization = .default
    ) {
        self.theme = theme
        self.plugins = plugins
        self.actions = actions
        self.toolbarOptions = toolbarOptions
        self.blockRendererRegistry = blockRendererRegistry
        self.inlineRendererRegistry = inlineRendererRegistry
        self.codeHighlighter = codeHighlighter
        self.mathRenderer = mathRenderer
        self.imageLoader = imageLoader
        self.codeBlockMaximumWidth = codeBlockMaximumWidth
        self.layoutOptions = layoutOptions
        self.localization = localization
    }

    public func transformedDocument(_ document: MarkdownDocument) throws -> MarkdownDocument {
        let context = PluginContext(configuration: self)
        return try plugins.reduce(document) { current, plugin in
            try plugin.transform(document: current, context: context)
        }
    }
}

/// 块级渲染器注册表。
///
/// 当前注册表保存的是渲染器名称，用于把解析出的块类型与业务侧自定义渲染能力建立映射。
public struct BlockRendererRegistry: Sendable {
    private var rendererNames: [MarkdownBlockKind: String]

    public init(rendererNames: [MarkdownBlockKind: String] = [:]) {
        self.rendererNames = rendererNames
    }

    /// 注册某类块级节点对应的渲染器名称。
    public mutating func register(kind: MarkdownBlockKind, rendererName: String) {
        rendererNames[kind] = rendererName
    }

    /// 查询某类块级节点对应的渲染器名称。
    public func rendererName(for kind: MarkdownBlockKind) -> String? {
        rendererNames[kind]
    }
}

/// 行内渲染器注册表。
///
/// 用于把行内节点类型与业务侧自定义行内渲染能力建立映射。
public struct InlineRendererRegistry: Sendable {
    private var rendererNames: [InlineNodeKind: String]

    public init(rendererNames: [InlineNodeKind: String] = [:]) {
        self.rendererNames = rendererNames
    }

    /// 注册某类行内节点对应的渲染器名称。
    public mutating func register(kind: InlineNodeKind, rendererName: String) {
        rendererNames[kind] = rendererName
    }

    /// 查询某类行内节点对应的渲染器名称。
    public func rendererName(for kind: InlineNodeKind) -> String? {
        rendererNames[kind]
    }
}
