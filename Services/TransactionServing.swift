protocol TransactionServing: Sendable {
    func transactions(includeDeleted: Bool) async throws -> [TransactionListItem]
    func transaction(id: String) async throws -> FinanceTransaction?
    func save(_ transaction: FinanceTransaction) async throws
    func softDelete(id: String) async throws
    func restore(id: String) async throws
}
