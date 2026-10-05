import Foundation

struct TransactionForm: Identifiable {
    var id: String
    var transactionID: String?
    var date: Date
    var time: String
    var transactionType: TransactionType
    var amount: String
    var description: String
    var category: String
    var notes: String

    init(categories: [String]) {
        id = UUID().uuidString
        transactionID = nil
        date = Date()
        time = ""
        transactionType = .expense
        amount = ""
        description = ""
        category = categories.first ?? "Other"
        notes = ""
    }

    init(transaction: FinanceTransaction, date: Date) {
        id = transaction.id
        transactionID = transaction.id
        self.date = date
        time = transaction.transactionTime ?? ""
        transactionType = transaction.transactionType
        amount = CurrencyAmountFormatter().inputString(for: transaction.amountCents)
        description = transaction.description
        category = transaction.category
        notes = transaction.notes ?? ""
    }
}
