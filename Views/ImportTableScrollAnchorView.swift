import AppKit

final class ImportTableScrollAnchorView: NSView {
    var attach: ((NSView) -> Void)?

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        scheduleAttachment()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        scheduleAttachment()
    }

    func scheduleAttachment() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            attach?(self)
        }
    }
}
