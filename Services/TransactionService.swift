import Foundation

actor TransactionService {
    private let repository: any TransactionRepository

    init(repository: any TransactionRepository) {
        self.repository = repository
    }

    func transactions(includeDeleted: Bool) throws -> [TransactionListItem] {
        try repository.transactions(includeDeleted: includeDeleted)
    }

    func transaction(id: String) throws -> FinanceTransaction? {
        try repository.transaction(id: id)
    }

    func save(_ transaction: FinanceTransaction) throws {
        try repository.save(transaction)
    }

    func softDelete(id: String) throws {
        try repository.softDelete(id: id)
    }

    func restore(id: String) throws {
        try repository.restore(id: id)
    }
}
