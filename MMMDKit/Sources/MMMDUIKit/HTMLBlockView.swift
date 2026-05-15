import MMMDCore
import MMMDHTML

#if canImport(UIKit) && canImport(WebKit)
import UIKit
import WebKit

public final class HTMLBlockView: UIView {
    public static func exactHeight(for htmlBlock: HTMLBlock, width: CGFloat, context: RenderContext) -> CGFloat {
        return 100
    }
    public init(htmlBlock: HTMLBlock, context: RenderContext) {
        super.init(frame: .zero)
        mmmdSuppressTextViewAttachmentSelection()
        let webView = WKWebView(frame: .zero)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        webView.loadHTMLString(HTMLSanitizer().sanitize(htmlBlock.html), baseURL: nil)
        isAccessibilityElement = true
        accessibilityLabel = "HTML 内容"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
