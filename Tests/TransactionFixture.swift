import Foundation
@testable import LedgerlyApp

enum TransactionFixture {
    static func make(
        id: String = UUID().uuidString, date: String = "2026-05-08", type: TransactionType = .expense,
        cents: Int = 450, category: String = "Food & Dining", description: String? = nil, deletedAt: String? = nil,
        notes: String? = nil
    ) -> FinanceTransaction {
        FinanceTransaction(
            id: id, transactionDate: date, transactionYear: Int(date.prefix(4))!, transactionType: type,
            amountCents: cents, currency: "SGD", description: description ?? id, category: category,
            notes: notes, dateCreated: "2026-05-08T00:00:00Z", updatedAt: "2026-05-08T00:00:00Z", deletedAt: deletedAt
        )
    }
}
