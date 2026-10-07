import AppKit
import SwiftUI
import XCTest
@testable import LedgerlyApp

@MainActor
final class ReportRefreshTests: XCTestCase {
    func testReportsRefreshAfterSaveDeleteRestoreImportAndUndo() async throws {
        _ = NSApplication.shared
        let store = try SQLiteTestStore()
        let transaction = TransactionFixture.make(id: "purchase", cents: 100, category: "Food")
        try store.repository.save(transaction)
        let now = TransactionDateFormatter().date(from: "2026-06-15")!
        let dashboard = DashboardController(reportService: DashboardReportService(repository: store.repository), currentDate: { now })
        let transactions = TransactionsController(service: TransactionService(repository: store.repository),
                                                 bulkImportService: BulkImportService(repository: store.repository))
        let files = LocalFilesController(service: LocalFileService(repository: store.repository))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 680),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: AppShellView(dashboardController: dashboard, transactionsController: transactions, localFilesController: files))
        defer { window.close() }
        window.contentView?.layoutSubtreeIfNeeded()
        try await waitForReports(dashboard, transactions: transactions, spending: 100)

        var form = TransactionForm(transaction: transaction, date: TransactionDateFormatter().date(from: transaction.transactionDate)!)
        form.amount = "2.00"
        transactions.save(form)
        try await waitForReports(dashboard, transactions: transactions, spending: 200)
        transactions.form = form
        transactions.exclude(id: transaction.id)
        try await waitForReports(dashboard, transactions: transactions, spending: 0)
        XCTAssertNil(transactions.form)
        XCTAssertNotNil(try store.repository.transaction(id: transaction.id)?.deletedAt)
        transactions.include(id: transaction.id)
        try await waitForReports(dashboard, transactions: transactions, spending: 200)
        XCTAssertNil(try store.repository.transaction(id: transaction.id)?.deletedAt)

        let url = store.directory.appendingPathComponent("import.csv")
        let csv = "Transaction Date,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount,Category\n09 May 2026,ICT,Lunch,,,,Settled,4.50,,Food"
        try csv.write(to: url, atomically: true, encoding: .utf8)
        transactions.previewCSV(at: url, kind: .debit)
        try await waitForReports(dashboard, transactions: transactions, spending: 200)
        XCTAssertEqual(transactions.dataRevision, 3)
        transactions.commitBulkImport()
        try await waitForReports(dashboard, transactions: transactions, spending: 650)
        transactions.undoBulkImport()
        try await waitForReports(dashboard, transactions: transactions, spending: 200)
        XCTAssertEqual(transactions.dataRevision, 5)
        XCTAssertNil(transactions.bulkImportSummary)
        XCTAssertTrue(transactions.importCandidates.isEmpty)
    }

    private func waitForReports(_ dashboard: DashboardController, transactions: TransactionsController, spending: Int) async throws {
        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline && (dashboard.isLoading || transactions.isLoading || transactions.isMutating || transactions.isImporting || dashboard.snapshot.expenseCents != spending) {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertEqual(dashboard.snapshot.expenseCents, spending)
        XCTAssertNil(dashboard.errorMessage)
        XCTAssertNil(transactions.errorMessage)
        XCTAssertNil(transactions.bulkImportError)
        XCTAssertFalse(transactions.isMutating || transactions.isImporting || transactions.isLoading || dashboard.isLoading)
    }
}
