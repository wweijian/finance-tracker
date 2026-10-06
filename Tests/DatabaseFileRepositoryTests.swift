import Foundation
import GRDB
import XCTest
@testable import LedgerlyApp

final class DatabaseFileRepositoryTests: XCTestCase {
    func testBackupRestoreIncludesDeletedRowsAndAllowsFurtherWrites() throws {
        let store = try SQLiteTestStore()
        let first = TransactionFixture.make(id: "first")
        let deleted = TransactionFixture.make(id: "deleted", deletedAt: "2026-05-09T00:00:00Z")
        try store.repository.save(first)
        try store.repository.save(deleted)
        let backup = store.directory.appendingPathComponent("backup.sqlite")
        try store.repository.backUp(to: backup)
        XCTAssertEqual(try store.repository.validateBackup(at: backup), 2)
        try store.repository.save(TransactionFixture.make(id: "later"))
        try store.repository.softDelete(id: "first")
        try store.repository.restoreDatabase(from: backup)
        XCTAssertEqual(try store.repository.transaction(id: "first"), first)
        XCTAssertEqual(try store.repository.transaction(id: "deleted"), deleted)
        XCTAssertNil(try store.repository.transaction(id: "later"))
        try store.repository.save(TransactionFixture.make(id: "after-restore"))
        XCTAssertEqual(try store.repository.transactions(includeDeleted: true).count, 3)
        let reopened = try SQLiteTransactionRepository(databaseURL: store.databaseURL, schemaURL: store.schemaURL)
        XCTAssertEqual(try reopened.transactions(includeDeleted: true).count, 3)
    }

    func testBackupCapturesCommittedWALAndCanReplacePreviousBackup() throws {
        let store = try SQLiteTestStore()
        let connection = try DatabaseQueue(path: store.databaseURL.path)
        try connection.writeWithoutTransaction { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }
        try store.repository.save(TransactionFixture.make(id: "first"))
        let backup = store.directory.appendingPathComponent("wal-backup.sqlite")
        try store.repository.backUp(to: backup)
        try store.repository.save(TransactionFixture.make(id: "second"))
        XCTAssertEqual(try store.repository.validateBackup(at: backup), 1)
        try store.repository.backUp(to: backup)
        XCTAssertEqual(try store.repository.validateBackup(at: backup), 2)
        XCTAssertFalse(FileManager.default.fileExists(atPath: backup.path + "-wal"))
        try connection.close()
    }

    func testInvalidBackupsLeaveCurrentDatabaseUntouched() throws {
        let store = try SQLiteTestStore()
        let original = TransactionFixture.make(id: "original")
        try store.repository.save(original)
        let corrupt = store.directory.appendingPathComponent("corrupt.sqlite")
        try "not a database".write(to: corrupt, atomically: true, encoding: .utf8)
        XCTAssertThrowsError(try store.repository.restoreDatabase(from: corrupt))
        let unrelated = store.directory.appendingPathComponent("unrelated.sqlite")
        let connection = try DatabaseQueue(path: unrelated.path)
        try connection.write { try $0.execute(sql: "CREATE TABLE transactions (id TEXT)") }
        try connection.close()
        XCTAssertThrowsError(try store.repository.restoreDatabase(from: unrelated))
        XCTAssertThrowsError(try store.repository.restoreDatabase(from: store.directory.appendingPathComponent("missing.sqlite")))
        XCTAssertEqual(try store.repository.transaction(id: original.id), original)
        XCTAssertEqual(try store.repository.transactions(includeDeleted: true).count, 1)
    }

    func testBackupWithInvalidRowsCannotBypassCanonicalConstraints() throws {
        let store = try SQLiteTestStore()
        try store.repository.save(TransactionFixture.make(id: "original"))
        let backup = store.directory.appendingPathComponent("invalid.sqlite")
        try store.repository.backUp(to: backup)
        let connection = try DatabaseQueue(path: backup.path)
        try connection.writeWithoutTransaction { db in
            try db.execute(sql: "PRAGMA ignore_check_constraints = ON")
            try db.execute(sql: "UPDATE transactions SET amount_cents = ?", arguments: [-1])
        }
        try connection.close()
        XCTAssertThrowsError(try store.repository.restoreDatabase(from: backup))
        XCTAssertEqual(try store.repository.transaction(id: "original")?.amountCents, 450)
    }

    func testLiveDatabaseJournalsAndAliasesAreProtected() throws {
        let store = try SQLiteTestStore()
        for suffix in ["", "-wal", "-shm", "-journal"] {
            XCTAssertThrowsError(try store.repository.checkFileLocation(URL(fileURLWithPath: store.databaseURL.path + suffix)))
        }
        let alias = store.directory.appendingPathComponent("alias.sqlite")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: store.databaseURL)
        XCTAssertThrowsError(try store.repository.backUp(to: alias))
        XCTAssertThrowsError(try store.repository.restoreDatabase(from: alias))
        let hardLink = store.directory.appendingPathComponent("hard-link.sqlite")
        try FileManager.default.linkItem(at: store.databaseURL, to: hardLink)
        XCTAssertThrowsError(try store.repository.checkFileLocation(hardLink))
        XCTAssertThrowsError(try store.repository.checkFileLocation(URL(string: "https://example.com/backup.sqlite")!))
    }

    func testEmptyBackupCanBeRestored() throws {
        let store = try SQLiteTestStore()
        let backup = store.directory.appendingPathComponent("empty.sqlite")
        try store.repository.backUp(to: backup)
        XCTAssertEqual(try store.repository.validateBackup(at: backup), 0)
        try store.repository.save(TransactionFixture.make())
        try store.repository.restoreDatabase(from: backup)
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
    }
}
