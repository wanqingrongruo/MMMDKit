@_exported import MMMDCore
#if canImport(MMMDParserSwiftMarkdown)
@_exported import MMMDParserSwiftMarkdown
#elseif canImport(MMMDParserCmark)
@_exported import MMMDParserCmark
#endif
@_exported import MMMDStreaming
@_exported import MMMDHighlighter
@_exported import MMMDMath
@_exported import MMMDHTML
@_exported import MMMDSwiftUI

/// MMMDKit umbrella product 的版本信息。
public enum MMMDKitVersion {
    /// 当前库版本号。
    public static let current = "0.2.0-alpha"
}
