import AppKit
import SwiftUI
import XCTest
@testable import LedgerlyApp

@MainActor
final class DashboardLayoutTests: XCTestCase {
    func testNativeVerticalPagingFollowsSelectionAndWindowSize() async throws {
        _ = NSApplication.shared
        let store = try SQLiteTestStore()
        for month in 1...12 {
            try store.repository.save(TransactionFixture.make(date: String(format: "2026-%02d-15", month), cents: month * 100, category: "Food"))
            try store.repository.save(TransactionFixture.make(date: String(format: "2026-%02d-16", month), cents: 500, category: "Transport"))
        }
        try store.repository.save(TransactionFixture.make(id: "removed", date: "2026-09-17", cents: 1000, deletedAt: "2026-09-18T00:00:00Z"))
        let now = TransactionDateFormatter().date(from: "2026-10-07")!
        let dashboard = DashboardController(reportService: DashboardReportService(repository: store.repository), currentDate: { now })
        let transactions = TransactionsController(service: TransactionService(repository: store.repository), bulkImportService: BulkImportService(repository: store.repository))
        let files = LocalFilesController(service: LocalFileService(repository: store.repository))
        let feedback = FeedbackController(repository: LocalFeedbackRepository(fileURL: store.directory.appendingPathComponent("feedback.txt")))
        let host = NSHostingView(rootView: AppShellView(dashboardController: dashboard, transactionsController: transactions, localFilesController: files, feedbackController: feedback))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1240, height: 820), styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        defer { window.close() }
        try await settle(host)
        XCTAssertEqual(dashboard.selectedPage, .spending)
        XCTAssertEqual(transactions.filteredTransactions.count, 2)
        try capture(host, name: "monthly-spending")
        let scopePicker = try XCTUnwrap(findScopePicker(in: host))
        XCTAssertEqual(scopePicker.label(forSegment: 0), "Month")
        XCTAssertEqual(scopePicker.label(forSegment: 1), "Year")
        scopePicker.selectedSegment = 1
        XCTAssertTrue(scopePicker.sendAction(scopePicker.action, to: scopePicker.target))
        try await settle(host)
        XCTAssertEqual(dashboard.scope, .yearly)
        XCTAssertEqual(transactions.filteredTransactions.count, 24)
        try capture(host, name: "yearly-spending")
        let pager = try XCTUnwrap(findPager(in: host))
        let document = try XCTUnwrap(pager.documentView)
        XCTAssertEqual(document.frame.height, pager.contentView.bounds.height * CGFloat(DashboardPage.allCases.count), accuracy: 2)
        XCTAssertLessThanOrEqual(document.frame.width, pager.contentView.bounds.width + 1)
        dashboard.selectedPage = .categories
        try await settle(host)
        XCTAssertEqual(pager.contentView.bounds.minY, pager.contentView.bounds.height, accuracy: 2)
        XCTAssertEqual(try XCTUnwrap(findTable(in: host)).numberOfRows, dashboard.categoryComparisons.count)
        try capture(host, name: "categories")

        window.setContentSize(NSSize(width: 640, height: 520))
        try await settle(host)
        let categoryTable = try XCTUnwrap(findTable(in: host))
        XCTAssertGreaterThan(categoryTable.visibleRect.height, 100)
        XCTAssertLessThanOrEqual(categoryTable.enclosingScrollView!.frame.width, host.bounds.width)
        XCTAssertEqual(document.frame.height, pager.contentView.bounds.height * CGFloat(DashboardPage.allCases.count), accuracy: 2)
        XCTAssertLessThanOrEqual(document.frame.width, pager.contentView.bounds.width + 1)
        XCTAssertEqual(pager.contentView.bounds.minY, pager.contentView.bounds.height, accuracy: 2)
        try capture(host, name: "categories-small")

