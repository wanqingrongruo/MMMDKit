import Foundation
import MMMDCore
import MMMDParserCmark

struct DemoChatMessage {
    enum Role: Equatable {
        case user
        case assistant
    }

    let id: String
    let role: Role
    let title: String
    let markdown: String
    let document: MarkdownDocument
}

enum DemoMarkdownSamples {
    static let richMarkdown = """
    # MMMDKit 复杂 Markdown 示例

    这份测试数据覆盖段落、**粗体**、*斜体*、链接、列表、引用、代码块、表格和数学公式。

    访问 [GitHub](https://github.com/wanqingrongruo/MMMDKit) 查看项目。

    ## 任务列表

    - 支持 UIKit 原生渲染
    - 支持 AppKit 原生渲染
    - 支持 CocoaPods 模块化接入

    ## 有序列表

    1. 解析 Markdown
    2. 转换 Block Model
    3. 原生渲染

    > 这是一段引用块。
    > 它会被渲染成带左侧指示线的原生视图。

    ---

    ## 表格

    | 能力 | 状态 |
    | --- | --- |
    | Markdown Parser | 已接入 |
    | 代码高亮 | 已接入 |
    | 表格 | 已接入 |
    | LaTeX | 已接入 |

    ## 数学公式

    inline math 示例：$x^2 + y^2 = z^2$

    $$
    E = mc^2
    $$

    $$
    x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}
    $$

    $$
    \\int_{0}^{\\infty} e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}
    $$

    ---

    ## Swift 代码

    ```swift
    struct ChildHabit {
        let title: String
        let score: Int

        func isCompleted() -> Bool {
            score >= 100
        }
    }
    ```
    """

    static func makeDocument() -> MarkdownDocument {
        let parser = CmarkMarkdownParser()
        var document = (try? parser.parse(richMarkdown, options: .init())) ?? MarkdownDocument(blocks: [])
        document.blocks.append(.html(.init(html: """
        <section style="font-family:-apple-system; padding:12px; border-radius:12px; background:#f5f5f5;">
          <strong>HTML fallback</strong>
          <p>这段内容通过 WebView fallback 渲染，并经过 sanitizer 处理。</p>
        </section>
        """)))
        document.blockSourceRanges.append(nil)
        return document
    }

    static let messageSamples: [String] = [
        """
        ### 01
        MMMDKit 是一个面向 Apple 平台的 **模块化原生 Markdown 渲染框架**。它的核心优势包括：
        
        - 🧩 **Parser 可替换**：内置 Cmark 桥接，支持无缝切换。
        - 🚀 **原生性能**：iOS 使用 UIKit，macOS 使用 AppKit，无 WebView。
        - 🌊 **AI 流式输出友好**：支持 Token 级别的高频刷新，动画丝滑。
        
        [访问 GitHub 仓库](https://github.com/wanqingrongruo/MMMDKit) 了解更多细节。
        """,
        """
        ### 02
        这太棒了！那么支持哪些具体的 Markdown 格式呢？包含数学公式和代码块吗？
        """,
        """
        ### 03
        当然支持！你可以使用各种内联格式来突出重点。比如这段文字包含了*斜体*、**粗体**、以及***粗斜体***。如果你需要提及代码，可以使用行内代码 `print("Hello")`。
        
        对于代码块，我们提供了基于关键字的高亮，支持扩展：
        
        ---

        ```swift
        public struct MarkdownConfiguration {
            public var theme: MarkdownTheme = .default
            public var codeHighlighter: CodeHighlighter?
            
            public init() {}
        }
        ```
        
        对于公式，我们支持 inline math $E=mc^2$ 甚至多行的 display math：
        
        $$
        f(x) = \\int_{-\\infty}^\\infty \\hat f(\\xi)\\,e^{2 \\pi i \\xi x} \\,d\\xi
        $$

        $$
        A = \\begin{pmatrix} 1 & 2 \\\\ 3 & 4 \\end{pmatrix}
        $$

        $$
        y = \\begin{cases} x^2, & x \\ge 0 \\\\ -x, & x < 0 \\end{cases}
        $$

        ---

        分割线也可以作为连续文本和非文本块之间的视觉分隔。
        """,
        """
        ### 04
        表格呢？我需要在消息中对比多项数据。
        """,
        """
        ### 05
        完全没问题。对于结构化数据的展示，表格是不可或缺的：
        
        | 框架特性 | MMMDKit | 其他 Web 方案 | 其他 TextKit 方案 |
        | --- | --- | --- | --- |
        | 渲染引擎 | 原生组件 | WebView | TextKit |
        | 内存占用 | 低 | 高 | 中 |
        | 流式更新 | ✅ 优秀 | ❌ 差 | ⚠️ 一般 |
        
        ---

        不仅如此，长表格我们支持了**原生的水平滚动**，告别页面被撑爆的烦恼。
        """,
        """
        ### 06
        这看起来能满足我开发 AI 助手 App 的全部需求，太感谢了！
        """,
        """
        ### 07
        不客气！在真实对话中，你还可以自由组合这些元素。
        
        > 💡 小贴士：
        > 
        > 所有的 Block 都可以通过 `MarkdownConfiguration` 灵活配置或替换！
        
        祝您开发顺利！如果遇到问题，请查阅以下兼容表：
        
        | 平台 | 最低版本 | 状态 |
        | --- | --- | --- |
        | iOS | 15.0 | ✅ Active |
        | macOS | 12.0 | ✅ Active |
        """
    ]

    static let chatMessages: [DemoChatMessage] = makeChatMessages()

