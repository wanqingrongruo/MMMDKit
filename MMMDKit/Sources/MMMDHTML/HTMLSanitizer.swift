import Foundation

/// 基础 HTML 清洗器。
///
/// 该实现用于移除明显不安全的脚本、事件属性和 `javascript:` 链接。
/// 它不是完整的安全沙箱；如果展示不可信 HTML，业务侧仍应结合服务端清洗或更严格策略。
public struct HTMLSanitizer {
    public init() {}

    /// 返回清洗后的 HTML 字符串。
    public func sanitize(_ html: String) -> String {
        var output = html
        output = output.replacingOccurrences(
            of: #"<script[\s\S]*?</script>"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        output = output.replacingOccurrences(
            of: #"\son[a-zA-Z]+\s*=\s*(['"]).*?\1"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        output = output.replacingOccurrences(
            of: #"javascript:"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        return output
    }
}
