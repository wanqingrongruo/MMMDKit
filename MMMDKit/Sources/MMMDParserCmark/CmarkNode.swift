import Foundation

import MMMDCore

enum CmarkNodeType: Equatable {
    case document
    case paragraph
    case heading(level: Int)
    case blockquote
    case list(style: CmarkListStyle)
    case table
    case tableRow(isHeader: Bool)
    case tableCell
    case mathBlock(latex: String)
    case listItem
    case text(String)
    case inlineMath(String)
    case emphasis
    case strong
    case link(destination: URL?)
    case image(alt: String, url: URL?)
    case codeBlock(language: String?, content: String)
    case thematicBreak
}

enum CmarkListStyle: Equatable {
    case ordered(start: Int)
    case unordered
}

struct CmarkNode: Equatable {
    var type: CmarkNodeType
    var children: [CmarkNode]
    var sourceRange: SourceRange?

    init(type: CmarkNodeType, children: [CmarkNode] = [], sourceRange: SourceRange? = nil) {
        self.type = type
        self.children = children
        self.sourceRange = sourceRange
    }
}
