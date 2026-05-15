import Foundation

public struct LayoutCacheKey: Hashable, Sendable {
    public var blockIndex: Int
    public var contentWidth: Double
    public var dynamicTypeSize: String
    public var themeName: String
    public var colorScheme: String

    public init(blockIndex: Int, environment: RenderEnvironment, theme: MarkdownTheme) {
        self.blockIndex = blockIndex
        self.contentWidth = environment.contentWidth
        self.dynamicTypeSize = environment.dynamicTypeSize
        self.themeName = theme.codeTheme.name
        self.colorScheme = environment.colorScheme
    }
}

public struct LayoutCacheValue: Equatable, Sendable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public final class LayoutCache {
    private var values: [LayoutCacheKey: LayoutCacheValue] = [:]

    public init() {}

    public func value(for key: LayoutCacheKey) -> LayoutCacheValue? {
        values[key]
    }

    public func store(_ value: LayoutCacheValue, for key: LayoutCacheKey) {
        values[key] = value
    }

    public func invalidateAll() {
        values.removeAll()
    }

    public func invalidate(where shouldRemove: (LayoutCacheKey) -> Bool) {
        values = values.filter { !shouldRemove($0.key) }
    }
}
