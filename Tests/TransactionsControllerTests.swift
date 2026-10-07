import Foundation
import XCTest
@testable import LedgerlyApp

@MainActor
final class TransactionsControllerTests: XCTestCase {
    func testFilteredExportUsesSearchTypeCategoryDatesAndSort() async throws {
        let store = try SQLiteTestStore()
        for transaction in [
            TransactionFixture.make(id: "small", date: "2026-05-10", cents: 100, description: "Coffee small"),
            TransactionFixture.make(id: "large", date: "2026-05-20", cents: 900, description: "Coffee large"),
            TransactionFixture.make(id: "outside", date: "2026-04-30", description: "Coffee outside"),
            TransactionFixture.make(id: "type", date: "2026-05-15", type: .income, description: "Coffee refund"),
            TransactionFixture.make(id: "category", date: "2026-05-15", category: "Transport", description: "Coffee delivery"),
            TransactionFixture.make(id: "search", date: "2026-05-15", description: "Lunch"),
            TransactionFixture.make(id: "deleted", date: "2026-05-15", description: "Coffee deleted", deletedAt: "2026-05-16T00:00:00Z")
        ] { try store.repository.save(transaction) }
        let controller = makeController(store)
        controller.load()
        try await waitForLoad(controller)
        controller.searchText = "COFFEE"
        controller.selectedType = .expense
        controller.selectedCategory = "Food & Dining"
        controller.dateFilterMode = .range
        controller.startDateText = "2026-05-10"
        controller.endDateText = "2026-05-20"
        controller.sortOrder = [KeyPathComparator(\TransactionListItem.amountCents, order: .reverse)]
        XCTAssertEqual(controller.filteredTransactions.map(\.id), ["large", "small"])
        let fileService = LocalFileService(repository: store.repository)
        let destination = store.directory.appendingPathComponent("filtered.csv")
        try await fileService.export(controller.filteredTransactions, to: destination)
        let csv = try String(contentsOf: destination, encoding: .utf8)
        XCTAssertEqual(csv.components(separatedBy: "\r\n").count, 4)
        XCTAssertTrue(csv.components(separatedBy: "\r\n")[1].hasPrefix("large,"))
        XCTAssertFalse(csv.contains("\r\noutside,"))
        XCTAssertFalse(csv.contains("\r\ndeleted,"))
        controller.selectStatus(.all)
        try await waitForLoad(controller)
        XCTAssertEqual(Set(controller.filteredTransactions.map(\.id)), ["large", "small", "deleted"])
    }

    func testFailedValidationKeepsEditorAndProvidesActionableError() throws {
        let store = try SQLiteTestStore()
        let controller = makeController(store)
        controller.presentNewTransaction()
        var form = controller.form!
        form.amount = "4.50bad"
        controller.save(form)
        XCTAssertNotNil(controller.form)
        XCTAssertEqual(controller.errorMessage, "Enter a valid non-negative amount.")
        form.amount = "4.50"
        form.description = "   "
        controller.save(form)
        XCTAssertNotNil(controller.form)
        XCTAssertEqual(controller.errorMessage, "A description is required.")
        XCTAssertEqual(controller.dataRevision, 0)
    }

    func testAmountRemarksAndStatusFiltersCombineAndExportOnlyMatchingRows() async throws {
        let store = try SQLiteTestStore()
        try store.repository.save(TransactionFixture.make(id: "match", cents: 450, notes: "Reimbursable"))
        try store.repository.save(TransactionFixture.make(id: "small", cents: 449, notes: "Reimbursable"))
        try store.repository.save(TransactionFixture.make(id: "large", cents: 451, notes: "Reimbursable"))
        try store.repository.save(TransactionFixture.make(id: "blank", cents: 450))
        try store.repository.save(TransactionFixture.make(id: "deleted", cents: 450, deletedAt: "2026-05-09T00:00:00Z", notes: "Reimbursable"))
        let controller = makeController(store)
        controller.load()
        try await waitForLoad(controller)
        controller.minimumAmount = "4.50"
        controller.maximumAmount = "4.50"
        controller.remarksFilter = .withRemarks
        XCTAssertEqual(controller.filteredTransactions.map(\.id), ["match"])
        controller.remarksFilter = .withoutRemarks
        XCTAssertEqual(controller.filteredTransactions.map(\.id), ["blank"])
        controller.remarksFilter = .withRemarks
        controller.selectStatus(.excluded)
        try await waitForLoad(controller)
        XCTAssertEqual(controller.filteredTransactions.map(\.id), ["deleted"])
        controller.selectStatus(.all)
        XCTAssertEqual(Set(controller.filteredTransactions.map(\.id)), ["match", "deleted"])

        let destination = store.directory.appendingPathComponent("remarks-filtered.csv")
        try await LocalFileService(repository: store.repository).export(controller.filteredTransactions, to: destination)
        let csv = try String(contentsOf: destination, encoding: .utf8)
        XCTAssertTrue(csv.contains("Reimbursable"))
        XCTAssertFalse(csv.contains("\r\nblank,"))
        XCTAssertFalse(csv.contains("\r\nsmall,"))
    }

