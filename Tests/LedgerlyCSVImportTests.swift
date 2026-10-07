import Foundation
import XCTest
@testable import LedgerlyApp

final class LedgerlyCSVImportTests: XCTestCase {
    private let categories = ["Food & Dining"]

    func testExportImportsIntoFreshDatabaseWithoutLosingExportedFields() async throws {
        let source = try SQLiteTestStore()
        try source.repository.save(TransactionFixture.make(
            id: "expense", cents: 123456, description: "  Café, \"coffee\"  ",
            notes: "  Receipt saved\r\nSecond line  "
        ))
        var income = TransactionFixture.make(id: "income", type: .income, cents: 0, notes: nil)
        income.currency = "USD"
        try source.repository.save(income)
        try source.repository.save(TransactionFixture.make(
            id: "deleted", cents: 1, deletedAt: "2026-05-09T00:00:00.123Z", notes: "Deleted remark"
        ))
        let exportedRows = try source.repository.transactions(includeDeleted: true)
        let url = source.directory.appendingPathComponent("ledgerly.csv")
        try TransactionCSVExporter().csv(exportedRows).write(to: url, atomically: true, encoding: .utf8)
        let original = try Data(contentsOf: url)

        let destination = try SQLiteTestStore()
        let service = BulkImportService(repository: destination.repository)
        let preview = try await service.previewFile(at: url, kind: .ledgerly, categories: categories)
        XCTAssertEqual(preview.count, 3)
        XCTAssertTrue(preview.allSatisfy(\.isReady))
        XCTAssertEqual(preview.first { $0.ledgerlyDetails?.transactionID == "deleted" }?.statusLabel, "Ready · Deleted")
        XCTAssertTrue(try destination.repository.transactions(includeDeleted: true).isEmpty)

        let summary = try await service.commit(preview, categories: categories)
        XCTAssertEqual(summary.acceptedCount, 3)
        XCTAssertEqual(summary.rejectedCount, 0)
        XCTAssertEqual(Set(summary.importedTransactionIDs), Set(exportedRows.map(\.id)))
        XCTAssertEqual(
            try destination.repository.transactions(includeDeleted: true).sorted { $0.id < $1.id },
            exportedRows.sorted { $0.id < $1.id }
        )
        XCTAssertEqual(try destination.repository.transactions(includeDeleted: false).count, 2)
        XCTAssertEqual(try Data(contentsOf: url), original)

        let repeatedPreview = try await service.previewFile(at: url, kind: .ledgerly, categories: categories)
        XCTAssertTrue(repeatedPreview.allSatisfy { !$0.isReady })
        let repeatedSummary = try await service.commit(repeatedPreview, categories: categories)
        XCTAssertEqual(repeatedSummary.acceptedCount, 0)
        XCTAssertEqual(repeatedSummary.rejectedCount, 3)

        try await service.undo(summary)
        XCTAssertTrue(try destination.repository.transactions(includeDeleted: false).isEmpty)
        XCTAssertEqual(try destination.repository.transaction(id: "deleted")?.deletedAt, "2026-05-09T00:00:00.123Z")
        let retry = try await service.previewFile(at: url, kind: .ledgerly, categories: categories)
        XCTAssertEqual(retry.filter(\.isReady).count, 2)
        let retrySummary = try await service.commit(retry, categories: categories)
        XCTAssertEqual(retrySummary.acceptedCount, 2)
        XCTAssertEqual(try destination.repository.transactions(includeDeleted: true).count, 3)
    }

    func testInvalidLedgerlyFieldsAreRejectedInPreviewAndCommit() async throws {
        let store = try SQLiteTestStore()
        let service = BulkImportService(repository: store.repository)
        let csv = """
        id,transaction_date,transaction_type,amount,currency,description,category,notes,deleted_at
        ,2026-05-08,expense,4.50,SGD,Missing ID,Food & Dining,,
        type,2026-05-08,transfer,4.50,SGD,Invalid type,Food & Dining,,
        currency,2026-05-08,income,4.50,,Missing currency,Food & Dining,,
        deleted,2026-05-08,expense,4.50,SGD,Invalid status,Food & Dining,,not-a-timestamp
        timezone,2026-05-08,expense,4.50,SGD,Non UTC status,Food & Dining,,2026-05-09T08:00:00+08:00
        amount,2026-05-08,expense,4.501,SGD,Invalid amount,Food & Dining,,
        category,2026-05-08,expense,4.50,SGD,Invalid category,Unknown,,
        date,2026-02-30,expense,4.50,SGD,Invalid date,Food & Dining,,
        valid,2026-05-08,income,4.50,SGD,Valid row,food & dining,,
        """
        let url = try write(csv, in: store)
        let preview = try await service.previewFile(at: url, kind: .ledgerly, categories: categories)
        XCTAssertEqual(preview.count, 9)
        XCTAssertTrue(preview.dropLast().allSatisfy { !$0.isReady })
        XCTAssertTrue(try XCTUnwrap(preview.last).isReady)
        XCTAssertEqual(preview.last?.category, "Food & Dining")
        let summary = try await service.commit(preview, categories: categories)
        XCTAssertEqual(summary.importedTransactionIDs, ["valid"])
        XCTAssertEqual(summary.rejectedCount, 8)
        XCTAssertEqual(try store.repository.transactions(includeDeleted: true).count, 1)
    }

