import Foundation
import GRDB

final class SQLiteTransactionRepository: TransactionRepository, @unchecked Sendable {
    private let database: DatabaseQueue

    init(databaseURL: URL, schemaURL: URL) throws {
        database = try DatabaseQueue(path: databaseURL.path)
        try database.write { db in
            try db.execute(sql: try String(contentsOf: schemaURL, encoding: .utf8))
        }
    }

    func transactions(includeDeleted: Bool) throws -> [TransactionListItem] {
        let predicate = includeDeleted ? "1 = 1" : "t.deleted_at IS NULL"
        return try database.read { db in
            try TransactionListItem.fetchAll(db, sql: """
                SELECT t.id, t.transaction_date, t.transaction_time, t.transaction_type,
                       t.amount_cents, t.currency, t.description, t.category,
                       t.notes, t.deleted_at
                FROM transactions t
                WHERE \(predicate)
                ORDER BY t.transaction_date DESC, t.transaction_time DESC, t.date_created DESC
                """)
        }
    }

    func transaction(id: String) throws -> FinanceTransaction? {
        try database.read { db in
            try FinanceTransaction.fetchOne(db, key: id)
        }
    }

    func dashboard(year: Int) throws -> DashboardSnapshot {
        try database.read { db in
            let totals = try Row.fetchOne(db, sql: """
                SELECT COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount_cents END), 0) AS income,
                       COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount_cents END), 0) AS expense,
                       COUNT(*) AS count
                FROM transactions WHERE deleted_at IS NULL AND transaction_year = ?
                """, arguments: [year])!
            let categories = try CategoryTotal.fetchAll(db, sql: """
                SELECT t.category, SUM(t.amount_cents) AS amount_cents
                FROM transactions t
                WHERE t.deleted_at IS NULL AND t.transaction_year = ? AND t.transaction_type = 'expense'
                GROUP BY t.category ORDER BY amount_cents DESC
                """, arguments: [year])
            return DashboardSnapshot(
                incomeCents: totals["income"],
                expenseCents: totals["expense"],
                transactionCount: totals["count"],
                categoryTotals: categories
            )
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
        try updateDeletion(id: id, deletedAt: ISO8601DateFormatter().string(from: Date()))
    }

    func restore(id: String) throws {
        try updateDeletion(id: id, deletedAt: nil)
    }

    private func updateDeletion(id: String, deletedAt: String?) throws {
        try database.write { db in
            try db.execute(sql: "UPDATE transactions SET deleted_at = ?, updated_at = ? WHERE id = ?", arguments: [deletedAt, ISO8601DateFormatter().string(from: Date()), id])
        }
    }
}
