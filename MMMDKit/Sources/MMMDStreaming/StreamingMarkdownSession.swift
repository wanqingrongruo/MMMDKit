import Foundation
import MMMDCore

/// 面向业务侧直接使用的流式 Markdown 会话。
///
/// `StreamingMarkdownSession` 在 `StreamingMarkdownProcessor` 之上增加了串行处理队列、
/// UI 友好的更新节流和指定队列回调。外部只需要不断调用 `append(_:)` 追加新文本，
/// 并在结束时调用 `finish()` 即可。
public final class StreamingMarkdownSession {
    private let processor: StreamingMarkdownProcessor
    private let processingQueue: DispatchQueue
    private let deliveryQueue: DispatchQueue
    private let updateInterval: TimeInterval
    private var pendingDiff: MarkdownRenderDiff?
    private var isUpdateScheduled = false
    private var generation = 0

    /// 节流后的文档更新回调。
    ///
    /// 默认会投递到主队列，适合直接驱动 UIKit/AppKit 视图刷新。
    public var onUpdate: ((MarkdownRenderDiff) -> Void)?

    /// 创建一个流式 Markdown 会话。
    /// - Parameters:
    ///   - parser: 用于把累计文本解析为 `MarkdownDocument` 的解析器。
    ///   - parseOptions: 每次解析时使用的选项。
    ///   - updateInterval: `.streaming` 阶段的最小回调间隔；传 `0` 表示不节流。
    ///   - deliveryQueue: `onUpdate` 的回调队列，默认主队列。
    public init(
        parser: MarkdownParser,
        parseOptions: ParseOptions = .init(),
        updateInterval: TimeInterval = 0.08,
        deliveryQueue: DispatchQueue = .main
    ) {
        self.processor = StreamingMarkdownProcessor(parser: parser, parseOptions: parseOptions)
        self.processingQueue = DispatchQueue(label: "com.mmmdkit.streaming.session")
        self.deliveryQueue = deliveryQueue
        self.updateInterval = updateInterval
        self.processor.onDiff = { [weak self] diff in
            self?.enqueue(diff)
        }
    }

    /// 追加上游新返回的一段文本。
    ///
    /// 该方法可从任意线程调用；内部会按调用顺序在串行队列中处理。
    public func append(_ delta: String) {
        guard !delta.isEmpty else { return }
        processingQueue.async { [weak self] in
            self?.processor.append(delta)
        }
    }

    /// 标记当前流式内容已经结束，并触发最终文档更新。
    public func finish() {
        processingQueue.async { [weak self] in
            self?.processor.finish()
        }
    }

    /// 清空当前会话状态，取消尚未投递的节流更新。
    public func reset() {
        processingQueue.async { [weak self] in
            guard let self else { return }
            self.generation += 1
            self.pendingDiff = nil
            self.isUpdateScheduled = false
            self.processor.reset()
        }
    }

    private func enqueue(_ diff: MarkdownRenderDiff) {
        pendingDiff = diff

        if diff.phase == .finished || updateInterval <= 0 {
            generation += 1
            isUpdateScheduled = false
            deliverPendingDiff()
            return
        }

        guard !isUpdateScheduled else { return }
        isUpdateScheduled = true
        let scheduledGeneration = generation
        processingQueue.asyncAfter(deadline: .now() + updateInterval) { [weak self] in
            guard let self, self.generation == scheduledGeneration else { return }
            self.isUpdateScheduled = false
            self.deliverPendingDiff()
        }
    }

    private func deliverPendingDiff() {
        guard let diff = pendingDiff else { return }
        pendingDiff = nil
        deliveryQueue.async { [weak self] in
            self?.onUpdate?(diff)
        }
    }
}
