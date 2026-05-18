import Foundation
import MMMDCore

#if canImport(AppKit)
import AppKit

/// AppKit 渲染层的 Markdown 尺寸测量结果。
///
/// 该结构只描述 Markdown 内容本身的排版尺寸，不包含业务容器的标题、头像、气泡内边距等额外 UI。
public struct MarkdownLayoutResult {
    /// 本次测量结果的唯一标识，便于列表或 item 判断布局是否发生变化。
    public let id: UUID
    /// Markdown 内容在给定宽度约束下需要的尺寸。
    public let size: CGSize

    public init(id: UUID = UUID(), size: CGSize) {
        self.id = id
        self.size = size
    }
}

/// Markdown 文档的 AppKit 尺寸测量入口。
///
/// 该类型适合在 macOS 列表或自定义容器中提前测量 Markdown 内容高度。测量会复用
/// `MarkdownNSView.estimatedHeight` 的内部 sizing view，因此应在主线程调用。
public enum MarkdownLayoutEngine {
    /// 测量一份 Markdown 文档在指定宽度下的内容尺寸。
    /// - Parameters:
    ///   - document: 要测量的 Markdown 文档。
    ///   - width: Markdown 内容区域的最大可用宽度。
    ///   - configuration: 渲染配置。
    /// - Returns: Markdown 内容尺寸。
    public static func measure(
        document: MarkdownDocument,
        fittingWidth width: CGFloat,
        configuration: MarkdownConfiguration
    ) -> MarkdownLayoutResult {
        let contentWidth = max(1, width)
        let height = MarkdownNSView.estimatedHeight(
            for: document,
            width: contentWidth,
            configuration: configuration
        )
        return MarkdownLayoutResult(size: CGSize(width: contentWidth, height: height))
    }
}
#endif
