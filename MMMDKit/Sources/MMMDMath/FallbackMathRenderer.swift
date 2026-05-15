import Foundation
import MMMDCore

public struct FallbackMathRenderer: MathRenderer {
    public init() {}

    public func render(latex: String, displayMode: Bool, environment: MathEnvironment) async throws -> MathRenderResult {
        MathRenderResult(representation: .plainText(latex), accessibilityLabel: latex)
    }
}
