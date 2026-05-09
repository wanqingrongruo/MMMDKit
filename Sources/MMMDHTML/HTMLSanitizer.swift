import Foundation

public struct HTMLSanitizer {
    public init() {}

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
