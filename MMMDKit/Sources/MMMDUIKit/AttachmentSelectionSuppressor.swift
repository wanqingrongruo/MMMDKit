#if canImport(UIKit)
import UIKit

public extension UIView {
    func mmmdSuppressTextViewAttachmentSelection() {
        guard !(gestureRecognizers ?? []).contains(where: { $0 is MarkdownAttachmentSelectionSuppressingLongPressGestureRecognizer }) else {
            return
        }
        addGestureRecognizer(MarkdownAttachmentSelectionSuppressingLongPressGestureRecognizer())
    }
}

private final class MarkdownAttachmentSelectionSuppressingLongPressGestureRecognizer: UILongPressGestureRecognizer, UIGestureRecognizerDelegate {
    init() {
        super.init(target: MarkdownAttachmentSelectionSuppressorTarget.shared, action: #selector(MarkdownAttachmentSelectionSuppressorTarget.handle(_:)))
        minimumPressDuration = 0.05
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        delegate = self
    }

    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isAncestorTextViewGesture(preventedGestureRecognizer) else {
            return false
        }
        return true
    }

    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isAncestorTextViewGesture(preventingGestureRecognizer) else {
            return super.canBePrevented(by: preventingGestureRecognizer)
        }
        return false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let view = gestureRecognizer.view, let otherView = otherGestureRecognizer.view else {
            return false
        }
        return otherView.isDescendant(of: view)
    }

    private func isAncestorTextViewGesture(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard
            let view,
            let otherView = gestureRecognizer.view,
            otherView is UITextView,
            view.isDescendant(of: otherView)
        else {
            return false
        }
        return true
    }
}

private final class MarkdownAttachmentSelectionSuppressorTarget: NSObject {
    static let shared = MarkdownAttachmentSelectionSuppressorTarget()

    @objc func handle(_ gestureRecognizer: UILongPressGestureRecognizer) {}
}
#endif
