import Foundation
import GRDB

final class SQLiteTransactionRepository: TransactionRepository, DatabaseFileRepository, @unchecked Sendable {
    private let database: DatabaseQueue
    private let databaseURL: URL
    private let schemaURL: URL

    init(databaseURL: URL, schemaURL: URL) throws {
        self.databaseURL = databaseURL
        self.schemaURL = schemaURL
        database = try DatabaseQueue(path: databaseURL.path)
        try database.write { db in
            try db.execute(sql: try String(contentsOf: schemaURL, encoding: .utf8))
            try removeTransactionTimeColumn(in: db)
        }
    }

    func transactions(includeDeleted: Bool) throws -> [TransactionListItem] {
        let predicate = includeDeleted ? "1 = 1" : "t.deleted_at IS NULL"
        return try database.read { db in
            try TransactionListItem.fetchAll(db, sql: """
                SELECT t.id, t.transaction_date, t.transaction_type,
                       t.amount_cents, t.currency, t.description, t.category,
                       t.notes, t.deleted_at
                FROM transactions t
                WHERE \(predicate)
                ORDER BY t.transaction_date DESC, t.date_created DESC
                """)
        }
    }

    func transaction(id: String) throws -> FinanceTransaction? {
        try database.read { db in
            try FinanceTransaction.fetchOne(db, key: id)
        }
    }

    func insertIfNew(_ transaction: FinanceTransaction) throws -> Bool {
        try !insertIfNew([transaction]).isEmpty
    }

    func insertIfNew(_ transactions: [FinanceTransaction]) throws -> [String] {
        try database.write { db in
            var insertedIDs: [String] = []
            for transaction in transactions {
                let exists = try isDuplicate(
                    in: db,
                    date: transaction.transactionDate,
                    amountCents: transaction.amountCents,
                    description: transaction.description
                )
                guard !exists else { continue }
                try transaction.insert(db)
                insertedIDs.append(transaction.id)
            }
            return insertedIDs
        }
    }

    func isDuplicate(date: String, amountCents: Int, description: String) throws -> Bool {
        try database.read { db in
            try isDuplicate(in: db, date: date, amountCents: amountCents, description: description)
        }
    }

    func save(_ transaction: FinanceTransaction) throws {
        try database.write { db in
            if try FinanceTransaction.fetchOne(db, key: transaction.id) == nil {
                try transaction.insert(db)
            } else {
                try transaction.update(db)
            }
        }
    }

    func softDelete(id: String) throws {
        try softDelete(ids: [id])
    }

    func softDelete(ids: [String]) throws {
        let now = ISO8601DateFormatter().string(from: Date())
        try database.write { db in
            for id in ids {
                try db.execute(
                    sql: "UPDATE transactions SET deleted_at = ?, updated_at = ? WHERE id = ? AND deleted_at IS NULL",
                    arguments: [now, now, id]
                )
            }
        }
    }

    func restore(id: String) throws {
        try updateDeletion(id: id, deletedAt: nil)
    }

    private func updateDeletion(id: String, deletedAt: String?) throws {
        try database.write { db in
            try db.execute(sql: "UPDATE transactions SET deleted_at = ?, updated_at = ? WHERE id = ?", arguments: [deletedAt, ISO8601DateFormatter().string(from: Date()), id])
        }
    }

    private func isDuplicate(
        in database: Database,
        date: String,
        amountCents: Int,
        description: String
    ) throws -> Bool {
        try Int.fetchOne(database, sql: """
            SELECT EXISTS(
                SELECT 1 FROM transactions
                WHERE transaction_date = ? AND amount_cents = ? AND description = ?
            )
            """, arguments: [date, amountCents, description]) == 1
    }

    private func removeTransactionTimeColumn(in database: Database) throws {
        guard try hasTransactionTimeColumn(in: database) else { return }

        try database.execute(sql: "DROP INDEX IF EXISTS idx_transactions_exact_duplicate")
        try database.execute(sql: "ALTER TABLE transactions DROP COLUMN transaction_time")
        try database.execute(sql: """
            CREATE UNIQUE INDEX idx_transactions_exact_duplicate
            ON transactions (transaction_date, amount_cents, description COLLATE BINARY)
            """)
    }

    private func hasTransactionTimeColumn(in database: Database) throws -> Bool {
        try Row.fetchAll(database, sql: "PRAGMA table_info(transactions)").contains { row in
            let name: String = row["name"]
            return name == "transaction_time"
        }
    }

