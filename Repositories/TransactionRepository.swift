import Foundation

protocol TransactionRepository: Sendable {
    func transactions(includeDeleted: Bool) throws -> [TransactionListItem]
    func transaction(id: String) throws -> FinanceTransaction?
    func isDuplicate(date: String, amountCents: Int, description: String) throws -> Bool
    func insertIfNew(_ transaction: FinanceTransaction) throws -> Bool
    func insertIfNew(_ transactions: [FinanceTransaction]) throws -> [String]
    func save(_ transaction: FinanceTransaction) throws
    func softDelete(id: String) throws
    func softDelete(ids: [String]) throws
    func restore(id: String) throws
}
