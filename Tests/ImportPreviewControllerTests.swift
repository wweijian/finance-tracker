import Foundation
import XCTest
@testable import LedgerlyApp

@MainActor
final class ImportPreviewControllerTests: XCTestCase {
    func testRemoveNeedsAttentionRowsAndCommitOnlyRemainingRowsWithoutChangingCSV() async throws {
        let store = try SQLiteTestStore()
        let url = try writeCSV([
            "08 May 2026,ICT,Coffee,,,,Settled,4.50,,Food",
            "09 May 2026,ICT,Lunch,,,,Settled,8.00,,Unknown",
            "08 May 2026,ICT,Coffee,,,,Settled,4.50,,Food"
        ], in: store)
        let originalCSV = try Data(contentsOf: url)
        let controller = makeController(store)
        controller.presentBulkImport()
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importPreview.readyCount, 1)
        XCTAssertEqual(controller.importPreview.rejectedCount, 2)
        let unwanted = Set(controller.importPreview.rows(matching: .needsAttention).map(\.id))
        controller.removeImportRows(unwanted)
        XCTAssertTrue(controller.isImporting)
        controller.commitBulkImport()
        controller.undoImportRowRemovals()
        XCTAssertNil(controller.bulkImportSummary)
        XCTAssertEqual(controller.removedImportRowCount, 2)
        try await waitForImport(controller)
        XCTAssertEqual(controller.importPreview.rejectedCount, 0)
        XCTAssertEqual(controller.importPreview.readyCount, 1)
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
        controller.commitBulkImport()
        try await waitForImport(controller)
        XCTAssertEqual(controller.bulkImportSummary?.acceptedCount, 1)
        XCTAssertEqual(controller.bulkImportSummary?.rejectedCount, 0)
        XCTAssertEqual(try store.repository.transactions(includeDeleted: true).map(\.description), ["Coffee"])
        XCTAssertEqual(try Data(contentsOf: url), originalCSV)
        controller.undoImportRowRemovals()
        XCTAssertTrue(controller.importCandidates.isEmpty)
    }

    func testRemovingEarlierDuplicatePromotesLaterRowAndUndoRevalidatesBoth() async throws {
        let store = try SQLiteTestStore()
        let url = try writeCSV([
            "08 May 2026,ICT,Coffee,,,,Settled,4.50,,Food",
            "08 May 2026,ICT,Coffee,,,,Settled,4.50,,Food"
        ], in: store)
        let controller = makeController(store)
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        let originalIDs = controller.importCandidates.map(\.id)
        controller.removeImportRows([originalIDs[0]])
        try await waitForImport(controller)
        XCTAssertEqual(controller.importCandidates.map(\.id), [originalIDs[1]])
        XCTAssertEqual(controller.importPreview.readyCount, 1)
        XCTAssertEqual(controller.importPreview.rejectedCount, 0)
        var edited = try XCTUnwrap(controller.importCandidates.first)
        edited.remarks = "Keep this remark"
        controller.revalidate(edited)
        try await waitForImport(controller)
        controller.undoImportRowRemovals()
        try await waitForImport(controller)
        XCTAssertEqual(controller.importCandidates.map(\.id), originalIDs)
        XCTAssertEqual(controller.importCandidates.map(\.sourceRow), [2, 3])
        XCTAssertEqual(controller.importCandidates.last?.remarks, "Keep this remark")
        XCTAssertEqual(controller.importPreview.readyCount, 1)
        XCTAssertEqual(controller.importPreview.rejectedCount, 1)
        XCTAssertEqual(controller.removedImportRowCount, 0)
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
    }

    func testRemovingAllRowsLeavesAnUndoableEmptyPreviewAndCannotCommit() async throws {
        let store = try SQLiteTestStore()
        let url = try writeCSV(["08 May 2026,ICT,Coffee,,,,Settled,4.50,,Unknown"], in: store)
        let controller = makeController(store)
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        controller.removeImportRows(["unknown-id"])
        XCTAssertFalse(controller.isImporting)
        XCTAssertEqual(controller.removedImportRowCount, 0)
        controller.removeImportRows(Set(controller.importCandidates.map(\.id)))
        try await waitForImport(controller)
        XCTAssertTrue(controller.importCandidates.isEmpty)
        XCTAssertEqual(controller.removedImportRowCount, 1)
        XCTAssertNil(controller.bulkImportError)
        controller.commitBulkImport()
        XCTAssertNil(controller.bulkImportSummary)
        controller.undoImportRowRemovals()
        try await waitForImport(controller)
        XCTAssertEqual(controller.importPreview.rejectedCount, 1)
        XCTAssertEqual(controller.removedImportRowCount, 0)
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
    }

    func testChangingFileAndCancellingClearRemovalHistory() async throws {
        let store = try SQLiteTestStore()
        let first = try writeCSV(["08 May 2026,ICT,Coffee,,,,Settled,4.50,,Unknown"], in: store)
        let second = try writeCSV(["09 May 2026,ICT,Lunch,,,,Settled,8.00,,Food"], in: store)
        let controller = makeController(store)
        controller.previewCSV(at: first, kind: .debit)
        try await waitForImport(controller)
        controller.removeImportRows(Set(controller.importCandidates.map(\.id)))
        try await waitForImport(controller)
        XCTAssertEqual(controller.removedImportRowCount, 1)
        controller.previewCSV(at: second, kind: .debit)
        XCTAssertEqual(controller.removedImportRowCount, 0)
        try await waitForImport(controller)
        controller.undoImportRowRemovals()
        XCTAssertEqual(controller.importCandidates.map(\.description), ["Lunch"])
        controller.removeImportRows(Set(controller.importCandidates.map(\.id)))
        try await waitForImport(controller)
        controller.cancelBulkImport()
        XCTAssertEqual(controller.removedImportRowCount, 0)
        XCTAssertTrue(controller.importCandidates.isEmpty)
        controller.undoImportRowRemovals()
        XCTAssertTrue(controller.importCandidates.isEmpty)
    }

    private func makeController(_ store: SQLiteTestStore) -> TransactionsController {
        TransactionsController(service: TransactionService(repository: store.repository),
                               bulkImportService: BulkImportService(repository: store.repository))
    }

    private func writeCSV(_ rows: [String], in store: SQLiteTestStore) throws -> URL {
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
