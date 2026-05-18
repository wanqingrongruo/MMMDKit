import AppKit
import MMMDCore
import MMMDHighlighter
import MMMDAppKit

class MacChatFeedViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    private let transcriptScrollView = NSScrollView()
    private let transcriptCollectionView = NSCollectionView()
    private let transcriptLayout = NSCollectionViewFlowLayout()
    var configuration: MarkdownConfiguration!
    var messages: [DemoChatMessage] = []
    private var previewWindows: [NSWindow] = []

    var headerView: NSView? { nil }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTranscriptCollectionView()
        setupLayout()
        configuration = makeConfiguration()
    }

    func makeConfiguration() -> MarkdownConfiguration {
        MarkdownConfiguration(
            actions: .init(
                onLinkTap: { url in
                    NSWorkspace.shared.open(url)
                },
                onCopyCode: { _, _ in
                    NSLog("已复制代码块")
                },
                onImageTap: { [weak self] imageBlock in
                    Task { @MainActor in
                        self?.presentImagePreview(for: imageBlock)
                    }
                }
            ),
            codeHighlighter: KeywordCodeHighlighter(),
            imageLoader: DemoImageLoader(),
            codeBlockMaximumWidth: 640
        )
    }

    func presentImagePreview(for imageBlock: ImageBlock) {
        guard let url = imageBlock.url, let imageLoader = configuration.imageLoader else {
            return
        }

        Task {
            guard
                let data = try? await imageLoader.loadImageData(from: url),
                let image = NSImage(data: data)
            else {
                return
            }

            await MainActor.run {
                let imageView = NSImageView()
                imageView.image = image
                imageView.imageScaling = .scaleProportionallyUpOrDown
                imageView.translatesAutoresizingMaskIntoConstraints = false

                let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 760, height: 460))
                contentView.wantsLayer = true
                contentView.layer?.backgroundColor = NSColor.black.cgColor
                contentView.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                    imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                    imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
                    imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
                ])

                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 760, height: 460),
                    styleMask: [.titled, .closable, .resizable],
                    backing: .buffered,
                    defer: false
                )
                window.title = imageBlock.alt.isEmpty ? "图片预览" : imageBlock.alt
                window.contentView = contentView
                window.center()
                window.makeKeyAndOrderFront(nil)
                self.previewWindows.append(window)
            }
        }
    }

    func reloadTranscript() {
        transcriptLayout.invalidateLayout()
        transcriptCollectionView.reloadData()
    }

    func insertItems(at indexPaths: Set<IndexPath>) {
        transcriptCollectionView.animator().insertItems(at: indexPaths)
    }

    func reloadItem(at indexPath: IndexPath) {
        transcriptLayout.invalidateLayout()
        transcriptCollectionView.reloadItems(at: Set([indexPath]))
    }

    func scrollToBottom() {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.messages.isEmpty else { return }
            let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
            self.transcriptCollectionView.scrollToItems(at: Set([indexPath]), scrollPosition: .bottom)
        }
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        messages.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: ChatMessageItem.identifier, for: indexPath) as? ChatMessageItem ?? ChatMessageItem()
        item.configure(message: messages[indexPath.item], configuration: configuration)
        return item
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> NSSize {
        let width = max(1, collectionView.enclosingScrollView?.contentView.bounds.width ?? collectionView.bounds.width)
        let height = ChatMessageRowView.estimatedHeight(for: messages[indexPath.item], width: width, configuration: configuration)
        return NSSize(width: width, height: height)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        transcriptLayout.invalidateLayout()
    }

    private func setupTranscriptCollectionView() {
        transcriptLayout.minimumInteritemSpacing = 0
        transcriptLayout.minimumLineSpacing = 14
        transcriptLayout.sectionInset = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        transcriptCollectionView.collectionViewLayout = transcriptLayout
        transcriptCollectionView.dataSource = self
        transcriptCollectionView.delegate = self
        transcriptCollectionView.register(ChatMessageItem.self, forItemWithIdentifier: ChatMessageItem.identifier)
        transcriptCollectionView.backgroundColors = [.clear]
        transcriptCollectionView.translatesAutoresizingMaskIntoConstraints = false

        transcriptScrollView.hasVerticalScroller = true
        transcriptScrollView.hasHorizontalScroller = false
        transcriptScrollView.drawsBackground = false
        transcriptScrollView.translatesAutoresizingMaskIntoConstraints = false
        transcriptScrollView.documentView = transcriptCollectionView
        view.addSubview(transcriptScrollView)

        NSLayoutConstraint.activate([
            transcriptCollectionView.leadingAnchor.constraint(equalTo: transcriptScrollView.contentView.leadingAnchor),
            transcriptCollectionView.trailingAnchor.constraint(equalTo: transcriptScrollView.contentView.trailingAnchor),
            transcriptCollectionView.topAnchor.constraint(equalTo: transcriptScrollView.contentView.topAnchor),
            transcriptCollectionView.widthAnchor.constraint(equalTo: transcriptScrollView.contentView.widthAnchor)
        ])
    }

    private func setupLayout() {
        if let headerView {
            headerView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(headerView)
            NSLayoutConstraint.activate([
                headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
                headerView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
                transcriptScrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16)
            ])
        } else {
            transcriptScrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        }

        NSLayoutConstraint.activate([
            transcriptScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            transcriptScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            transcriptScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24)
        ])
    }
}
