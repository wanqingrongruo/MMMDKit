import MMMDCore

#if canImport(UIKit)
import UIKit

final class ImageBlockView: UIImageView {
    init(imageBlock: ImageBlock, context: RenderContext) {
        super.init(frame: .zero)
        contentMode = .scaleAspectFit
        isAccessibilityElement = true
        accessibilityLabel = imageBlock.alt
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
            guard let data = try? await imageLoader.loadImageData(from: url), let image = UIImage(data: data) else {
                return
            }
            await MainActor.run {
                self.image = image
            }
        }
    }
}
#endif