    static let streamingMarkdown = """
    好的！为您生成一份 **5岁孩子习惯养成方案**。该方案结合了游戏化思维和正面管教原则，帮助孩子在快乐中建立良好的生活规律。

    ### 一、 核心习惯列表

    我们先从日常最基础的习惯开始，不要贪多，每次专注 2-3 个核心习惯：

    1. **晨间流程**
       - ☀️ 独立起床并穿好衣服
       - 🪥 自己刷牙洗脸
       - 🥛 喝一杯温水
    2. **晚间流程**
       - 🧸 睡前自己收拾玩具回原位
       - 📚 亲子共读 15 分钟
       - 🛌 准时熄灯睡觉

    > 💡 **家长小贴士：** 
    > 5岁孩子的专注力和执行力还在发育中，尽量把指令拆解成具体的动作。例如不说“快点睡觉”，而是说“现在我们去挑一本睡前故事书”。

    ---

    ### 二、 积分奖励机制

    为了增加趣味性，我们可以引入“星星积分”。你可以将这段结构映射成家庭积分表：

    | 任务项 | 完成奖励 | 备注 |
    | :--- | :---: | :--- |
    | 独立穿衣 | ⭐️ x 1 | 需在 10 分钟内完成 |
    | 按时刷牙 | ⭐️ x 1 | 早晚各一次 |
    | 收拾玩具 | ⭐️ x 2 | 保持区域整洁 |
    | 情绪稳定 | ⭐️ x 2 | 遇到困难不乱发脾气 |

    ---

    你可以使用以下简单代码逻辑来计算孩子本周的奖励情况：

    ```swift
    struct ChildHabitTracker {
        let name: String
        var totalStars: Int = 0
        
        mutating func completeTask(stars: Int) {
            totalStars += stars
            print("太棒了！\\(name) 获得了 \\(stars) 颗星星！")
        }
        
        func checkReward() -> String {
            if totalStars >= 20 {
                return "解锁周末动物园之旅！🐘"
            } else if totalStars >= 10 {
                return "获得一次挑选睡前故事的权利！📖"
            } else {
                return "继续加油哦！💪"
            }
        }
    }

    var tracker = ChildHabitTracker(name: "宝贝")
    tracker.completeTask(stars: 2)
    ```

    ---

    ### 三、 总结公式

    最后，我们可以用一个“数学公式”来总结习惯养成的秘诀：
    
    $$
    \\text{好习惯} = \\text{清晰指令} + \\text{及时鼓励} + \\text{坚持重复}
    $$

    $$
    \\frac{\\text{每日坚持}}{\\text{任务难度}} + \\sqrt{\\text{及时反馈}} = \\text{稳定成长}
    $$
    
    ---

    希望这份方案能帮到您！如果有其他需要调整的环节，随时告诉我。
    """

    static func makeLongFeedDocument() -> MarkdownDocument {
        let parser = CmarkMarkdownParser()
        let source = messageSamples.joined(separator: "\n\n")
        return (try? parser.parse(source, options: .init())) ?? MarkdownDocument(blocks: [])
    }

    static func makeChatMessages() -> [DemoChatMessage] {
        let parser = CmarkMarkdownParser()
        return messageSamples.enumerated().map { index, markdown in
            let number = index + 1
            let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)
            let body = lines.dropFirst().joined(separator: "\n")
            // 偶数消息是 User，奇数消息是 Assistant
            let role: DemoChatMessage.Role = number.isMultiple(of: 2) ? .user : .assistant
            let document = (try? parser.parse(body, options: .init())) ?? MarkdownDocument(blocks: [])
            return DemoChatMessage(
                id: "message-\(number)",
                role: role,
                title: role == .user ? "家长" : "AI 助手",
                markdown: body,
                document: document
            )
        }
    }

    static func makeStreamingSeedMessages() -> [DemoChatMessage] {
        [makeStreamingUserMessage(index: 1)]
    }

    static func makeStreamingUserMessage(index: Int) -> DemoChatMessage {
        let parser = CmarkMarkdownParser()
        let prompts = [
            "帮我生成一个适合 5 岁孩子的习惯养成方案，包含列表、代码和一个小表格。",
            "再给我一个睡前流程建议，要求语气温柔，并包含一个检查清单。",
            "换一个英语启蒙陪伴方案，适合每天 10 分钟执行。",
            "生成一个亲子户外观察小游戏，包含步骤和奖励建议。"
        ]
        let userMarkdown = prompts[(index - 1) % prompts.count]
        let document = (try? parser.parse(userMarkdown, options: .init())) ?? MarkdownDocument(blocks: [])
        return DemoChatMessage(
            id: "streaming-user-\(index)",
            role: .user,
            title: "家长 \(String(format: "%02d", index))",
            markdown: userMarkdown,
            document: document
        )
    }

    static func makeStreamingAssistantPlaceholder(index: Int) -> DemoChatMessage {
        DemoChatMessage(
            id: "streaming-assistant-\(index)",
            role: .assistant,
            title: "AI 助手 \(String(format: "%02d", index))",
            markdown: "",
            document: MarkdownDocument(blocks: [.paragraph(.init(text: "正在输入..."))])
        )
    }

    static func streamingChunks() -> [String] {
        var chunks: [String] = []
        var current = ""
        for character in streamingMarkdown {
            current.append(character)
            if current.count >= 8 || character == "\n" {
                chunks.append(current)
                current.removeAll()
            }
        }
        if !current.isEmpty {
            chunks.append(current)
        }
        return chunks
    }
}
