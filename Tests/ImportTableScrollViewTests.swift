import AppKit
import SwiftUI
import XCTest
@testable import LedgerlyApp

@MainActor
final class ImportTableScrollViewTests: XCTestCase {
    func testVisibleHorizontalScrollbarReachesLastColumnsAndSurvivesResize() async throws {
        _ = NSApplication.shared
        let candidate = ImportCandidate(
            id: "preview", sourceRow: 2, transactionDate: "2026-05-08", transactionType: .expense,
            amount: "4.50", description: "Coffee", category: "Food", rejectionReason: nil
        )
        let hostingView = NSHostingView(rootView: ImportCandidateTableView(
            candidates: [candidate], selection: .constant([]), edit: { _ in }, remove: { _ in }
        ))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1_100, height: 400),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hostingView
        defer { window.close() }
        try await settleLayout(hostingView)
        let scrollView = try XCTUnwrap(findHorizontalScrollView(in: hostingView))
        let document = try XCTUnwrap(scrollView.documentView)
        let scroller = try XCTUnwrap(scrollView.horizontalScroller)
        XCTAssertFalse(scroller.isHidden)
        XCTAssertGreaterThan(scroller.frame.height, 0)
        XCTAssertLessThan(scroller.knobProportion, 1)
        XCTAssertEqual(document.frame.height, scrollView.contentView.bounds.height, accuracy: 1)

        scrollView.contentView.scroll(to: NSPoint(x: document.frame.width - scrollView.contentView.bounds.width, y: 0))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        XCTAssertGreaterThan(scrollView.contentView.bounds.minX, 0)
        XCTAssertEqual(scrollView.contentView.bounds.maxX, document.frame.maxX, accuracy: 1)
        XCTAssertEqual(scroller.doubleValue, 1, accuracy: 0.01)

        window.setContentSize(NSSize(width: 1_000, height: 500))
        try await settleLayout(hostingView)
        XCTAssertFalse(scroller.isHidden)
        XCTAssertEqual(document.frame.height, scrollView.contentView.bounds.height, accuracy: 1)
        scrollView.contentView.scroll(to: NSPoint(x: document.frame.width - scrollView.contentView.bounds.width, y: 0))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        XCTAssertEqual(scrollView.contentView.bounds.maxX, document.frame.maxX, accuracy: 1)
    }

    private func findHorizontalScrollView(in view: NSView) -> NSScrollView? {
        if let scrollView = view as? NSScrollView, scrollView.scrollerStyle == .legacy,
           scrollView.hasHorizontalScroller, !scrollView.hasVerticalScroller { return scrollView }
        return view.subviews.compactMap { findHorizontalScrollView(in: $0) }.first
    }

    private func settleLayout(_ view: NSView) async throws {
        view.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(50))
        view.layoutSubtreeIfNeeded()
    }
}
