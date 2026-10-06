import Foundation
import XCTest
@testable import LedgerlyApp

final class TransactionCSVExporterTests: XCTestCase {
    func testEscapesFieldsPreservesUnicodeDatesStatusAndExactCents() {
        let row = TransactionListItem(
            id: "id", transactionDate: "2026-05-08", transactionType: .expense, amountCents: 123456,
            currency: "SGD", description: "Café, \"coffee\"", category: "Food & Dining",
            notes: "First line\nSecond line", deletedAt: "2026-05-09T00:00:00Z"
        )
        let csv = TransactionCSVExporter().csv([row])
        XCTAssertTrue(csv.hasPrefix("id,transaction_date,transaction_type,amount,currency,description,category,notes,deleted_at\r\n"))
        XCTAssertTrue(csv.contains("id,2026-05-08,expense,1234.56,SGD,\"Café, \"\"coffee\"\"\",Food & Dining,\"First line\nSecond line\",2026-05-09T00:00:00Z\r\n"))
    }

    func testEmptyExportHasHeaderAndNoDataRows() {
        XCTAssertEqual(TransactionCSVExporter().csv([]).components(separatedBy: "\r\n").count, 2)
    }

    func testLocalServiceWritesOnlyProvidedRowsInTheirOrderAndProtectsDatabase() async throws {
        let store = try SQLiteTestStore()
        try store.repository.save(TransactionFixture.make(id: "a", cents: 1))
        try store.repository.save(TransactionFixture.make(id: "b", cents: 100))
        let rows = try store.repository.transactions(includeDeleted: false).sorted { $0.id > $1.id }
        let service = LocalFileService(repository: store.repository)
        let destination = store.directory.appendingPathComponent("filtered.csv")
        try await service.export(rows, to: destination)
        let csv = try String(contentsOf: destination, encoding: .utf8)
        let lines = csv.components(separatedBy: "\r\n")
        XCTAssertTrue(lines[1].hasPrefix("b,"))
        XCTAssertTrue(lines[1].contains(",1.00,"))
        XCTAssertTrue(lines[2].hasPrefix("a,"))
        XCTAssertTrue(lines[2].contains(",0.01,"))
        do {
            try await service.export(rows, to: store.databaseURL)
            XCTFail("Export must not overwrite the active database")
        } catch {
            XCTAssertEqual(try store.repository.transactions(includeDeleted: true).count, 2)
        }
    }
}
