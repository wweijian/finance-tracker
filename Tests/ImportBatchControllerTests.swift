import Foundation
import XCTest
@testable import LedgerlyApp

@MainActor
final class ImportBatchControllerTests: XCTestCase {
    func testImportWritesImmediatelyAndClosingSuccessKeepsDataAfterReopeningDatabase() async throws {
        let store = try SQLiteTestStore()
        let controller = makeController(store)
        let url = try writeCSV(in: store)
        let originalCSV = try Data(contentsOf: url)
        try await importCSV(url, using: controller)
        let summary = try XCTUnwrap(controller.bulkImportSummary)
        XCTAssertEqual(summary.acceptedCount, 1)
        XCTAssertEqual(try store.repository.transactions(includeDeleted: false).map(\.id), summary.importedTransactionIDs)
        XCTAssertTrue(controller.importCandidates.isEmpty)
        XCTAssertEqual(controller.dataRevision, 1)

        controller.cancelBulkImport()
        XCTAssertNil(controller.bulkImportSummary)
        let reopened = try SQLiteTransactionRepository(databaseURL: store.databaseURL, schemaURL: store.schemaURL)
        XCTAssertEqual(try reopened.transactions(includeDeleted: false).map(\.id), summary.importedTransactionIDs)
        controller.undoBulkImport()
        XCTAssertEqual(try reopened.transactions(includeDeleted: false).count, 1)
        XCTAssertEqual(try Data(contentsOf: url), originalCSV)
    }

    func testUndoRemovesOnlyImportedBatchAndSameFileCanBeImportedAgain() async throws {
        let store = try SQLiteTestStore()
        let existing = TransactionFixture.make(id: "existing", description: "Existing purchase")
        try store.repository.save(existing)
        let controller = makeController(store)
        let url = try writeCSV(in: store)
        try await importCSV(url, using: controller)
        let importedIDs = try XCTUnwrap(controller.bulkImportSummary).importedTransactionIDs
        let later = TransactionFixture.make(id: "later", description: "Later purchase")
        try store.repository.save(later)

        controller.undoBulkImport()
        try await waitForImport(controller)
        XCTAssertFalse(controller.isShowingBulkImport)
        XCTAssertNil(controller.bulkImportSummary)
        XCTAssertTrue(controller.importCandidates.isEmpty)
        XCTAssertEqual(Set(try store.repository.transactions(includeDeleted: false).map(\.id)), [existing.id, later.id])
        XCTAssertEqual(try store.repository.transaction(id: existing.id), existing)
        XCTAssertEqual(try store.repository.transaction(id: later.id), later)

        controller.presentBulkImport()
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importPreview.readyCount, 1)
        XCTAssertEqual(controller.importPreview.rejectedCount, 0)
        controller.commitBulkImport()
        try await waitForImport(controller)
        XCTAssertEqual(controller.bulkImportSummary?.importedTransactionIDs, importedIDs)
        XCTAssertEqual(try store.repository.transactions(includeDeleted: true).count, 3)
        XCTAssertEqual(try store.repository.transactions(includeDeleted: false).count, 3)
        controller.undoBulkImport()
        try await waitForImport(controller)
        XCTAssertEqual(Set(try store.repository.transactions(includeDeleted: false).map(\.id)), [existing.id, later.id])
        XCTAssertEqual(controller.dataRevision, 4)
    }

    func testUndoAfterSecondImportKeepsFirstCompletedBatchAndSkippedDuplicates() async throws {
        let store = try SQLiteTestStore()
        let controller = makeController(store)
        let firstFile = try writeCSV(in: store)
        try await importCSV(firstFile, using: controller)
        let firstIDs = try XCTUnwrap(controller.bulkImportSummary).importedTransactionIDs
        controller.cancelBulkImport()
        let secondFile = try writeCSV(in: store, rows: [
            "08 May 2026,ICT,Coffee shop,,,,Settled,4.50,,Food",
            "09 May 2026,ICT,Lunch,,,,Settled,8.00,,Food"
        ])
        try await importCSV(secondFile, using: controller)
        let secondSummary = try XCTUnwrap(controller.bulkImportSummary)
        XCTAssertEqual(secondSummary.acceptedCount, 1)
        XCTAssertEqual(secondSummary.rejectedCount, 1)
        XCTAssertTrue(Set(firstIDs).isDisjoint(with: secondSummary.importedTransactionIDs))
        controller.undoBulkImport()
        try await waitForImport(controller)
        XCTAssertEqual(try store.repository.transactions(includeDeleted: false).map(\.id), firstIDs)
    }

    func testCommitRechecksDuplicatesAddedAfterPreviewWithoutUndoingThem() async throws {
        let store = try SQLiteTestStore()
        let controller = makeController(store)
        let url = try writeCSV(in: store)
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importPreview.readyCount, 1)
        let existing = TransactionFixture.make(id: "existing", category: "Food", description: "Coffee shop")
        try store.repository.save(existing)
        controller.commitBulkImport()
        try await waitForImport(controller)
        XCTAssertEqual(controller.bulkImportSummary?.acceptedCount, 0)
        XCTAssertEqual(controller.bulkImportSummary?.rejectedCount, 1)
        controller.undoBulkImport()
        XCTAssertEqual(try store.repository.transactions(includeDeleted: true).map(\.id), [existing.id])
        XCTAssertEqual(try store.repository.transaction(id: existing.id), existing)
    }

    private func makeController(_ store: SQLiteTestStore) -> TransactionsController {
        TransactionsController(service: TransactionService(repository: store.repository),
                               bulkImportService: BulkImportService(repository: store.repository))
    }

    private func writeCSV(in store: SQLiteTestStore,
                          rows: [String] = ["08 May 2026,ICT,Coffee shop,,,,Settled,4.50,,Food"]) throws -> URL {
        let url = store.directory.appendingPathComponent("\(UUID().uuidString).csv")
        let header = "Transaction Date,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount,Category"
        try ([header] + rows).joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func importCSV(_ url: URL, using controller: TransactionsController) async throws {
        controller.presentBulkImport()
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        controller.commitBulkImport()
        try await waitForImport(controller)
    }

    private func waitForImport(_ controller: TransactionsController) async throws {
        let deadline = Date().addingTimeInterval(3)
        while controller.isImporting && Date() < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertFalse(controller.isImporting)
        XCTAssertNil(controller.bulkImportError)
    }
}
