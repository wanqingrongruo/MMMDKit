import Foundation
import MMMDCore

/// 数学公式的纯文本 fallback 渲染器。
///
/// 当业务侧未接入真实公式渲染能力时，可使用该实现把 LaTeX 原文作为可访问文本返回。
public struct FallbackMathRenderer: MathRenderer {
    public init() {}

    /// 返回 LaTeX 原文的纯文本表示。
    public func render(latex: String, displayMode: Bool, environment: MathEnvironment) async throws -> MathRenderResult {
        MathRenderResult(representation: .plainText(latex), accessibilityLabel: latex)
    }
}
