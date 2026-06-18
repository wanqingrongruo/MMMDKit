import Foundation
import MMMDCore
#if canImport(MMMDParserSwiftMarkdown)
import MMMDParserSwiftMarkdown
#elseif canImport(MMMDParserCmark)
import MMMDParserCmark
#endif
import MMMDStreaming
import SwiftUI

public enum StreamingMarkdownInputMode: Sendable {
    case delta
    case snapshot
}

/// SwiftUI renderer for a `StreamingMarkdownSession`.
public struct StreamingMarkdownText: View {
    @StateObject private var controller: StreamingMarkdownController
    private let configuration: MarkdownConfiguration

    public init(
        session: StreamingMarkdownSession,
        configuration: MarkdownConfiguration = .init(),
        onUpdate: ((MarkdownRenderDiff) -> Void)? = nil
    ) {
        _controller = StateObject(wrappedValue: StreamingMarkdownController(session: session, onUpdate: onUpdate))
        self.configuration = configuration
    }

    public init(
        source: AsyncStream<String>,
        inputMode: StreamingMarkdownInputMode = .delta,
        configuration: MarkdownConfiguration = .init(),
        parser: (any MarkdownParser)? = nil,
        updateInterval: TimeInterval = 0.08,
        onUpdate: ((MarkdownRenderDiff) -> Void)? = nil
    ) {
        _controller = StateObject(wrappedValue: StreamingMarkdownController(
            source: source,
            inputMode: inputMode,
            parser: parser ?? Self.defaultParser(),
            updateInterval: updateInterval,
            onUpdate: onUpdate
        ))
        self.configuration = configuration
    }

    public var body: some View {
        MarkdownDocumentView(document: controller.document, configuration: configuration)
            .onAppear {
                controller.start()
            }
            .onDisappear {
                controller.stop()
            }
    }

    private static func defaultParser() -> any MarkdownParser {
        #if canImport(MMMDParserSwiftMarkdown)
        return SwiftMarkdownParser()
        #elseif canImport(MMMDParserCmark)
        return CmarkMarkdownParser()
        #else
        fatalError("MMMDKit requires a parser module.")
        #endif
    }
}

@MainActor
final class StreamingMarkdownController: ObservableObject {
    @Published var document = MarkdownDocument(blocks: [])

    private var session: StreamingMarkdownSession?
    private let source: AsyncStream<String>?
    private let inputMode: StreamingMarkdownInputMode
    private let parser: (any MarkdownParser)?
    private let updateInterval: TimeInterval
    private let onUpdate: ((MarkdownRenderDiff) -> Void)?
    private var task: Task<Void, Never>?

    init(session: StreamingMarkdownSession, onUpdate: ((MarkdownRenderDiff) -> Void)?) {
        self.session = session
        self.source = nil
        self.inputMode = .delta
        self.parser = nil
        self.updateInterval = 0
        self.onUpdate = onUpdate
    }

    init(
        source: AsyncStream<String>,
        inputMode: StreamingMarkdownInputMode,
        parser: any MarkdownParser,
        updateInterval: TimeInterval,
        onUpdate: ((MarkdownRenderDiff) -> Void)?
    ) {
        self.session = nil
        self.source = source
        self.inputMode = inputMode
        self.parser = parser
        self.updateInterval = updateInterval
        self.onUpdate = onUpdate
    }

    func start() {
        stop()

        if let session {
            session.onUpdate = { [weak self] diff in
                Task { @MainActor in
                    self?.document = diff.document
                    self?.onUpdate?(diff)
                }
            }
            return
        }

        guard let source, let parser else { return }
        switch inputMode {
        case .delta:
            let session = StreamingMarkdownSession(
                parser: parser,
                updateInterval: updateInterval,
                deliveryQueue: .main
            )
            session.onUpdate = { [weak self] diff in
                Task { @MainActor in
                    self?.document = diff.document
                    self?.onUpdate?(diff)
                }
            }
            self.session = session
            task = Task {
                for await chunk in source {
                    if Task.isCancelled { break }
                    session.append(chunk)
                }
                session.finish()
            }
        case .snapshot:
            task = Task {
                for await snapshot in source {
                    if Task.isCancelled { break }
                    let parsed = (try? parser.parse(snapshot, options: .init())) ?? MarkdownDocument(blocks: [], source: snapshot)
                    document = parsed
                    onUpdate?(MarkdownRenderDiff(
                        document: parsed,
                        stableBlockCount: parsed.blocks.count,
                        phase: .streaming,
                        metrics: .init(sourceLength: snapshot.count)
                    ))
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