    func testTypedDatesAreInclusiveAndSupportOpenEndedRanges() async throws {
        let store = try SQLiteTestStore()
        for (id, date) in [("before", "2024-02-28"), ("start", "2024-02-29"), ("end", "2024-03-01"), ("after", "2024-03-02")] {
            try store.repository.save(TransactionFixture.make(id: id, date: date))
        }
        let controller = makeController(store)
        controller.load()
        try await waitForLoad(controller)
        controller.dateFilterMode = .range
        controller.startDateText = "2024-02-29"
        controller.endDateText = "2024-03-01"
        XCTAssertNil(controller.filterErrorMessage)
        XCTAssertEqual(Set(controller.filteredTransactions.map(\.id)), ["start", "end"])
        controller.startDateText = ""
        XCTAssertEqual(Set(controller.filteredTransactions.map(\.id)), ["before", "start", "end"])
        controller.startDateText = "2024-02-29"
        controller.endDateText = ""
        XCTAssertEqual(Set(controller.filteredTransactions.map(\.id)), ["start", "end", "after"])
    }

    func testInvalidFilterInputHasActionableErrorsAndDoesNotReturnUnfilteredData() async throws {
        let store = try SQLiteTestStore()
        try store.repository.save(TransactionFixture.make(id: "purchase"))
        let controller = makeController(store)
        controller.load()
        try await waitForLoad(controller)
        controller.dateFilterMode = .range
        for invalid in ["2026-02-30", "2026-2-01", "2026-05-", "bad"] {
            controller.startDateText = invalid
            XCTAssertTrue(controller.filterErrorMessage?.contains("From date") == true)
            XCTAssertTrue(controller.filteredTransactions.isEmpty)
        }
        controller.startDateText = "2026-05-10"
        controller.endDateText = "2026-05-01"
        XCTAssertEqual(controller.filterErrorMessage, "The From date must be on or before the Through date.")
        controller.clearFilters()
        for invalid in ["-1", "4.500", "4.50bad", "999999999999999999999999999999"] {
            controller.minimumAmount = invalid
            XCTAssertNotNil(controller.filterErrorMessage)
            XCTAssertTrue(controller.filteredTransactions.isEmpty)
        }
        controller.minimumAmount = "5.00"
        controller.maximumAmount = "4.50"
        XCTAssertEqual(controller.filterErrorMessage, "The minimum amount must not exceed the maximum amount.")
        controller.clearFilters()
        XCTAssertNil(controller.filterErrorMessage)
        XCTAssertEqual(controller.filteredTransactions.map(\.id), ["purchase"])
    }

    func testHeaderSortOrdersUseNumbersAndPreserveMultipleKeys() async throws {
        let store = try SQLiteTestStore()
        for transaction in [
            TransactionFixture.make(id: "a", cents: 100, description: "Zulu", notes: "Alpha"),
            TransactionFixture.make(id: "b", cents: 2000, description: "Alpha", notes: "Zulu"),
            TransactionFixture.make(id: "c", cents: 900, description: "Middle", notes: "Alpha")
        ] { try store.repository.save(transaction) }
        let controller = makeController(store)
        controller.load()
        try await waitForLoad(controller)
        controller.sortOrder = [KeyPathComparator(\TransactionListItem.amountCents)]
        XCTAssertEqual(controller.filteredTransactions.map(\.id), ["a", "c", "b"])
        controller.sortOrder = [KeyPathComparator(\TransactionListItem.amountCents, order: .reverse)]
        XCTAssertEqual(controller.filteredTransactions.map(\.id), ["b", "c", "a"])
        controller.sortOrder = [KeyPathComparator(\TransactionListItem.description)]
        XCTAssertEqual(controller.filteredTransactions.map(\.id), ["b", "c", "a"])
        controller.sortOrder = [KeyPathComparator(\TransactionListItem.remarks), KeyPathComparator(\TransactionListItem.amountCents, order: .reverse)]
        XCTAssertEqual(controller.filteredTransactions.map(\.id), ["c", "a", "b"])
        controller.searchText = "aLPHa"
        XCTAssertEqual(Set(controller.filteredTransactions.map(\.id)), ["a", "b", "c"])
    }

