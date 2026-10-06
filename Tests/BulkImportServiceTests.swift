import Foundation
import XCTest
@testable import LedgerlyApp

final class BulkImportServiceTests: XCTestCase {
    private var directoryURL: URL!
    private var repository: SQLiteTransactionRepository!
    private var service: BulkImportService!

    override func setUpWithError() throws {
        directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let schemaURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/schema.sql")
        repository = try SQLiteTransactionRepository(
            databaseURL: directoryURL.appendingPathComponent("test.sqlite"),
            schemaURL: schemaURL
        )
        service = BulkImportService(repository: repository)
    }

    override func tearDownWithError() throws {
        service = nil
        repository = nil
        if let directoryURL {
            try FileManager.default.removeItem(at: directoryURL)
        }
    }

    func testCountsInvalidAndDuplicateRowsAsRejected() async throws {
        let existing = transaction(id: "existing", description: "Existing purchase")
        try repository.save(existing)
        let candidates = try await service.validate([
            candidate(row: 2, description: "New purchase"),
            candidate(row: 3, description: "New purchase"),
            candidate(row: 4, description: "Existing purchase"),
            candidate(row: 5, description: "Invalid purchase", category: "Unknown")
        ], categories: ["Food & Dining"])

        let summary = try await service.commit(candidates, categories: ["Food & Dining"])

        XCTAssertEqual(summary.acceptedCount, 1)
        XCTAssertEqual(summary.rejectedCount, 3)
        XCTAssertEqual(try repository.transactions(includeDeleted: false).count, 2)
    }

    func testCountsDuplicatesAddedAfterPreviewAsRejected() async throws {
        let candidates = try await service.validate([
            candidate(row: 2, description: "Existing purchase"),
            candidate(row: 3, description: "New purchase")
        ], categories: ["Food & Dining"])
        try repository.save(transaction(id: "existing", description: "Existing purchase"))

        let summary = try await service.commit(candidates, categories: ["Food & Dining"])

        XCTAssertEqual(summary.acceptedCount, 1)
        XCTAssertEqual(summary.rejectedCount, 1)
        XCTAssertFalse(summary.importedTransactionIDs.contains("existing"))
    }

    func testUndoSoftDeletesOnlyRowsFromThisImport() async throws {
        try repository.save(transaction(id: "existing", description: "Existing purchase"))
        let summary = try await service.commit([
            candidate(row: 2, description: "First import purchase"),
            candidate(row: 3, description: "Second import purchase"),
            candidate(row: 4, description: "Existing purchase")
        ], categories: ["Food & Dining"])
        let laterImport = try await service.commit([
            candidate(row: 5, description: "Later import purchase")
        ], categories: ["Food & Dining"])

        try await service.undo(summary)

        let activeIDs = Set(try repository.transactions(includeDeleted: false).map(\.id))
        XCTAssertEqual(activeIDs, Set(["existing"] + laterImport.importedTransactionIDs))
        XCTAssertEqual(try repository.transactions(includeDeleted: true).count, 4)
        for id in summary.importedTransactionIDs {
            let imported = try XCTUnwrap(repository.transaction(id: id))
            XCTAssertNotNil(imported.deletedAt)
        }
        XCTAssertNil(try repository.transaction(id: "existing")?.deletedAt)

        try await service.undo(summary)
        XCTAssertEqual(try repository.transactions(includeDeleted: false).count, 2)
    }

    func testEmptyImportHasNothingToUndo() async throws {
        try repository.save(transaction(id: "existing", description: "Existing purchase"))
        let summary = try await service.commit([
            candidate(row: 2, description: "Existing purchase")
        ], categories: ["Food & Dining"])

        XCTAssertEqual(summary.acceptedCount, 0)
        XCTAssertEqual(summary.rejectedCount, 1)
        try await service.undo(summary)
        XCTAssertEqual(try repository.transactions(includeDeleted: false).map(\.id), ["existing"])
    }

    func testFailedBatchRollsBackEveryImportedRow() throws {
        let valid = transaction(id: "valid", description: "Valid purchase")
        var invalid = transaction(id: "invalid", description: "Invalid purchase")
        invalid.transactionYear = 2025

        XCTAssertThrowsError(try repository.insertIfNew([valid, invalid]))
        XCTAssertTrue(try repository.transactions(includeDeleted: true).isEmpty)
    }

