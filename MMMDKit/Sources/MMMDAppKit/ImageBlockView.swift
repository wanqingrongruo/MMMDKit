import MMMDCore

#if canImport(AppKit)
import AppKit

final class ImageBlockView: NSImageView {
    private var imageBlock: ImageBlock?
    private var actions: MarkdownActions?

    init(imageBlock: ImageBlock, context: RenderContext) {
        self.imageBlock = imageBlock
        actions = context.actions
        super.init(frame: .zero)
        imageScaling = .scaleProportionallyUpOrDown
        setAccessibilityElement(true)
        setAccessibilityLabel(imageBlock.alt)
        addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(imageClicked)))
        load(imageBlock, context: context)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func load(_ imageBlock: ImageBlock, context: RenderContext) {
        guard let url = imageBlock.url, let imageLoader = context.imageLoader else {
            return
        }
        Task {
            guard let data = try? await imageLoader.loadImageData(from: url), let image = NSImage(data: data) else {
                return
            }
            await MainActor.run {
                self.image = image
            }
        }
    }

    @objc private func imageClicked() {
        guard let imageBlock else {
            return
        }
        actions?.onImageTap?(imageBlock)
    }
}
#endif
