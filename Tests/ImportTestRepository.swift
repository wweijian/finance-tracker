import Foundation
@testable import LedgerlyApp

final class ImportTestRepository: TransactionRepository, @unchecked Sendable {
    func transactions(includeDeleted: Bool) throws -> [TransactionListItem] { [] }
    func transaction(id: String) throws -> FinanceTransaction? { nil }
    func isDuplicate(date: String, amountCents: Int, description: String) throws -> Bool { false }
    func insertIfNew(_ transaction: FinanceTransaction) throws -> Bool { true }
    func insertIfNew(_ transactions: [FinanceTransaction]) throws -> [String] { transactions.map(\.id) }
    func save(_ transaction: FinanceTransaction) throws {}
    func softDelete(id: String) throws {}
    func softDelete(ids: [String]) throws {}
    func restore(id: String) throws {}
}
