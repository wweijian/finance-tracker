import Foundation

struct TransactionForm: Identifiable {
    var id: String
    var transactionID: String?
    var date: Date
    var transactionType: TransactionType
    var amount: String
    var description: String
    var category: String
    var notes: String
    var isExcluded: Bool

    init(categories: [String]) {
        id = UUID().uuidString
        transactionID = nil
        date = Date()
        transactionType = .expense
        amount = ""
        description = ""
        category = categories.first ?? "Other"
        notes = ""
        isExcluded = false
    }

    init(transaction: FinanceTransaction, date: Date) {
        id = transaction.id
        transactionID = transaction.id
        self.date = date
        transactionType = transaction.transactionType
        amount = CurrencyAmountFormatter().inputString(for: transaction.amountCents)
        description = transaction.description
        category = transaction.category
        notes = transaction.notes ?? ""
        isExcluded = transaction.deletedAt != nil
    }
}
