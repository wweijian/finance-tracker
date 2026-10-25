import Foundation
import XCTest
@testable import FinanceApp

@MainActor
final class ImportCandidateEditingTests: XCTestCase {
    func testRapidEditsToDifferentRowsPreserveTheLatestValues() async throws {
        let store = try SQLiteTestStore()
        let controller = makeController(store)
        let url = try debitCSV([
            "08 May 2026,ICT,Coffee,,,,Settled,4.50,,Food",
            "09 May 2026,ICT,Lunch,,,,Settled,8.00,,Food"
        ], in: store)
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        for index in 0..<20 {
            var row = controller.importCandidates[index % 2]
            row.description = "Change \(index)"
            controller.revalidate(row)
        }
        XCTAssertEqual(controller.importCandidates.map(\.description), ["Change 18", "Change 19"])
        try await waitForImport(controller)
        XCTAssertEqual(controller.importCandidates.map(\.description), ["Change 18", "Change 19"])
        XCTAssertTrue(controller.importCandidates.allSatisfy(\.isReady))
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
    }

    func testEditingCorrectsRejectedRowAndCommitsEditedFieldsWithoutChangingCSV() async throws {
        let store = try SQLiteTestStore()
        let url = try debitCSV([
            "08 May 2026,ICT,Coffee,,,,Settled,4.50,,Unknown"
        ], in: store)
        let source = try Data(contentsOf: url)
        let controller = makeController(store)
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        let original = try XCTUnwrap(controller.importCandidates.first)
        XCTAssertFalse(original.isReady)
        var draft = original
        draft.transactionDate = "2026-05-09"
        draft.transactionType = .income
        draft.amount = "1234.56"
        draft.description = "Refund"
        draft.category = "food"
        draft.remarks = "Receipt saved\nReimbursed"
        controller.revalidate(draft)
        XCTAssertTrue(controller.isImporting)
        controller.commitBulkImport()
        XCTAssertNil(controller.bulkImportSummary)
        try await waitForImport(controller)
        let edited = try XCTUnwrap(controller.importCandidates.first)
        XCTAssertTrue(edited.isReady)
        XCTAssertEqual(edited.id, original.id)
        XCTAssertEqual(edited.sourceRow, original.sourceRow)
        XCTAssertEqual(edited.category, "Food")
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
        controller.commitBulkImport()
        try await waitForImport(controller)
        let transaction = try XCTUnwrap(store.repository.transactions(includeDeleted: false).first)
        XCTAssertEqual(transaction.transactionDate, "2026-05-09")
        XCTAssertEqual(transaction.transactionType, .income)
        XCTAssertEqual(transaction.amountCents, 123456)
        XCTAssertEqual(transaction.description, "Refund")
        XCTAssertEqual(transaction.category, "Food")
        XCTAssertEqual(transaction.notes, "Receipt saved\nReimbursed")
        XCTAssertEqual(try Data(contentsOf: url), source)
    }

