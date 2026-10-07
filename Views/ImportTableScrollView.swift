import AppKit
import SwiftUI

struct ImportTableScrollView<Content: View>: NSViewRepresentable {
    private let content: Content
    private let activateSelection: (() -> Void)?
    private let toggleChecks: (() -> Void)?
    private let deleteSelection: (() -> Void)?

    init(activateSelection: (() -> Void)? = nil, toggleChecks: (() -> Void)? = nil, deleteSelection: (() -> Void)? = nil,
         @ViewBuilder content: () -> Content) {
        self.activateSelection = activateSelection
        self.toggleChecks = toggleChecks
        self.deleteSelection = deleteSelection
        self.content = content()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = false
        // Overlay scrollers disappear with macOS's default scroll-bar preference.
        scrollView.scrollerStyle = .legacy
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        let document = ImportTableHostingView(rootView: hostedContent(context: context))
        document.activateSelection = context.environment.isEnabled ? activateSelection : nil
        document.toggleChecks = context.environment.isEnabled ? toggleChecks : nil
        document.deleteSelection = context.environment.isEnabled ? deleteSelection : nil
        document.sizingOptions = []
        document.frame = NSRect(x: 0, y: 0, width: 1_180, height: 0)
        document.autoresizingMask = [.height]
        scrollView.documentView = document
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let document = scrollView.documentView as? ImportTableHostingView else { return }
        document.activateSelection = context.environment.isEnabled ? activateSelection : nil
        document.toggleChecks = context.environment.isEnabled ? toggleChecks : nil
        document.deleteSelection = context.environment.isEnabled ? deleteSelection : nil
        document.rootView = hostedContent(context: context)
        document.setFrameSize(NSSize(width: max(1_180, scrollView.contentView.bounds.width), height: scrollView.contentView.bounds.height))
    }

    private func hostedContent(context: Context) -> AnyView {
        AnyView(content.environment(\.self, context.environment))
    }
}