    func testRepeatedIDsAndExactRowsAreRejectedWithinFile() async throws {
        let store = try SQLiteTestStore()
        let service = BulkImportService(repository: store.repository)
        let csv = """
        id,transaction_date,transaction_type,amount,currency,description,category,notes,deleted_at
        first,2026-05-08,expense,4.50,SGD,Coffee,Food & Dining,,
        first,2026-05-08,expense,8.00,SGD,Lunch,Food & Dining,,
        second,2026-05-08,expense,4.50,SGD,Coffee,Food & Dining,Different notes,
        """
        let url = try write(csv, in: store)
        let preview = try await service.previewFile(at: url, kind: .ledgerly, categories: categories)
        XCTAssertTrue(preview[0].isReady)
        XCTAssertEqual(preview[1].rejectionReason, "Transaction ID is repeated from row 2 in this import.")
        XCTAssertEqual(preview[2].rejectionReason, "Duplicate of row 2 in this import.")
        let summary = try await service.commit(preview, categories: categories)
        XCTAssertEqual(summary.importedTransactionIDs, ["first"])
        XCTAssertEqual(summary.rejectedCount, 2)
    }

    func testExistingIDConflictIsRejectedWithoutOverwritingExistingTransaction() async throws {
        let store = try SQLiteTestStore()
        let existing = TransactionFixture.make(id: "existing", description: "Original")
        try store.repository.save(existing)
        let service = BulkImportService(repository: store.repository)
        let csv = """
        id,transaction_date,transaction_type,amount,currency,description,category,notes,deleted_at
        existing,2026-05-08,expense,4.50,SGD,Different transaction,Food & Dining,,
        """
        let url = try write(csv, in: store)
        let preview = try await service.previewFile(at: url, kind: .ledgerly, categories: categories)
        XCTAssertEqual(preview.first?.rejectionReason, "Transaction ID belongs to a different existing transaction.")
        let summary = try await service.commit(preview, categories: categories)
        XCTAssertEqual(summary.acceptedCount, 0)
        XCTAssertEqual(try store.repository.transaction(id: "existing"), existing)
    }

    func testIDConflictAddedAfterPreviewIsSkippedAndOtherRowsImport() async throws {
        let store = try SQLiteTestStore()
        let service = BulkImportService(repository: store.repository)
        let csv = """
        id,transaction_date,transaction_type,amount,currency,description,category,notes,deleted_at
        conflict,2026-05-08,expense,4.50,SGD,Coffee,Food & Dining,,
        new,2026-05-08,income,10.00,SGD,Refund,Food & Dining,,
        """
        let url = try write(csv, in: store)
        let preview = try await service.previewFile(at: url, kind: .ledgerly, categories: categories)
        XCTAssertTrue(preview.allSatisfy(\.isReady))
        try store.repository.save(TransactionFixture.make(id: "conflict", description: "Another transaction"))
        let summary = try await service.commit(preview, categories: categories)
        XCTAssertEqual(summary.importedTransactionIDs, ["new"])
        XCTAssertEqual(summary.rejectedCount, 1)
        XCTAssertEqual(try store.repository.transaction(id: "conflict")?.description, "Another transaction")
    }

    func testRequiresExportHeadersAndReportsLedgerlyHeaderOnFormatMismatch() throws {
        let store = try SQLiteTestStore()
        let exporter = TransactionCSVExporter()
        let url = try write(exporter.csv([]), in: store)
        XCTAssertTrue(try CSVTransactionParser().parse(url: url, kind: .ledgerly).candidates.isEmpty)
        XCTAssertThrowsError(try CSVTransactionParser().parse(url: url, kind: .debit)) { error in
            XCTAssertTrue(error.localizedDescription.contains("transaction_date"))
        }
        let missingHeader = try write(exporter.csv([]).replacingOccurrences(of: ",notes", with: ""), in: store)
        XCTAssertThrowsError(try CSVTransactionParser().parse(url: missingHeader, kind: .ledgerly))
        let duplicateHeader = try write(exporter.csv([]).replacingOccurrences(of: ",notes", with: ",notes,notes"), in: store)
        XCTAssertThrowsError(try CSVTransactionParser().parse(url: duplicateHeader, kind: .ledgerly))
    }

    private func write(_ csv: String, in store: SQLiteTestStore) throws -> URL {
        let url = store.directory.appendingPathComponent("\(UUID().uuidString).csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
