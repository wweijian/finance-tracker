import SwiftUI

struct ImportTableScrollBridge: NSViewRepresentable {
    let controller: ImportTableScrollController

    func makeCoordinator() -> ImportTableScrollController { controller }

    func makeNSView(context: Context) -> ImportTableScrollAnchorView {
        let view = ImportTableScrollAnchorView()
        view.attach = attach
        return view
    }

    func updateNSView(_ view: ImportTableScrollAnchorView, context: Context) {
        view.attach = attach
        view.scheduleAttachment()
    }

    static func dismantleNSView(_ view: ImportTableScrollAnchorView, coordinator: ImportTableScrollController) {
        view.attach = nil
        coordinator.detach()
    }

    private func attach(from view: NSView) {
        var ancestor = view.superview
        while let container = ancestor {
            if let scroll = tableScrollView(in: container) {
                controller.attach(to: scroll)
                return
            }
            ancestor = container.superview
        }
    }

    private func tableScrollView(in view: NSView) -> NSScrollView? {
        if let scroll = view as? NSScrollView, scroll.documentView is NSTableView { return scroll }
        return view.subviews.lazy.compactMap { tableScrollView(in: $0) }.first
    }
}
