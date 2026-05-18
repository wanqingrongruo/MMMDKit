import UIKit
import MMMDCore
import MMMDHighlighter
import MMMDUIKit

class ChatFeedViewController: UIViewController {
    private let transcriptCollectionView: UICollectionView
    var configuration: MarkdownConfiguration!
    var messages: [MessageLayoutModel] = []

    init(title: String) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 0
        layout.estimatedItemSize = .zero
        transcriptCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 0
        layout.estimatedItemSize = .zero
        transcriptCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupTranscriptCollectionView()
        NSLayoutConstraint.activate([
            transcriptCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            transcriptCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            transcriptCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            transcriptCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        configuration = makeConfiguration()
    }

    func makeConfiguration() -> MarkdownConfiguration {
        MarkdownConfiguration(
            actions: .init(
                onLinkTap: { url in
                    Task { @MainActor in
                        UIApplication.shared.open(url)
                    }
                },
                onCopyCode: { [weak self] _, _ in
                    Task { @MainActor in
                        self?.showToast(message: "已复制代码块")
                    }
                },
                onCopyTable: { [weak self] _ in
                    Task { @MainActor in
                        self?.showToast(message: "已复制表格")
                    }
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

    func buildLayoutModel(for message: DemoChatMessage) -> MessageLayoutModel {
        MessageLayoutModel(
            message: message,
            layout: ChatBubbleLayoutEngine.build(
                message: message,
                configuration: configuration,
                containerWidth: view.bounds.width
            )
        )
    }

    func reloadTranscript() {
        transcriptCollectionView.reloadData()
    }

    func invalidateTranscriptLayout() {
        transcriptCollectionView.collectionViewLayout.invalidateLayout()
    }

    func insertItems(at indexPaths: [IndexPath], completion: ((Bool) -> Void)? = nil) {
        transcriptCollectionView.performBatchUpdates {
            transcriptCollectionView.insertItems(at: indexPaths)
        } completion: { finished in
            completion?(finished)
        }
    }

    func reloadItem(at indexPath: IndexPath, completion: ((Bool) -> Void)? = nil) {
        UIView.performWithoutAnimation {
            transcriptCollectionView.performBatchUpdates {
                transcriptCollectionView.collectionViewLayout.invalidateLayout()
                transcriptCollectionView.reloadItems(at: [indexPath])
            } completion: { finished in
                completion?(finished)
            }
        }
    }

    func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.font = .systemFont(ofSize: 14)
        toastLabel.textColor = .white
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textAlignment = .center
        toastLabel.layer.cornerRadius = 8
        toastLabel.clipsToBounds = true
        toastLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(toastLabel)

        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            toastLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            toastLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])

        UIView.animate(withDuration: 0.3, delay: 1.5, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { _ in
            toastLabel.removeFromSuperview()
        })
    }

    func presentImagePreview(for imageBlock: ImageBlock) {
        guard let url = imageBlock.url, let imageLoader = configuration.imageLoader else {
            showToast(message: "图片不可预览")
            return
        }

        Task {
            guard
                let data = try? await imageLoader.loadImageData(from: url),
                let image = UIImage(data: data)
            else {
                await MainActor.run {
                    self.showToast(message: "图片加载失败")
                }
                return
            }

            await MainActor.run {
                let previewController = UIViewController()
                previewController.view.backgroundColor = .black

                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                imageView.accessibilityLabel = imageBlock.alt
                imageView.translatesAutoresizingMaskIntoConstraints = false
                previewController.view.addSubview(imageView)

                let closeButton = UIButton(type: .system)
                closeButton.setTitle("关闭", for: .normal)
                closeButton.tintColor = .white
                closeButton.addAction(UIAction { [weak previewController] _ in
                    previewController?.dismiss(animated: true)
                }, for: .touchUpInside)
                closeButton.translatesAutoresizingMaskIntoConstraints = false
                previewController.view.addSubview(closeButton)

                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: previewController.view.leadingAnchor),
                    imageView.trailingAnchor.constraint(equalTo: previewController.view.trailingAnchor),
                    imageView.topAnchor.constraint(equalTo: previewController.view.topAnchor),
                    imageView.bottomAnchor.constraint(equalTo: previewController.view.bottomAnchor),
                    closeButton.trailingAnchor.constraint(equalTo: previewController.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                    closeButton.topAnchor.constraint(equalTo: previewController.view.safeAreaLayoutGuide.topAnchor, constant: 16)
                ])

                previewController.modalPresentationStyle = .fullScreen
                self.present(previewController, animated: true)
            }
        }
    }

    func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        transcriptCollectionView.layoutIfNeeded()
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        transcriptCollectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }

    func isNearBottom(threshold: CGFloat = 72) -> Bool {
        let visibleBottom = transcriptCollectionView.contentOffset.y
            + transcriptCollectionView.bounds.height
            - transcriptCollectionView.adjustedContentInset.bottom
        return transcriptCollectionView.contentSize.height - visibleBottom <= threshold
    }

    private func setupTranscriptCollectionView() {
        transcriptCollectionView.backgroundColor = .clear
        transcriptCollectionView.alwaysBounceVertical = true
        transcriptCollectionView.dataSource = self
        transcriptCollectionView.delegate = self
        transcriptCollectionView.register(ChatMessageCell.self, forCellWithReuseIdentifier: ChatMessageCell.reuseIdentifier)
        transcriptCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(transcriptCollectionView)
    }
}

extension ChatFeedViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        messages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatMessageCell.reuseIdentifier, for: indexPath) as! ChatMessageCell
        let model = messages[indexPath.item]
        let bubble = ChatMessageBubbleView(layout: model.layout)
        cell.host(bubble, width: model.layout.targetWidth, role: model.message.role)
        bubble.configure(model: model, configuration: configuration)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard indexPath.item < messages.count else { return .zero }
        let model = messages[indexPath.item]
        return CGSize(width: collectionView.bounds.width, height: model.layout.exactHeight)
    }
}
