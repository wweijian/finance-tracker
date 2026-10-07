import Foundation
import XCTest
@testable import LedgerlyApp

@MainActor
final class ImportCandidateEditingTests: XCTestCase {
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
        controller.editImportCandidate(id: original.id)
        var draft = try XCTUnwrap(controller.importEditorCandidate)
        draft.transactionDate = "2026-05-09"
        draft.transactionType = .income
        draft.amount = "1234.56"
        draft.description = "Refund"
        draft.category = "food"
        draft.remarks = "Receipt saved\nReimbursed"
        controller.saveImportCandidate(draft)
        XCTAssertTrue(controller.isImporting)
        controller.commitBulkImport()
        XCTAssertNil(controller.bulkImportSummary)
        try await waitForImport(controller)
        XCTAssertNil(controller.importEditorCandidate)
        XCTAssertNil(controller.importEditorError)
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

    func testInvalidEditsKeepEditorOpenAndCancelLeavesOriginalPreviewUntouched() async throws {
        let store = try SQLiteTestStore()
        let url = try debitCSV(["08 May 2026,ICT,Coffee,,,,Settled,4.50,,Food"], in: store)
        let controller = makeController(store)
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        let original = try XCTUnwrap(controller.importCandidates.first)
        controller.editImportCandidate(id: original.id)
        var draft = original
        draft.transactionDate = "2026-02-30"
        controller.saveImportCandidate(draft)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importEditorCandidate?.id, original.id)
        XCTAssertEqual(controller.importEditorError, "Date must use YYYY-MM-DD.")
        XCTAssertEqual(controller.importCandidates, [original])
        draft.transactionDate = original.transactionDate
        draft.amount = "4.501"
        controller.saveImportCandidate(draft)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importEditorError, "Amount is invalid.")
        XCTAssertEqual(controller.importCandidates, [original])
        controller.importEditorCandidate = nil
        XCTAssertEqual(controller.importCandidates, [original])
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
        controller.editImportCandidate(id: first.id)
        var draft = first
        draft.description = "Lunch"
        controller.saveImportCandidate(draft)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importPreview.readyCount, 2)
        XCTAssertEqual(controller.importPreview.rejectedCount, 0)
        let second = controller.importCandidates[1]
        controller.editImportCandidate(id: second.id)
        draft = second
        draft.description = "Lunch"
        controller.saveImportCandidate(draft)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importEditorError, "Duplicate of row 2 in this import.")
        XCTAssertEqual(controller.importCandidates[1].description, "Coffee")
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
    }

    func testLedgerlyEditsPreserveExportIdentityCurrencyAndDeletedStatus() async throws {
        let store = try SQLiteTestStore()
        let controller = makeController(store)
        let url = store.directory.appendingPathComponent("ledgerly.csv")
        let csv = """
        id,transaction_date,transaction_type,amount,currency,description,category,notes,deleted_at
        exported-id,2026-05-08,expense,4.50,USD,Coffee,Food,,2026-05-09T00:00:00Z
        """
        try csv.write(to: url, atomically: true, encoding: .utf8)
        controller.previewCSV(at: url, kind: .ledgerly)
        try await waitForImport(controller)
        let original = try XCTUnwrap(controller.importCandidates.first)
        controller.editImportCandidate(id: original.id)
        var draft = original
        draft.transactionType = .income
        draft.ledgerlyDetails?.transactionType = "income"
        draft.remarks = "  Edited remarks  "
        controller.saveImportCandidate(draft)
        try await waitForImport(controller)
        XCTAssertNil(controller.importEditorError)
        XCTAssertNil(controller.importEditorCandidate)
        controller.commitBulkImport()
        try await waitForImport(controller)
        let transaction = try XCTUnwrap(store.repository.transaction(id: "exported-id"))
        XCTAssertEqual(transaction.transactionType, .income)
        XCTAssertEqual(transaction.currency, "USD")
        XCTAssertEqual(transaction.deletedAt, "2026-05-09T00:00:00Z")
        XCTAssertEqual(transaction.notes, "  Edited remarks  ")
    }

    func testDeletingEditedRowClosesEditorAndUndoRestoresRow() async throws {
        let store = try SQLiteTestStore()
        let url = try debitCSV(["08 May 2026,ICT,Coffee,,,,Settled,4.50,,Food"], in: store)
        let controller = makeController(store)
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        let original = try XCTUnwrap(controller.importCandidates.first)
        controller.editImportCandidate(id: original.id)
        controller.commitBulkImport()
        XCTAssertNil(controller.bulkImportSummary)
        controller.removeImportRows([original.id])
        try await waitForImport(controller)
        XCTAssertNil(controller.importEditorCandidate)
        XCTAssertTrue(controller.importCandidates.isEmpty)
        controller.undoImportRowRemovals()
        try await waitForImport(controller)
        XCTAssertEqual(controller.importCandidates, [original])
        controller.editImportCandidate(id: original.id)
        controller.cancelBulkImport()
        XCTAssertNil(controller.importEditorCandidate)
        XCTAssertTrue(controller.importCandidates.isEmpty)
        controller.saveImportCandidate(original)
        XCTAssertFalse(controller.isImporting)
        XCTAssertTrue(controller.importCandidates.isEmpty)
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
