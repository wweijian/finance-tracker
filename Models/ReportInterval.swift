import Foundation

struct ReportInterval: Sendable, Identifiable {
    let startDate: String
    let label: String
    let totals: ReportTotals
    let categories: [CategoryTotal]
    let transactions: [TransactionListItem]
    private let highestTransactions: [String: TransactionListItem]

    var id: String { startDate }

    init(startDate: String, label: String, totals: ReportTotals, categories: [CategoryTotal], transactions: [TransactionListItem]) {
        self.startDate = startDate
        self.label = label
        self.totals = totals
        self.categories = categories.sorted { $0.category < $1.category }
        self.transactions = transactions
        highestTransactions = SpendingTransactionSelector.highestByCategory(in: transactions)
    }

    func spendingCents(for category: String) -> Int {
        categories.first { $0.category == category }?.amountCents ?? 0
    }

    func highestSpendingTransaction(for category: String) -> TransactionListItem? {
        highestTransactions[category]
    }

    func category(atSpendingCents cents: Int) -> String? {
        guard cents >= 0 else { return nil }
        var cumulative = 0
        for category in categories {
            cumulative += category.amountCents
            if cents < cumulative { return category.category }
        }
        return nil
    }

    static func peak(for category: String, in intervals: [ReportInterval]) -> ReportInterval? {
        intervals.filter { $0.spendingCents(for: category) > 0 }
            .max { lhs, rhs in
                let left = lhs.spendingCents(for: category)
                let right = rhs.spendingCents(for: category)
                return left == right ? lhs.startDate > rhs.startDate : left < right
            }
    }
}
