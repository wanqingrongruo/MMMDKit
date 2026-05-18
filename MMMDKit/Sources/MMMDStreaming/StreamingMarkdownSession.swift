import Foundation
import MMMDCore

public final class StreamingMarkdownSession {
    private let processor: StreamingMarkdownProcessor
    private let processingQueue: DispatchQueue
    private let deliveryQueue: DispatchQueue
    private let updateInterval: TimeInterval
    private var pendingDiff: MarkdownRenderDiff?
    private var isUpdateScheduled = false
    private var generation = 0

    public var onUpdate: ((MarkdownRenderDiff) -> Void)?

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

    public func append(_ delta: String) {
        guard !delta.isEmpty else { return }
        processingQueue.async { [weak self] in
            self?.processor.append(delta)
        }
    }

    public func finish() {
        processingQueue.async { [weak self] in
            self?.processor.finish()
        }
    }

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