    func testRemarksSaveEditClearAndReopenWithoutChangingDuplicateIdentity() async throws {
        let store = try SQLiteTestStore()
        let original = TransactionFixture.make(id: "purchase")
        try store.repository.save(original)
        let controller = makeController(store)
        var form = TransactionForm(transaction: original, date: TransactionDateFormatter().date(from: original.transactionDate)!)
        form.notes = "  Claim from employer\nReceipt saved  "
        controller.save(form)
        try await waitForMutation(controller)
        let reopened = try SQLiteTransactionRepository(databaseURL: store.databaseURL, schemaURL: store.schemaURL)
        XCTAssertEqual(try reopened.transaction(id: "purchase")?.notes, "Claim from employer\nReceipt saved")
        XCTAssertEqual(try reopened.transactions(includeDeleted: false).first?.remarks, "Claim from employer\nReceipt saved")
        XCTAssertTrue(try reopened.isDuplicate(date: original.transactionDate, amountCents: original.amountCents, description: original.description))
        form.notes = "  "
        controller.save(form)
        try await waitForMutation(controller)
        XCTAssertNil(try reopened.transaction(id: "purchase")?.notes)
    }

    func testClearFiltersResetsAllCriteriaAndKeepsSortOrder() async throws {
        let store = try SQLiteTestStore()
        let controller = makeController(store)
        controller.searchText = "Coffee"
        controller.selectedCategory = "Food"
        controller.selectedType = .income
        controller.dateFilterMode = .range
        controller.startDateText = "2026-01-01"
        controller.endDateText = "2026-01-31"
        controller.minimumAmount = "1"
        controller.maximumAmount = "2"
        controller.remarksFilter = .withRemarks
        controller.selectStatus(.excluded)
        controller.sortOrder = [KeyPathComparator(\TransactionListItem.amountCents)]
        XCTAssertTrue(controller.hasActiveFilters)
        controller.clearFilters()
        try await waitForLoad(controller)
        XCTAssertFalse(controller.hasActiveFilters)
        XCTAssertEqual(controller.statusFilter, .included)
        XCTAssertEqual(controller.startDateText, "")
        XCTAssertEqual(controller.endDateText, "")
        XCTAssertEqual(controller.sortOrder.first?.keyPath, \TransactionListItem.amountCents)
    }

    private func waitForMutation(_ controller: TransactionsController) async throws {
        let deadline = Date().addingTimeInterval(3)
        while controller.isMutating && Date() < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertFalse(controller.isMutating)
        XCTAssertNil(controller.errorMessage)
        try await waitForLoad(controller)
    }

