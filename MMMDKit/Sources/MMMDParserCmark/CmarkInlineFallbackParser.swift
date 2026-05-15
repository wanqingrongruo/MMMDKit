import Foundation

enum CmarkInlineFallbackParser {
    static func parse(_ text: String) -> [CmarkNode] {
        parse(text[...])
    }

    private static func parse(_ text: Substring) -> [CmarkNode] {
        var nodes: [CmarkNode] = []
        var remaining = text

        while !remaining.isEmpty {
            if remaining.hasPrefix("!["),
               let titleEnd = remaining.firstIndex(of: "]"),
               titleEnd < remaining.index(before: remaining.endIndex),
               remaining[remaining.index(after: titleEnd)] == "(",
               let urlEnd = remaining[remaining.index(titleEnd, offsetBy: 2)...].firstIndex(of: ")") {
                let alt = remaining[remaining.index(remaining.startIndex, offsetBy: 2)..<titleEnd]
                let urlStart = remaining.index(titleEnd, offsetBy: 2)
                let urlText = String(remaining[urlStart..<urlEnd])
                nodes.append(.init(type: .image(alt: String(alt), url: URL(string: urlText))))
                remaining = remaining[remaining.index(after: urlEnd)...]
                continue
            }

            if remaining.hasPrefix("["),
               let titleEnd = remaining.firstIndex(of: "]"),
               titleEnd < remaining.index(before: remaining.endIndex),
               remaining[remaining.index(after: titleEnd)] == "(",
               let urlEnd = remaining[remaining.index(titleEnd, offsetBy: 2)...].firstIndex(of: ")") {
                let title = remaining[remaining.index(after: remaining.startIndex)..<titleEnd]
                let urlStart = remaining.index(titleEnd, offsetBy: 2)
                let urlText = String(remaining[urlStart..<urlEnd])
                nodes.append(.init(
                    type: .link(destination: URL(string: urlText)),
                    children: parse(title)
                ))
                remaining = remaining[remaining.index(after: urlEnd)...]
                continue
            }

            if remaining.hasPrefix("$"), !remaining.hasPrefix("$$"), let end = remaining.dropFirst().firstIndex(of: "$") {
                let latex = remaining[remaining.index(after: remaining.startIndex)..<end]
                nodes.append(.init(type: .inlineMath(String(latex))))
                remaining = remaining[remaining.index(after: end)...]
                continue
            }

            if remaining.hasPrefix("**"), let end = remaining.dropFirst(2).range(of: "**") {
                let content = remaining[remaining.index(remaining.startIndex, offsetBy: 2)..<end.lowerBound]
                nodes.append(.init(type: .strong, children: parse(content)))
                remaining = remaining[end.upperBound...]
                continue
            }

            if remaining.hasPrefix("*"), let end = remaining.dropFirst().firstIndex(of: "*") {
                let content = remaining[remaining.index(after: remaining.startIndex)..<end]
                nodes.append(.init(type: .emphasis, children: parse(content)))
                remaining = remaining[remaining.index(after: end)...]
                continue
            }

            let nextStrong = remaining.range(of: "**")?.lowerBound
            let nextEmphasis = remaining.dropFirst().firstIndex(of: "*")
            let nextImage = remaining.range(of: "![")?.lowerBound
            let nextLink = remaining.firstIndex(of: "[")
            let nextMath = remaining.firstIndex(of: "$")
            let nextMarker = [nextStrong, nextEmphasis, nextImage, nextLink, nextMath].compactMap { $0 }.min()
            let end = nextMarker ?? remaining.endIndex
            nodes.append(.init(type: .text(String(remaining[..<end]))))
            remaining = remaining[end...]
        }

        return nodes
    }
}