    func testPreviewDoesNotWriteAndCommitCanonicalizesCategoriesWithoutChangingCSV() async throws {
        let url = directoryURL.appendingPathComponent("debit.csv")
        let csv = #"""
        Transaction Date,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount,Category
        08 May 2026,ICT,"Coffee, ""quoted""",,,,Settled,4.50,,food & dining
        09 May 2026,ICT,Salary,,,,Settled,,1234.56,Food & Dining
        10 May 2026,ICT,Unknown category,,,,Settled,1.00,,Unknown
        """#
        try csv.write(to: url, atomically: true, encoding: .utf8)
        let original = try Data(contentsOf: url)
        let candidates = try await service.previewFile(at: url, kind: .debit, categories: ["Food & Dining"])
        XCTAssertEqual(candidates.count, 3)
        XCTAssertEqual(candidates[0].category, "Food & Dining")
        XCTAssertEqual(candidates[1].transactionType, .income)
        XCTAssertNotNil(candidates[2].rejectionReason)
        XCTAssertTrue(try repository.transactions(includeDeleted: true).isEmpty)
        let summary = try await service.commit(candidates, categories: ["Food & Dining"])
        XCTAssertEqual(summary.acceptedCount, 2)
        XCTAssertEqual(summary.rejectedCount, 1)
        XCTAssertEqual(try Data(contentsOf: url), original)
        XCTAssertEqual(try repository.transactions(includeDeleted: false).first { $0.transactionType == .income }?.amountCents, 123456)
    }

    func testRejectedRowsCanBeCorrectedAndRevalidated() async throws {
        var invalidDate = candidate(row: 2, description: "Bad date")
        invalidDate.transactionDate = "2026-02-30"
        var invalidAmount = candidate(row: 3, description: "Bad amount")
        invalidAmount.amount = "4.50oops"
        var blankDescription = candidate(row: 4, description: "   ")
        let invalid = try await service.validate([invalidDate, invalidAmount, blankDescription], categories: ["Food & Dining"])
        XCTAssertTrue(invalid.allSatisfy { !$0.isReady })
        invalidDate.transactionDate = "2026-02-28"
        invalidAmount.amount = "4.50"
        blankDescription.description = "Fixed description"
        let corrected = try await service.validate([invalidDate, invalidAmount, blankDescription], categories: ["Food & Dining"])
        XCTAssertTrue(corrected.allSatisfy(\.isReady))
        let summary = try await service.commit(corrected, categories: ["Food & Dining"])
        XCTAssertEqual(summary.acceptedCount, 3)
        XCTAssertEqual(summary.rejectedCount, 0)
    }

    func testCommitRevalidatesRowsChangedAfterPreview() async throws {
        var candidates = try await service.validate([
            candidate(row: 2, description: "New purchase"),
            candidate(row: 3, description: "Changed purchase")
        ], categories: ["Food & Dining"])
        candidates[1].category = "Unknown"
        let summary = try await service.commit(candidates, categories: ["Food & Dining"])
        XCTAssertEqual(summary.acceptedCount, 1)
        XCTAssertEqual(summary.rejectedCount, 1)
    }

    func testBatchRemarksAreOptionalAndSurviveCSVPreviewAndCommit() async throws {
        let url = directoryURL.appendingPathComponent("with-remarks.csv")
        let csv = #"""
        Transaction Date,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount,Category,Remarks
        08 May 2026,ICT,Coffee shop,,,,Settled,4.50,,Food & Dining,"Receipt, saved"
        09 May 2026,ICT,Lunch,,,,Settled,8.00,,Food & Dining,
        """#
        try csv.write(to: url, atomically: true, encoding: .utf8)
        let source = try Data(contentsOf: url)
        var preview = try await service.previewFile(at: url, kind: .debit, categories: ["Food & Dining"])
        XCTAssertTrue(preview.allSatisfy(\.isReady))
        XCTAssertEqual(preview[0].remarks, "Receipt, saved")
        XCTAssertEqual(preview[1].remarks, "")
        preview[0].remarks = "  Reimbursable\nReceipt saved  "
        let summary = try await service.commit(preview, categories: ["Food & Dining"])
        XCTAssertEqual(summary.acceptedCount, 2)
        let transactions = try repository.transactions(includeDeleted: false)
        XCTAssertEqual(transactions.first { $0.description == "Coffee shop" }?.notes, "Reimbursable\nReceipt saved")
        XCTAssertNil(transactions.first { $0.description == "Lunch" }?.notes)
        XCTAssertEqual(try Data(contentsOf: url), source)
    }

    func testDifferentRemarksStillCountAsTheSameDuplicateTransaction() async throws {
        var first = candidate(row: 2, description: "Coffee")
        first.remarks = "First remark"
        var second = candidate(row: 3, description: "Coffee")
        second.remarks = "Different remark"
        let validated = try await service.validate([first, second], categories: ["Food & Dining"])
        XCTAssertTrue(validated[0].isReady)
        XCTAssertFalse(validated[1].isReady)
        let summary = try await service.commit(validated, categories: ["Food & Dining"])
        XCTAssertEqual(summary.acceptedCount, 1)
        XCTAssertEqual(summary.rejectedCount, 1)
    }

    private func candidate(
        row: Int,
        description: String,
        category: String = "Food & Dining"
    ) -> ImportCandidate {
        ImportCandidate(
            id: UUID().uuidString,
            sourceRow: row,
            transactionDate: "2026-05-08",
            transactionType: .expense,
            amount: "4.50",
            description: description,
            category: category,
            rejectionReason: nil
        )
    }

    private func transaction(id: String, description: String) -> FinanceTransaction {
        FinanceTransaction(
            id: id,
            transactionDate: "2026-05-08",
            transactionYear: 2026,
            transactionType: .expense,
            amountCents: 450,
            currency: "SGD",
            description: description,
            category: "Food & Dining",
            notes: nil,
            dateCreated: "2026-05-08T00:00:00Z",
            updatedAt: "2026-05-08T00:00:00Z",
            deletedAt: nil
        )
    }
}