    func testExcludingAndIncludingRowsPreservesDataAndUpdatesReportTotals() async throws {
        let store = try SQLiteTestStore()
        let purchase = TransactionFixture.make(id: "purchase", cents: 450, notes: "Receipt saved")
        try store.repository.save(purchase)
        try store.repository.save(TransactionFixture.make(id: "salary", type: .income, cents: 10000))
        try store.repository.save(TransactionFixture.make(id: "other", cents: 300))
        let controller = makeController(store)
        controller.load()
        try await waitForLoad(controller)
        controller.exclude(id: "purchase")
        try await waitForMutation(controller)
        XCTAssertEqual(Set(controller.filteredTransactions.map(\.id)), ["salary", "other"])
        let persisted = try XCTUnwrap(store.repository.transaction(id: "purchase"))
        XCTAssertNotNil(persisted.deletedAt)
        XCTAssertEqual(persisted.notes, purchase.notes)
        XCTAssertEqual(persisted.dateCreated, purchase.dateCreated)
        XCTAssertEqual(try store.repository.transactions(includeDeleted: true).count, 3)

        let reports = DashboardReportService(repository: store.repository)
        let excludedReport = try await reports.dashboard(for: DashboardPeriod(year: 2026))
        XCTAssertEqual(excludedReport.expenseCents, 300)
        XCTAssertEqual(excludedReport.netCents, 9700)
        controller.selectStatus(.excluded)
        try await waitForLoad(controller)
        XCTAssertEqual(controller.filteredTransactions.first?.statusLabel, "Deleted")
        XCTAssertEqual(controller.filteredTransactions.map(\.id), ["purchase"])
        controller.include(id: "purchase")
        try await waitForMutation(controller)
        XCTAssertTrue(controller.filteredTransactions.isEmpty)
        XCTAssertNil(try store.repository.transaction(id: "purchase")?.deletedAt)
        let includedReport = try await reports.dashboard(for: DashboardPeriod(year: 2026))
        XCTAssertEqual(includedReport.expenseCents, 750)
        XCTAssertEqual(includedReport.netCents, 9250)
        controller.selectStatus(.included)
        try await waitForLoad(controller)
        XCTAssertEqual(controller.filteredTransactions.first { $0.id == "purchase" }?.statusLabel, "Active")
    }

    func testFailedFileChangeClearsPreviousPreviewAndCannotCommitOldRows() async throws {
        let store = try SQLiteTestStore()
        let controller = makeController(store)
        let original = try writeImportCSV(in: store, category: "Food")
        controller.presentBulkImport()
        controller.previewCSV(at: original, kind: .debit)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importPreview.readyCount, 1)

        let invalid = store.directory.appendingPathComponent("invalid.csv")
        try "Unsupported,Header\nInvalid,Row".write(to: invalid, atomically: true, encoding: .utf8)
        controller.previewCSV(at: invalid, kind: .debit)
        XCTAssertTrue(controller.importCandidates.isEmpty)
        try await waitForImport(controller)
        XCTAssertNotNil(controller.bulkImportError)
        XCTAssertNil(controller.errorMessage)
        controller.commitBulkImport()
        XCTAssertNil(controller.bulkImportSummary)
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
    }

    func testRevalidationBlocksCommitUntilEditedRowIsReady() async throws {
        let store = try SQLiteTestStore()
        let controller = makeController(store)
        let url = try writeImportCSV(in: store, category: "Unknown")
        controller.presentBulkImport()
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importPreview.rejectedCount, 1)
        var corrected = try XCTUnwrap(controller.importCandidates.first)
        corrected.category = "Food"

        controller.revalidate(corrected)
        XCTAssertEqual(controller.importActivity, .validatingRows)
        controller.commitBulkImport()
        XCTAssertNil(controller.bulkImportSummary)
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importPreview.readyCount, 1)
        controller.commitBulkImport()
        try await waitForImport(controller)
        try await waitForLoad(controller)
        XCTAssertEqual(controller.bulkImportSummary?.acceptedCount, 1)
        XCTAssertEqual(try store.repository.transactions(includeDeleted: false).first?.category, "Food")
    }

    private func writeImportCSV(in store: SQLiteTestStore, category: String) throws -> URL {
        let url = store.directory.appendingPathComponent("import.csv")
        let csv = """
        Transaction Date,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount,Category
        08 May 2026,ICT,Coffee shop,,,,Settled,4.50,,\(category)
        """
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func waitForImport(_ controller: TransactionsController) async throws {
        let deadline = Date().addingTimeInterval(3)
        while controller.isImporting && Date() < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertFalse(controller.isImporting, "Import operation did not finish")
    }

    private func makeController(_ store: SQLiteTestStore) -> TransactionsController {
        TransactionsController(service: TransactionService(repository: store.repository),
                               bulkImportService: BulkImportService(repository: store.repository))
    }

    private func waitForLoad(_ controller: TransactionsController) async throws {
        let deadline = Date().addingTimeInterval(3)
        while controller.isLoading && Date() < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertFalse(controller.isLoading, "Transactions did not load")
        XCTAssertNil(controller.errorMessage)
    }
}
