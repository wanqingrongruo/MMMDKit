import Foundation

/// 负责控制整个 Markdown 渲染的视觉外观，包括字体排版、系统颜色、间距以及代码块高亮主题
public struct MarkdownTheme: Equatable, Sendable {
    /// 字体排版系统，控制正文、标题和代码的字号、字重等属性
    public var typography: MarkdownTypography
    /// 语义化颜色系统，定义了诸如正文、链接、分割线等元素的颜色键值（通过渲染层的工厂转化为具体颜色）
    public var colors: MarkdownColors
    /// 间距系统，决定了块与块之间、段落之间、列表缩进等维度的空白大小
    public var spacing: MarkdownSpacing
    /// 专门负责代码高亮的颜色和样式主题，包含前景色、背景色及各个 Token（如关键字、字符串）的精准配色
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

    public static let `default` = MarkdownTheme(
        typography: .streamingDefault,
        colors: .streamingDefault,
        spacing: .streamingDefault,
        codeTheme: .streamingDefault
    )
}

/// 定义不同语义层级文本的字体配置
public struct MarkdownTypography: Equatable, Sendable {
    /// 基础正文配置
    public var body: FontToken
    /// 行内代码和代码块配置，通常建议使用等宽字体设计
    public var code: FontToken
    /// 一级标题配置 (H1)
    public var heading1: FontToken
    /// 二级标题配置 (H2)
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

    public static let streamingDefault = MarkdownTypography(
        body: .init(textStyle: "body", pointSize: 17, weight: "regular"),
        code: .init(textStyle: "body", pointSize: 15, weight: "regular", design: "monospaced"),
        heading1: .init(textStyle: "largeTitle", pointSize: 28, weight: "regular"),
        heading2: .init(textStyle: "title2", pointSize: 24, weight: "regular")
    )

    public static let `default` = streamingDefault
}

/// 表示一种特定的字体规格单元
public struct FontToken: Equatable, Sendable {
    /// 对应的 iOS/macOS 动态字体层级（如 body, title1, headline 等）
    public var textStyle: String
    /// 基准字号大小。在支持动态字体（Dynamic Type）的系统上，实际大小将基于此按系统缩放比例变化
    public var pointSize: Double
    /// 字体粗细程度（如 regular, medium, bold）
    public var weight: String
    /// 字体变体设计风格（如 default, monospaced, serif）
    public var design: String

    public init(textStyle: String, pointSize: Double, weight: String, design: String = "default") {
        self.textStyle = textStyle
        self.pointSize = pointSize
        self.weight = weight
        self.design = design
    }
}

/// 定义 Markdown 基本元素的语义化颜色。
/// 这些值支持系统的颜色命名（如 "label", "systemBlue"），也支持以 "#" 开头的十六进制颜色字符串（如 "#FF0000"）
public struct MarkdownColors: Equatable, Sendable {
    /// 主要正文文本颜色
    public var text: String
    /// 次要文本颜色（常用于引用块文字、列表标记符号等）
    public var secondaryText: String
    /// 超链接文字颜色
    public var link: String
    /// 代码块和行内代码的默认底层背景色
    public var codeBackground: String
    /// 表格边框和内部网格线颜色
    public var tableBorder: String
    /// 代码块主体背景色
    public var codeBlockBackground: String
    /// 代码块头部文字和按钮颜色
    public var codeBlockHeaderText: String
    /// 表格头部背景色
    public var tableHeaderBackground: String
    /// 引用块左侧竖线颜色
    public var quoteBorder: String

    public init(
        text: String,
        secondaryText: String,
        link: String,
        codeBackground: String,
        tableBorder: String,
        codeBlockBackground: String? = nil,
        codeBlockHeaderText: String? = nil,
        tableHeaderBackground: String? = nil,
        quoteBorder: String? = nil
    ) {
        self.text = text
        self.secondaryText = secondaryText
        self.link = link
        self.codeBackground = codeBackground
        self.tableBorder = tableBorder
        self.codeBlockBackground = codeBlockBackground ?? codeBackground
        self.codeBlockHeaderText = codeBlockHeaderText ?? secondaryText
        self.tableHeaderBackground = tableHeaderBackground ?? codeBackground
        self.quoteBorder = quoteBorder ?? tableBorder
    }

    public static let streamingDefault = MarkdownColors(
        text: "streamingText",
        secondaryText: "streamingSecondaryText",
        link: "streamingLink",
        codeBackground: "streamingCodeBackground",
        tableBorder: "streamingTableBorder",
        codeBlockBackground: "streamingCodeBlockBackground",
        codeBlockHeaderText: "streamingCodeBlockHeaderText",
        tableHeaderBackground: "streamingTableHeaderBackground",
        quoteBorder: "streamingQuoteBorder"
    )

    public static let `default` = streamingDefault
}

/// 定义不同区块与元素间的空间排版尺度（以 pt 为单位）
public struct MarkdownSpacing: Equatable, Sendable {
    /// 块级元素（如段落与列表、表格与代码块）之间的垂直间距
    public var blockSpacing: Double
    /// 段落内部换行或同类型小块级元素的垂直间距
    public var paragraphSpacing: Double
    /// 段落内部文本行距
    public var lineSpacing: Double
    /// 列表项相比外部正文的基础缩进距离
    public var listIndent: Double
    /// 代码块内部内容与边界的内边距 (Padding)
    public var codePadding: Double

    public init(
        blockSpacing: Double,
        paragraphSpacing: Double,
        listIndent: Double,
        codePadding: Double,
        lineSpacing: Double? = nil
    ) {
        self.blockSpacing = blockSpacing
        self.paragraphSpacing = paragraphSpacing
        self.lineSpacing = lineSpacing ?? paragraphSpacing
        self.listIndent = listIndent
        self.codePadding = codePadding
    }

    public static let streamingDefault = MarkdownSpacing(
        blockSpacing: 30,
        paragraphSpacing: 8,
        listIndent: 22,
        codePadding: 16,
        lineSpacing: 5
    )

    public static let `default` = streamingDefault
}
