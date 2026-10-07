import AppKit
import SwiftUI
import XCTest
@testable import LedgerlyApp

@MainActor
final class MonthlyReportTableTests: XCTestCase {
    func testLedgerCapsRowsAtTwelveAndShowsAllRowsWithoutExtraBlankRows() async throws {
        _ = NSApplication.shared
        let months = (1...12).map { month in
            MonthlyReport(month: month, startDate: String(format: "2026-%02d-01", month),
                          endDate: String(format: "2026-%02d-28", month), totals: .empty,
                          monthOverMonth: .empty, yearOverYear: .empty, categories: [])
        }
        let host = NSHostingView(rootView: MonthlyReportTable(months: months + [months[0]], selectedMonth: .constant(9)))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 360),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        defer { window.close() }
        host.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(50))
        host.layoutSubtreeIfNeeded()
        let table = try XCTUnwrap(findTable(in: host))
        XCTAssertEqual(table.numberOfRows, 12)
        let scrollView = try XCTUnwrap(table.enclosingScrollView)
        let lastRow = table.rect(ofRow: 11)
        XCTAssertLessThanOrEqual(lastRow.maxY, scrollView.contentView.bounds.maxY)
        XCTAssertLessThan(scrollView.contentView.bounds.maxY - lastRow.maxY, table.rowHeight + table.intercellSpacing.height)
    }

    private func findTable(in view: NSView) -> NSTableView? {
        if let table = view as? NSTableView { return table }
        return view.subviews.compactMap { findTable(in: $0) }.first
    }
}