    func testInvalidEditsStayVisibleUntilCorrectedWithoutWritingToDatabase() async throws {
        let store = try SQLiteTestStore()
        let url = try debitCSV(["08 May 2026,ICT,Coffee,,,,Settled,4.50,,Food"], in: store)
        let controller = makeController(store)
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        var draft = try XCTUnwrap(controller.importCandidates.first)
        draft.transactionDate = "2026-02-30"
        controller.revalidate(draft)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importCandidates.first?.transactionDate, "2026-02-30")
        XCTAssertEqual(controller.importCandidates.first?.rejectionReason, "Date must use YYYY-MM-DD.")
        draft.transactionDate = "2026-02-28"
        draft.amount = "4.501"
        controller.revalidate(draft)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importCandidates.first?.amount, "4.501")
        XCTAssertEqual(controller.importCandidates.first?.rejectionReason, "Amount is invalid.")
        draft.amount = "4.50"
        controller.revalidate(draft)
        try await waitForImport(controller)
        XCTAssertTrue(controller.importCandidates.allSatisfy(\.isReady))
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
    }

    func testEditingEarlierDuplicateRevalidatesEveryRemainingRow() async throws {
        let store = try SQLiteTestStore()
        let url = try debitCSV([
            "08 May 2026,ICT,Coffee,,,,Settled,4.50,,Food",
            "08 May 2026,ICT,Coffee,,,,Settled,4.50,,Food"
        ], in: store)
        let controller = makeController(store)
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importPreview.rejectedCount, 1)
        let first = try XCTUnwrap(controller.importCandidates.first)
        var draft = first
        draft.description = "Lunch"
        controller.revalidate(draft)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importPreview.readyCount, 2)
        XCTAssertEqual(controller.importPreview.rejectedCount, 0)
        let second = controller.importCandidates[1]
        draft = second
        draft.description = "Lunch"
        controller.revalidate(draft)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importCandidates[1].rejectionReason, "Duplicate of row 2 in this import.")
        XCTAssertEqual(controller.importCandidates[1].description, "Lunch")
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
    }

    func testFinanceEditsPreserveExportIdentityCurrencyAndDeletedStatus() async throws {
        let store = try SQLiteTestStore()
        let controller = makeController(store)
        let url = store.directory.appendingPathComponent("finance.csv")
        let csv = """
        id,transaction_date,transaction_type,amount,currency,description,category,notes,deleted_at
        exported-id,2026-05-08,expense,4.50,USD,Coffee,Food,,2026-05-09T00:00:00Z
        """
        try csv.write(to: url, atomically: true, encoding: .utf8)
        controller.previewCSV(at: url, kind: .finance)
        try await waitForImport(controller)
        let original = try XCTUnwrap(controller.importCandidates.first)
        var draft = original
        draft.transactionType = .income
        draft.financeDetails?.transactionType = "income"
        draft.remarks = "  Edited remarks  "
        controller.revalidate(draft)
        try await waitForImport(controller)
        controller.commitBulkImport()
        try await waitForImport(controller)
        let transaction = try XCTUnwrap(store.repository.transaction(id: "exported-id"))
        XCTAssertEqual(transaction.transactionType, .income)
        XCTAssertEqual(transaction.currency, "USD")
        XCTAssertEqual(transaction.deletedAt, "2026-05-09T00:00:00Z")
        XCTAssertEqual(transaction.notes, "  Edited remarks  ")
    }

    func testRemovingEditedRowPreservesChangesForUndoAndCancellationStopsValidation() async throws {
        let store = try SQLiteTestStore()
        let url = try debitCSV(["08 May 2026,ICT,Coffee,,,,Settled,4.50,,Food"], in: store)
        let controller = makeController(store)
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        var edited = try XCTUnwrap(controller.importCandidates.first)
        edited.description = "Edited coffee"
        controller.revalidate(edited)
        controller.removeImportRows([edited.id])
        try await waitForImport(controller)
        XCTAssertTrue(controller.importCandidates.isEmpty)
        controller.undoImportRowRemovals()
        try await waitForImport(controller)
        XCTAssertEqual(controller.importCandidates.first?.description, "Edited coffee")
        edited.description = "Discard this edit"
        controller.revalidate(edited)
        controller.cancelBulkImport()
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertFalse(controller.isImporting)
        XCTAssertTrue(controller.importCandidates.isEmpty)
        controller.revalidate(edited)
        XCTAssertFalse(controller.isImporting)
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
    }

    private func makeController(_ store: SQLiteTestStore) -> TransactionsController {
        TransactionsController(service: TransactionService(repository: store.repository),
                               bulkImportService: BulkImportService(repository: store.repository))
    }

    private func debitCSV(_ rows: [String], in store: SQLiteTestStore) throws -> URL {
        let url = store.directory.appendingPathComponent("\(UUID().uuidString).csv")
        let header = "Transaction Date,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount,Category"
        try ([header] + rows).joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func waitForImport(_ controller: TransactionsController) async throws {
        let deadline = Date().addingTimeInterval(3)
        while controller.isImporting && Date() < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertFalse(controller.isImporting)
        XCTAssertNil(controller.bulkImportError)
    }
}
