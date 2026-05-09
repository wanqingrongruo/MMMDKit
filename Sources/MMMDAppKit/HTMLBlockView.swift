import MMMDCore
import MMMDHTML

#if canImport(AppKit) && canImport(WebKit)
import AppKit
import WebKit

final class HTMLBlockView: NSView {
    init(htmlBlock: HTMLBlock, context: RenderContext) {
        super.init(frame: .zero)
        let webView = WKWebView(frame: .zero)
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
        setAccessibilityElement(true)
        setAccessibilityLabel("HTML 内容")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
