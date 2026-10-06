import Foundation

actor TransactionService: TransactionServing {
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

    func insertIfNew(_ transaction: FinanceTransaction) throws -> Bool {
        try repository.insertIfNew(transaction)
    }

    func isDuplicate(date: String, amountCents: Int, description: String) throws -> Bool {
        try repository.isDuplicate(date: date, amountCents: amountCents, description: description)
    }

    func softDelete(id: String) throws {
        try repository.softDelete(id: id)
    }

    func restore(id: String) throws {
        try repository.restore(id: id)
    }
}
