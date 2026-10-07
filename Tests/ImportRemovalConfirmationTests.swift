import Foundation
import XCTest
@testable import LedgerlyApp

@MainActor
final class ImportRemovalConfirmationTests: XCTestCase {
    func testRequestAndCancelKeepRowsAndConfirmationRemovesOnlyRequestedRows() async throws {
        let store = try SQLiteTestStore()
        let controller = makeController(store)
        let url = try writeCSV(in: store)
        let originalFile = try Data(contentsOf: url)
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        let original = controller.importCandidates
        let requestedIDs = Set(original.prefix(2).map(\.id))

        controller.requestImportRowRemoval(requestedIDs.union(["unknown"]))
        XCTAssertEqual(controller.importRowRemovalIDs, requestedIDs)
        XCTAssertEqual(controller.importCandidates, original)
        XCTAssertEqual(controller.removedImportRowCount, 0)
        XCTAssertFalse(controller.isImporting)
        controller.commitBulkImport()
        XCTAssertNil(controller.bulkImportSummary)
        controller.importRowRemovalIDs = []
        XCTAssertEqual(controller.importCandidates, original)

        controller.requestImportRowRemoval(requestedIDs)
        let confirmedIDs = controller.importRowRemovalIDs
        // SwiftUI can clear the presentation binding before running the confirm button's action.
        controller.importRowRemovalIDs = []
        controller.confirmImportRowRemoval(confirmedIDs)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importCandidates, Array(original.suffix(1)))
        XCTAssertEqual(controller.removedImportRowCount, 2)
        XCTAssertTrue(controller.importRowRemovalIDs.isEmpty)
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
        XCTAssertEqual(try Data(contentsOf: url), originalFile)
        controller.undoImportRowRemovals()
        try await waitForImport(controller)
        XCTAssertEqual(controller.importCandidates, original)
    }

    func testEditorDeletionKeepsEditorOpenUntilConfirmed() async throws {
        let store = try SQLiteTestStore()
        let controller = makeController(store)
        controller.previewCSV(at: try writeCSV(in: store), kind: .debit)
        try await waitForImport(controller)
        let original = try XCTUnwrap(controller.importCandidates.first)
        controller.editImportCandidate(id: original.id)
        controller.requestImportRowRemoval([original.id])
        XCTAssertEqual(controller.importEditorCandidate, original)
        XCTAssertEqual(controller.importCandidates.count, 3)
        controller.importRowRemovalIDs = []
        XCTAssertEqual(controller.importEditorCandidate, original)
        controller.requestImportRowRemoval([original.id])
        controller.confirmImportRowRemoval(controller.importRowRemovalIDs)
        try await waitForImport(controller)
        XCTAssertNil(controller.importEditorCandidate)
        XCTAssertFalse(controller.importCandidates.contains { $0.id == original.id })
        XCTAssertEqual(controller.removedImportRowCount, 1)
    }

    func testChangingFileAndCancellingClearPendingDeletionAndUnknownRowsDoNothing() async throws {
        let store = try SQLiteTestStore()
        let controller = makeController(store)
        let url = try writeCSV(in: store)
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        controller.requestImportRowRemoval(["unknown"])
        XCTAssertTrue(controller.importRowRemovalIDs.isEmpty)
        let oldIDs = Set(controller.importCandidates.map(\.id))
        controller.requestImportRowRemoval(oldIDs)
        controller.previewCSV(at: url, kind: .debit)
        XCTAssertTrue(controller.importRowRemovalIDs.isEmpty)
        try await waitForImport(controller)
        controller.confirmImportRowRemoval(oldIDs)
        XCTAssertEqual(controller.importCandidates.count, 3)
        XCTAssertEqual(controller.removedImportRowCount, 0)
        controller.requestImportRowRemoval(Set(controller.importCandidates.map(\.id)))
        controller.cancelBulkImport()
        XCTAssertTrue(controller.importRowRemovalIDs.isEmpty)
        XCTAssertTrue(controller.importCandidates.isEmpty)
    }

    private func makeController(_ store: SQLiteTestStore) -> TransactionsController {
        TransactionsController(service: TransactionService(repository: store.repository),
                               bulkImportService: BulkImportService(repository: store.repository))
    }

    private func writeCSV(in store: SQLiteTestStore) throws -> URL {
        let url = store.directory.appendingPathComponent("import.csv")
        let csv = """
        Transaction Date,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount,Category
        08 May 2026,ICT,Coffee,,,,Settled,4.50,,Food
        09 May 2026,ICT,Lunch,,,,Settled,8.00,,Food
        10 May 2026,ICT,Dinner,,,,Settled,12.00,,Food
        """
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func waitForImport(_ controller: TransactionsController) async throws {
        let deadline = Date().addingTimeInterval(3)
        while controller.isImporting && Date() < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertFalse(controller.isImporting)
        XCTAssertNil(controller.bulkImportError)
    }
}
