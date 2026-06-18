import Foundation

/// Markdown 组件内部交互与无障碍文案。
///
/// App 可以直接传入自定义实例覆盖默认中文/英文资源；渲染层不硬编码用户可见字符串。
public struct MarkdownLocalization: Equatable, Sendable {
    public var codeBlockTitle: String
    public var tableTitle: String
    public var copy: String
    public var copied: String
    public var retry: String
    public var download: String
    public var expand: String
    public var openLink: String
    public var imagePreview: String
    public var imageLoading: String
    public var imageLoadFailed: String
    public var imageMissingURL: String
    public var imageMissingLoader: String
    public var listItem: String
    public var tableCellPositionFormat: String

    public init(
        codeBlockTitle: String,
        tableTitle: String,
        copy: String,
        copied: String,
        retry: String,
        download: String,
        expand: String,
        openLink: String,
        imagePreview: String,
        imageLoading: String,
        imageLoadFailed: String,
        imageMissingURL: String,
        imageMissingLoader: String,
        listItem: String,
        tableCellPositionFormat: String
    ) {
        self.codeBlockTitle = codeBlockTitle
        self.tableTitle = tableTitle
        self.copy = copy
        self.copied = copied
        self.retry = retry
        self.download = download
        self.expand = expand
        self.openLink = openLink
        self.imagePreview = imagePreview
        self.imageLoading = imageLoading
        self.imageLoadFailed = imageLoadFailed
        self.imageMissingURL = imageMissingURL
        self.imageMissingLoader = imageMissingLoader
        self.listItem = listItem
        self.tableCellPositionFormat = tableCellPositionFormat
    }

    public static let english = MarkdownLocalization(
        codeBlockTitle: "Code",
        tableTitle: "Table",
        copy: "Copy",
        copied: "Copied",
        retry: "Retry",
        download: "Download",
        expand: "Expand",
        openLink: "Open link",
        imagePreview: "Preview image",
        imageLoading: "Loading image",
        imageLoadFailed: "Image failed to load",
        imageMissingURL: "Missing image URL",
        imageMissingLoader: "Missing image loader",
        listItem: "List item",
        tableCellPositionFormat: "Row %d of %d, Column %d of %d"
    )

    public static let simplifiedChinese = MarkdownLocalization(
        codeBlockTitle: "代码",
        tableTitle: "表格",
        copy: "复制",
        copied: "已复制",
        retry: "重试",
        download: "下载",
        expand: "展开",
        openLink: "打开链接",
        imagePreview: "预览图片",
        imageLoading: "图片加载中",
        imageLoadFailed: "图片加载失败",
        imageMissingURL: "缺少图片地址",
        imageMissingLoader: "缺少图片加载器",
        listItem: "列表项",
        tableCellPositionFormat: "第 %d 行，共 %d 行；第 %d 列，共 %d 列"
    )

    public static var `default`: MarkdownLocalization {
        if Locale.preferredLanguages.first?.hasPrefix("zh") == true {
            return .simplifiedChinese
        }
        return .english
    }
}
