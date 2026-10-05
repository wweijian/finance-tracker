import Foundation

protocol TransactionRepository: Sendable {
    func transactions(includeDeleted: Bool) throws -> [TransactionListItem]
    func transaction(id: String) throws -> FinanceTransaction?
    func dashboard(year: Int) throws -> DashboardSnapshot
    func save(_ transaction: FinanceTransaction) throws
    func softDelete(id: String) throws
    func restore(id: String) throws
}
