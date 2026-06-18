import Foundation
import MMMDCore

public struct CodeHighlightCacheKey: Hashable, Sendable {
    public var code: String
    public var language: String?
    public var themeSignature: String

    public init(code: String, language: String?, theme: CodeTheme) {
        self.code = code
        self.language = language?.lowercased()
        self.themeSignature = theme.cacheSignature
    }
}

public actor CodeHighlightCache {
    private var entries: [CodeHighlightCacheKey: HighlightResult] = [:]
    private var insertionOrder: [CodeHighlightCacheKey] = []
    private let maximumEntryCount: Int

    public init(maximumEntryCount: Int = 256) {
        self.maximumEntryCount = max(1, maximumEntryCount)
    }

    public func value(for key: CodeHighlightCacheKey) -> HighlightResult? {
        entries[key]
    }

    public func insert(_ result: HighlightResult, for key: CodeHighlightCacheKey) {
        if entries[key] == nil {
            insertionOrder.append(key)
        }
        entries[key] = result
        trimIfNeeded()
    }

    public func removeAll() {
        entries.removeAll()
        insertionOrder.removeAll()
    }

    private func trimIfNeeded() {
        while entries.count > maximumEntryCount, let oldest = insertionOrder.first {
            insertionOrder.removeFirst()
            entries.removeValue(forKey: oldest)
        }
    }
}

public struct CachingCodeHighlighter: CodeHighlighter {
    private let base: any CodeHighlighter
    private let cache: CodeHighlightCache

    public init(base: any CodeHighlighter, cache: CodeHighlightCache = CodeHighlightCache()) {
        self.base = base
        self.cache = cache
    }

    public func highlight(code: String, language: String?, theme: CodeTheme) async throws -> HighlightResult {
        let key = CodeHighlightCacheKey(code: code, language: language, theme: theme)
        if let cached = await cache.value(for: key) {
            return cached
        }

        let result = try await base.highlight(code: code, language: language, theme: theme)
        await cache.insert(result, for: key)
        return result
    }
}

private extension CodeTheme {
    var cacheSignature: String {
        let styles = tokenStyles
            .sorted { $0.key < $1.key }
            .map { key, style in
                "\(key):\(style.foregroundColor):\(style.fontTraits.sorted().joined(separator: ","))"
            }
            .joined(separator: "|")

        return "\(name)|\(foregroundColor)|\(backgroundColor)|\(styles)"
    }
}
