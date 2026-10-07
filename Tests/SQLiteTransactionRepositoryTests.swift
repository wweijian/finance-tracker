import Foundation
import XCTest
@testable import LedgerlyApp

final class SQLiteTransactionRepositoryTests: XCTestCase {
    func testCreateReadUpdateAndReopen() throws {
        let store = try SQLiteTestStore()
        var transaction = TransactionFixture.make(id: "first")
        transaction.notes = "Notes, quotes \" and a newline\n"
        try store.repository.save(transaction)
        XCTAssertEqual(try store.repository.transaction(id: transaction.id), transaction)
        transaction.amountCents = 12345
        transaction.description = "Changed description"
        transaction.updatedAt = "2026-06-01T03:00:00Z"
        try store.repository.save(transaction)
        let reopened = try SQLiteTransactionRepository(databaseURL: store.databaseURL, schemaURL: store.schemaURL)
        XCTAssertEqual(try reopened.transaction(id: transaction.id), transaction)
        XCTAssertEqual(try reopened.transactions(includeDeleted: false).count, 1)
        XCTAssertNil(try reopened.transaction(id: "missing"))
    }

    func testSoftDeleteAndRestorePreserveRowsAndDuplicateIdentity() throws {
        let store = try SQLiteTestStore()
        let transaction = TransactionFixture.make(id: "deleted", description: "Exact duplicate")
        try store.repository.save(transaction)
        try store.repository.softDelete(id: transaction.id)
        XCTAssertTrue(try store.repository.transactions(includeDeleted: false).isEmpty)
        XCTAssertEqual(try store.repository.transactions(includeDeleted: true).count, 1)
        let deleted = try XCTUnwrap(store.repository.transaction(id: transaction.id))
        XCTAssertNotNil(deleted.deletedAt)
        XCTAssertFalse(try store.repository.isDuplicate(date: transaction.transactionDate, amountCents: transaction.amountCents, description: transaction.description))
        XCTAssertThrowsError(try store.repository.save(TransactionFixture.make(description: transaction.description)))
        try store.repository.softDelete(id: transaction.id)
        XCTAssertEqual(try store.repository.transaction(id: transaction.id)?.deletedAt, deleted.deletedAt)
        try store.repository.restore(id: transaction.id)
        XCTAssertNil(try store.repository.transaction(id: transaction.id)?.deletedAt)
        XCTAssertEqual(try store.repository.transactions(includeDeleted: false).count, 1)
        XCTAssertTrue(try store.repository.isDuplicate(date: transaction.transactionDate, amountCents: transaction.amountCents, description: transaction.description))
    }

    func testReimportRestoresDeletedIdentityAndRollsBackEntireBatchOnFailure() throws {
        let store = try SQLiteTestStore()
        let original = TransactionFixture.make(id: "deleted", description: "Coffee", notes: "Original notes")
        try store.repository.save(original)
        try store.repository.softDelete(id: original.id)
        let deleted = try XCTUnwrap(store.repository.transaction(id: original.id))
        let replacement = TransactionFixture.make(id: "replacement", description: "Coffee", notes: "Reimported notes")
        var invalid = TransactionFixture.make(id: "invalid", description: "Invalid purchase")
        invalid.transactionYear = 2025

        XCTAssertThrowsError(try store.repository.insertIfNew([replacement, invalid]))
        XCTAssertEqual(try store.repository.transaction(id: original.id), deleted)
        XCTAssertEqual(try store.repository.transactions(includeDeleted: true).count, 1)

        XCTAssertEqual(try store.repository.insertIfNew([replacement, replacement]), [original.id])
        let restored = try XCTUnwrap(store.repository.transaction(id: original.id))
        XCTAssertNil(restored.deletedAt)
        XCTAssertEqual(restored.notes, "Reimported notes")
        XCTAssertEqual(restored.dateCreated, original.dateCreated)
        XCTAssertNil(try store.repository.transaction(id: replacement.id))
        XCTAssertEqual(try store.repository.transactions(includeDeleted: true).count, 1)
    }

    func testSQLiteEnforcesExactDateAmountDescriptionUniqueness() throws {
        let store = try SQLiteTestStore()
        try store.repository.save(TransactionFixture.make(id: "original", description: "Coffee"))
        XCTAssertThrowsError(try store.repository.save(TransactionFixture.make(id: "duplicate", description: "Coffee")))
        XCTAssertTrue(try store.repository.insertIfNew(TransactionFixture.make(id: "case", description: "coffee")))
        XCTAssertTrue(try store.repository.insertIfNew(TransactionFixture.make(id: "date", date: "2026-05-09", description: "Coffee")))
        XCTAssertTrue(try store.repository.insertIfNew(TransactionFixture.make(id: "amount", cents: 451, description: "Coffee")))
        XCTAssertEqual(try store.repository.transactions(includeDeleted: true).count, 4)
    }

    func testSchemaRejectsInvalidMoneyAndYear() throws {
        let store = try SQLiteTestStore()
        XCTAssertThrowsError(try store.repository.save(TransactionFixture.make(cents: -1)))
        var badYear = TransactionFixture.make()
        badYear.transactionYear = 2025
        XCTAssertThrowsError(try store.repository.save(badYear))
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
    }

    func testBatchDeleteOnlyTouchesRequestedRows() throws {
        let store = try SQLiteTestStore()
        for id in ["a", "b", "c"] { try store.repository.save(TransactionFixture.make(id: id)) }
        try store.repository.softDelete(ids: ["a", "b", "missing"])
        XCTAssertEqual(try store.repository.transactions(includeDeleted: false).map(\.id), ["c"])
        XCTAssertEqual(try store.repository.transactions(includeDeleted: true).count, 3)
    }
}
