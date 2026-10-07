import Foundation

protocol TransactionRepository: Sendable {
    func transactions(includeDeleted: Bool) throws -> [TransactionListItem]
    func transaction(id: String) throws -> FinanceTransaction?
    /// Deleted matches can be re-imported; only active matches are duplicates.
    func isDuplicate(date: String, amountCents: Int, description: String) throws -> Bool
    func insertIfNew(_ transaction: FinanceTransaction) throws -> Bool
    /// Adds new rows or restores deleted matches atomically, returning their stored IDs.
    func insertIfNew(_ transactions: [FinanceTransaction]) throws -> [String]
    func save(_ transaction: FinanceTransaction) throws
    func softDelete(id: String) throws
    func softDelete(ids: [String]) throws
    func restore(id: String) throws
}