    func checkFileLocation(_ url: URL) throws {
        guard url.isFileURL else { throw LocalFileError.localLocationRequired }
        let fileManager = FileManager.default
        let resolved = url.resolvingSymlinksInPath().standardizedFileURL
        let live = databaseURL.resolvingSymlinksInPath().standardizedFileURL
        let reservedPaths = [live.path, live.path + "-wal", live.path + "-shm", live.path + "-journal"]
        guard !reservedPaths.contains(resolved.path) else { throw LocalFileError.liveDatabase }
        if fileManager.fileExists(atPath: resolved.path) {
            let candidate = try fileManager.attributesOfItem(atPath: resolved.path)
            let active = try fileManager.attributesOfItem(atPath: live.path)
            if candidate[.systemNumber] as? NSNumber == active[.systemNumber] as? NSNumber,
               candidate[.systemFileNumber] as? NSNumber == active[.systemFileNumber] as? NSNumber {
                throw LocalFileError.liveDatabase
            }
        }
        let folder = resolved.deletingLastPathComponent()
        let resources = try folder.resourceValues(forKeys: [.volumeIsLocalKey, .isUbiquitousItemKey])
        guard resources.volumeIsLocal != false, resources.isUbiquitousItem != true,
              !fileManager.isUbiquitousItem(at: resolved) else { throw LocalFileError.localLocationRequired }
    }

    func backUp(to url: URL) throws {
        try checkFileLocation(url)
        for suffix in ["-wal", "-shm", "-journal"] {
            guard !FileManager.default.fileExists(atPath: url.path + suffix) else { throw LocalFileError.destinationInUse }
        }
        let temporaryURL = url.deletingLastPathComponent().appendingPathComponent(".ledgerly-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: temporaryURL) }
        try writeBackup(at: temporaryURL)
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: temporaryURL)
        } else {
            try FileManager.default.moveItem(at: temporaryURL, to: url)
        }
    }

    func validateBackup(at url: URL) throws -> Int {
        let snapshot = try validatedBackup(at: url)
        return try snapshot.read { try Int.fetchOne($0, sql: "SELECT COUNT(*) FROM transactions")! }
    }

    func restoreDatabase(from url: URL) throws {
        let snapshot = try validatedBackup(at: url)
        // SQLite replaces the database atomically and keeps the existing connection usable.
        try snapshot.backup(to: database)
    }

    private func writeBackup(at url: URL) throws {
        let destination = try DatabaseQueue(path: url.path)
        try database.backup(to: destination)
        // A backup is one portable file, even when the source uses WAL journaling.
        try destination.writeWithoutTransaction { try $0.execute(sql: "PRAGMA journal_mode = DELETE") }
        try destination.close()
    }

    private func validatedBackup(at url: URL) throws -> DatabaseQueue {
        try checkFileLocation(url)
        guard FileManager.default.fileExists(atPath: url.path) else { throw LocalFileError.invalidBackup }
        do {
            var configuration = Configuration()
            configuration.readonly = true
            let source = try DatabaseQueue(path: url.path, configuration: configuration)
            defer { try? source.close() }
            let transactions = try source.read { db in
                guard try String.fetchOne(db, sql: "PRAGMA integrity_check") == "ok" else { throw LocalFileError.invalidBackup }
                let tables = try String.fetchAll(db, sql: "SELECT name FROM sqlite_schema WHERE type = ? AND name NOT LIKE ?", arguments: ["table", "sqlite_%"])
                let executableObjects = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM sqlite_schema WHERE type IN (?, ?)", arguments: ["trigger", "view"])
                guard tables == ["transactions"], executableObjects == 0 else { throw LocalFileError.invalidBackup }
                let requiredColumns: Set<String> = ["id", "transaction_date", "transaction_year", "transaction_type", "amount_cents", "currency", "description", "category", "notes", "date_created", "updated_at", "deleted_at"]
                let columns = Set(try db.columns(in: "transactions").map(\.name))
                guard requiredColumns.isSubset(of: columns), columns.isSubset(of: requiredColumns.union(["transaction_time"])) else { throw LocalFileError.invalidBackup }
                return try FinanceTransaction.fetchAll(db)
            }
            return try canonicalBackup(transactions)
        } catch {
            throw LocalFileError.invalidBackup
        }
    }

    private func canonicalBackup(_ transactions: [FinanceTransaction]) throws -> DatabaseQueue {
        let snapshot = try DatabaseQueue()
        let schema = try String(contentsOf: schemaURL, encoding: .utf8)
        let formatter = TransactionDateFormatter()
        try snapshot.write { db in
            try db.execute(sql: schema)
            for transaction in transactions {
                guard let date = formatter.date(from: transaction.transactionDate),
                      formatter.string(from: date) == transaction.transactionDate else { throw LocalFileError.invalidBackup }
                try transaction.insert(db)
            }
        }
        return snapshot
    }
}
