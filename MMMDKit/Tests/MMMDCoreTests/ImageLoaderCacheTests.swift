import Foundation
import XCTest
import MMMDCore

final class ImageLoaderCacheTests: XCTestCase {
    func testCachingImageLoaderReusesDataForSameURL() async throws {
        let base = CountingImageLoader()
        let loader = CachingImageLoader(base: base)
        let url = try XCTUnwrap(URL(string: "https://example.com/a.png"))

        let first = try await loader.loadImageData(from: url)
        let second = try await loader.loadImageData(from: url)

        XCTAssertEqual(first, second)
        let invocationCount = await base.invocationCount
        XCTAssertEqual(invocationCount, 1)
    }

    func testCachingImageLoaderSeparatesURLs() async throws {
        let base = CountingImageLoader()
        let loader = CachingImageLoader(base: base)
        let firstURL = try XCTUnwrap(URL(string: "https://example.com/a.png"))
        let secondURL = try XCTUnwrap(URL(string: "https://example.com/b.png"))

        _ = try await loader.loadImageData(from: firstURL)
        _ = try await loader.loadImageData(from: secondURL)

        let invocationCount = await base.invocationCount
        XCTAssertEqual(invocationCount, 2)
    }

    func testImageDataCacheEvictsLeastRecentlyUsedEntry() async throws {
        let cache = ImageDataCache(configuration: .init(maximumEntryCount: 2, evictionStrategy: .leastRecentlyUsed))
        let firstURL = try XCTUnwrap(URL(string: "https://example.com/a.png"))
        let secondURL = try XCTUnwrap(URL(string: "https://example.com/b.png"))
        let thirdURL = try XCTUnwrap(URL(string: "https://example.com/c.png"))

        await cache.insert(Data("a".utf8), for: firstURL)
        await cache.insert(Data("b".utf8), for: secondURL)
        _ = await cache.data(for: firstURL)
        await cache.insert(Data("c".utf8), for: thirdURL)

        let first = await cache.data(for: firstURL)
        let second = await cache.data(for: secondURL)
        let third = await cache.data(for: thirdURL)
        XCTAssertNotNil(first)
        XCTAssertNil(second)
        XCTAssertNotNil(third)
    }

    func testImageDataCacheEvictsByByteLimit() async throws {
        let cache = ImageDataCache(configuration: .init(maximumEntryCount: 10, maximumByteCount: 4))
        let firstURL = try XCTUnwrap(URL(string: "https://example.com/a.png"))
        let secondURL = try XCTUnwrap(URL(string: "https://example.com/b.png"))

        await cache.insert(Data("aaa".utf8), for: firstURL)
        await cache.insert(Data("bbb".utf8), for: secondURL)

        let first = await cache.data(for: firstURL)
        let second = await cache.data(for: secondURL)
        XCTAssertNil(first)
        XCTAssertNotNil(second)
    }
}

private actor CountingImageLoader: ImageLoader {
    private var count = 0

    var invocationCount: Int {
        count
    }

    func loadImageData(from url: URL) async throws -> Data {
        count += 1
        return Data(url.absoluteString.utf8)
    }
}