        dashboard.selectedPage = .cashFlow
        try await settle(host)
        XCTAssertEqual(pager.contentView.bounds.minY, pager.contentView.bounds.height * 3, accuracy: 2)
        try capture(host, name: "cash-flow-small")
        let wheel = try XCTUnwrap(CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1,
                                         wheel1: -Int32(pager.contentView.bounds.height), wheel2: 0, wheel3: 0))
        pager.scrollWheel(with: try XCTUnwrap(NSEvent(cgEvent: wheel)))
        try await settle(host)
        XCTAssertEqual(dashboard.selectedPage, .balance, "Scrolling should update the selected report.")
        dashboard.selectedPage = .transactions
        try await settle(host)
        XCTAssertEqual(pager.contentView.bounds.minY, pager.contentView.bounds.height * 5, accuracy: 2)
        try capture(host, name: "transactions-small")
        transactions.selectStatus(.excluded)
        try await settle(host)
        XCTAssertEqual(dashboard.transactionIntervals(for: transactions.filteredTransactions).flatMap(\.transactions).map(\.id), ["removed"])
        transactions.include(id: "removed")
        try await settle(host)
        XCTAssertTrue(dashboard.transactionIntervals(for: transactions.filteredTransactions).flatMap(\.transactions).isEmpty)
        XCTAssertEqual(dashboard.snapshot.expenseCents, 14800)
        dashboard.selectScope(.monthly)
        dashboard.selectedPage = .categories
        try await settle(host)
        try capture(host, name: "monthly-categories-small")
        dashboard.selectedPage = .spending
        try await settle(host)
        try capture(host, name: "monthly-spending-small")
    }

    func testLongTransactionDetailsStayScrollableWithoutTruncation() async throws {
        _ = NSApplication.shared
        let transaction = TransactionListItem(id: "meal", transactionDate: "2026-05-11", transactionType: .expense,
                                              amountCents: 500, currency: "SGD", description: "Dinner with friends after the concert",
                                              category: "Food", notes: String(repeating: "Receipt saved. Shared with friends.\n", count: 12), deletedAt: nil)
        let host = NSHostingView(rootView: ScrollView(.vertical) {
            HighestTransactionDetailView(transaction: transaction).padding(12)
        })
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 116),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        defer { window.close() }
        try await settle(host)
        let scroll = try XCTUnwrap(findScrollableDetails(in: host))
        XCTAssertGreaterThan(try XCTUnwrap(scroll.documentView).frame.height, scroll.contentView.bounds.height)
        try capture(host, name: "highest-transaction-details")
    }

    private func findScrollableDetails(in view: NSView) -> NSScrollView? {
        if let scroll = view as? NSScrollView,
           let document = scroll.documentView, document.frame.height > scroll.contentView.bounds.height { return scroll }
        return view.subviews.compactMap { findScrollableDetails(in: $0) }.first
    }

    private func findPager(in view: NSView) -> NSScrollView? {
        if let scroll = view as? NSScrollView,
           let document = scroll.documentView,
           document.frame.height > scroll.contentView.bounds.height * 4 { return scroll }
        return view.subviews.compactMap { findPager(in: $0) }.first
    }

    private func findTable(in view: NSView) -> NSTableView? {
        if let table = view as? NSTableView { return table }
        return view.subviews.compactMap { findTable(in: $0) }.first
    }

    private func findScopePicker(in view: NSView) -> NSSegmentedControl? {
        if let control = view as? NSSegmentedControl, control.segmentCount == 2 { return control }
        return view.subviews.compactMap { findScopePicker(in: $0) }.first
    }

    private func settle(_ view: NSView) async throws {
        view.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(500))
        view.layoutSubtreeIfNeeded()
    }

    private func capture(_ view: NSView, name: String) throws {
        let defaultDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent(".build/report-previews", isDirectory: true)
        let url = ProcessInfo.processInfo.environment["LEDGERLY_PREVIEW_DIRECTORY"].map {
            URL(fileURLWithPath: $0, isDirectory: true)
        } ?? defaultDirectory
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        let data = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        try data.write(to: url.appendingPathComponent("\(name).png"))
    }
}
