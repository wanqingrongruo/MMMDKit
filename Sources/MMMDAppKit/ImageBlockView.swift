import MMMDCore

#if canImport(AppKit)
import AppKit

final class ImageBlockView: NSImageView {
    init(imageBlock: ImageBlock, context: RenderContext) {
        super.init(frame: .zero)
        imageScaling = .scaleProportionallyUpOrDown
        setAccessibilityElement(true)
        setAccessibilityLabel(imageBlock.alt)
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
}
#endif
