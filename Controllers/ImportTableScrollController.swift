import AppKit
import Combine

@MainActor
final class ImportTableScrollController: ObservableObject {
    @Published private(set) var canScrollLeft = false
    @Published private(set) var canScrollRight = false
    @Published private(set) var horizontalPosition = 0.0

    private weak var scrollView: NSScrollView?
    private var subscriptions = Set<AnyCancellable>()

    func attach(to scrollView: NSScrollView) {
        scrollView.scrollerStyle = .legacy
        scrollView.autohidesScrollers = false
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        // SwiftUI initially lays out the table for overlay scrollbars.
        scrollView.tile()
        guard self.scrollView !== scrollView else { return }
        self.scrollView = scrollView
        subscriptions.removeAll()
        scrollView.contentView.postsBoundsChangedNotifications = true
        scrollView.documentView?.postsFrameChangedNotifications = true
        observe(NSView.boundsDidChangeNotification, object: scrollView.contentView)
        if let document = scrollView.documentView {
            observe(NSView.frameDidChangeNotification, object: document)
        }
        updateAvailability()
    }

    func detach() {
        subscriptions.removeAll()
        scrollView = nil
    }

    func scrollLeft() { scroll(by: -1) }
    func scrollRight() { scroll(by: 1) }

    func scroll(to position: Double) {
        guard let scrollView else { return }
        let maximum = max(0, (scrollView.documentView?.frame.width ?? 0) - scrollView.contentView.bounds.width)
        setOffset(CGFloat(min(1, max(0, position))) * maximum, in: scrollView)
    }

    private func scroll(by direction: CGFloat) {
        guard let scrollView else { return }
        let clip = scrollView.contentView
        let maximum = max(0, (scrollView.documentView?.frame.width ?? 0) - clip.bounds.width)
        let offset = min(maximum, max(0, clip.bounds.minX + direction * clip.bounds.width * 0.7))
        setOffset(offset, in: scrollView)
    }

    private func setOffset(_ offset: CGFloat, in scrollView: NSScrollView) {
        let clip = scrollView.contentView
        clip.scroll(to: NSPoint(x: offset, y: clip.bounds.minY))
        scrollView.reflectScrolledClipView(clip)
        updateAvailability()
    }

    private func observe(_ name: Notification.Name, object: NSView) {
        NotificationCenter.default.publisher(for: name, object: object)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.updateAvailability() }
            }
            .store(in: &subscriptions)
    }

    private func updateAvailability() {
        guard let scrollView, let document = scrollView.documentView else { return }
        let bounds = scrollView.contentView.bounds
        // The native header has a separate viewport from the editable rows.
        if let table = document as? NSTableView, let headerClip = table.headerView?.superview as? NSClipView,
           abs(headerClip.bounds.minX - bounds.minX) > 0.5 {
            headerClip.scroll(to: NSPoint(x: bounds.minX, y: headerClip.bounds.minY))
        }
        let left = bounds.minX > 1
        let right = bounds.maxX < document.frame.maxX - 1
        if canScrollLeft != left { canScrollLeft = left }
        if canScrollRight != right { canScrollRight = right }
        let maximum = max(0, document.frame.width - bounds.width)
        let position = maximum > 0 ? Double(bounds.minX / maximum) : 0
        if abs(horizontalPosition - position) > 0.001 { horizontalPosition = position }
    }
}
