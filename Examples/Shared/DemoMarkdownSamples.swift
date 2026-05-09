import Foundation
import MMMDCore
import MMMDParserCmark

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
        "### 消息 01\n今天的习惯任务：**刷牙**、**整理书包**、睡前阅读 10 分钟。",
        "### 消息 02\n- 起床后喝水\n- 自己穿袜子\n- 出门前检查水杯",
        "### 消息 03\n> 孩子不配合时，先描述事实，再给两个可选项。",
        "### 消息 04\n英语启蒙句子：`Can you put the toy in the box?`",
        "### 消息 05\n| 项目 | 完成 |\n| --- | --- |\n| 刷牙 | 是 |\n| 阅读 | 是 |",
        "### 消息 06\n数学小游戏：$1 + 2 = 3$，可以用积木演示。",
        "### 消息 07\n```swift\nlet habit = \"reading\"\nprint(habit)\n```",
        "### 消息 08\n今天适合做 15 分钟户外观察：树叶、云、影子。",
        "### 消息 09\n**鼓励话术**：你刚才自己试了一次，这就是进步。",
        "### 消息 10\n亲子英语：*Brush your teeth, please.*",
        "### 消息 11\n- 收玩具\n- 洗手\n- 换睡衣\n- 讲故事",
        "### 消息 12\n> 当孩子说“我不会”，可以回复“我们先试第一步”。",
        "### 消息 13\n兴趣观察：画画时是否愿意补充细节？",
        "### 消息 14\n| 英文 | 中文 |\n| --- | --- |\n| apple | 苹果 |\n| banana | 香蕉 |",
        "### 消息 15\n公式块：\n$$\nE = mc^2\n$$",
        "### 消息 16\n睡前复盘：今天最开心的一件事是什么？",
        "### 消息 17\n链接测试：[MMMDKit](https://github.com/wanqingrongruo/MMMDKit)",
        "### 消息 18\n代码块复制测试：\n```swift\nstruct Reward { let stars: Int }\n```",
        "### 消息 19\n任务拆分：先穿上衣，再穿裤子，最后穿袜子。",
        "### 消息 20\n情绪识别：开心、生气、害怕、委屈。",
        "### 消息 21\n- 红色\n- 蓝色\n- 黄色\n- 绿色",
        "### 消息 22\n> 分享不是强迫，轮流和等待也同样重要。",
        "### 消息 23\n今天可以玩“找不同”，训练观察力。",
        "### 消息 24\n英语问答：`What color is it?` / `It is red.`",
        "### 消息 25\n| 场景 | 英语 |\n| --- | --- |\n| 洗手 | Wash your hands |\n| 睡觉 | Time for bed |",
        "### 消息 26\ninline math：$x^2 + y^2 = z^2$。",
        "### 消息 27\n**规则表达**：玩具用完回家。",
        "### 消息 28\n运动建议：跳格子、单脚站、拍球。",
        "### 消息 29\n绘本提问：你觉得小熊为什么难过？",
        "### 消息 30\n```swift\nlet score = 100\nlet completed = score >= 100\n```",
        "### 消息 31\n习惯奖励：连续 3 天完成后解锁一次亲子游戏。",
        "### 消息 32\n> 先连接情绪，再处理行为。",
        "### 消息 33\n表格长内容测试：\n| 能力 | 说明 |\n| --- | --- |\n| 专注 | 5 分钟拼图 |\n| 表达 | 说出今天的感受 |",
        "### 消息 34\n睡前英文：*Good night. Sweet dreams.*",
        "### 消息 35\n兴趣探索：音乐、搭建、运动、科学小实验。",
        "### 消息 36\n总结：稳定的小步骤，比一次性大目标更容易坚持。"
    ]

    static let streamingMarkdown = """
    # 流式输出演示

    我会像 AI 回复一样逐步输出内容。

    先给出一个列表：

    - 记录孩子每天的习惯完成情况
    - 根据完成情况生成鼓励话术
    - 用可视化奖励帮助孩子坚持

    然后输出一段代码：

    ```swift
    struct HabitProgress {
        let title: String
        let completedDays: Int
    }
    ```

    最后给出一个表格：

    | 模块 | 价值 |
    | --- | --- |
    | 习惯 | 降低家长催促 |
    | 英语 | 每天轻量陪伴 |
    | 兴趣 | 先观察再报班 |
    """

    static func makeLongFeedDocument() -> MarkdownDocument {
        let parser = CmarkMarkdownParser()
        let source = messageSamples.joined(separator: "\n\n")
        return (try? parser.parse(source, options: .init())) ?? MarkdownDocument(blocks: [])
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
