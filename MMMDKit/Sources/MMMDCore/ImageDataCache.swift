import Foundation

public enum ImageCacheEvictionStrategy: String, Equatable, Sendable {
    case firstInFirstOut
    case leastRecentlyUsed
}

public struct ImageDataCacheConfiguration: Equatable, Sendable {
    public var maximumEntryCount: Int
    public var maximumByteCount: Int?
    public var evictionStrategy: ImageCacheEvictionStrategy

    public init(
        maximumEntryCount: Int = 128,
        maximumByteCount: Int? = nil,
        evictionStrategy: ImageCacheEvictionStrategy = .leastRecentlyUsed
    ) {
        self.maximumEntryCount = max(1, maximumEntryCount)
        self.maximumByteCount = maximumByteCount.map { max(1, $0) }
        self.evictionStrategy = evictionStrategy
    }
}

public actor ImageDataCache {
    private var entries: [URL: Data] = [:]
    private var accessOrder: [URL] = []
    private var totalByteCount = 0
    private let configuration: ImageDataCacheConfiguration

    public init(maximumEntryCount: Int = 128) {
        self.configuration = .init(maximumEntryCount: maximumEntryCount)
    }

    public init(configuration: ImageDataCacheConfiguration) {
        self.configuration = configuration
    }

    public func data(for url: URL) -> Data? {
        guard let data = entries[url] else { return nil }
        if configuration.evictionStrategy == .leastRecentlyUsed {
            markRecentlyUsed(url)
        }
        return data
    }

    public func insert(_ data: Data, for url: URL) {
        if let oldData = entries[url] {
            totalByteCount -= oldData.count
        } else {
            accessOrder.append(url)
        }

        entries[url] = data
        totalByteCount += data.count
        if configuration.evictionStrategy == .leastRecentlyUsed {
            markRecentlyUsed(url)
        }
        trimIfNeeded()
    }

    public func removeAll() {
        entries.removeAll()
        accessOrder.removeAll()
        totalByteCount = 0
    }

    private func trimIfNeeded() {
        while shouldEvict, let url = accessOrder.first {
            accessOrder.removeFirst()
            if let data = entries.removeValue(forKey: url) {
                totalByteCount -= data.count
            }
        }
    }

    private var shouldEvict: Bool {
        if entries.count > configuration.maximumEntryCount {
            return true
        }
        if let maximumByteCount = configuration.maximumByteCount,
           totalByteCount > maximumByteCount {
            return true
        }
        return false
    }

    private func markRecentlyUsed(_ url: URL) {
        accessOrder.removeAll { $0 == url }
        accessOrder.append(url)
    }
}

public struct CachingImageLoader: ImageLoader {
    private let base: any ImageLoader
    private let cache: ImageDataCache

    public init(base: any ImageLoader, cache: ImageDataCache = ImageDataCache()) {
        self.base = base
        self.cache = cache
    }

    public init(base: any ImageLoader, cacheConfiguration: ImageDataCacheConfiguration) {
        self.base = base
        self.cache = ImageDataCache(configuration: cacheConfiguration)
    }

    public func loadImageData(from url: URL) async throws -> Data {
        if let cached = await cache.data(for: url) {
            return cached
        }

        let data = try await base.loadImageData(from: url)
        await cache.insert(data, for: url)
        return data
    }
}
