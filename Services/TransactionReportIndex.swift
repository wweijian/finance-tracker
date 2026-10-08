struct TransactionReportIndex {
    private let months: [String: [TransactionListItem]]

    init(transactions: [TransactionListItem]) {
        months = Dictionary(grouping: transactions) { String($0.transactionDate.prefix(7)) }
    }

    func rows(from startDate: String, through endDate: String) -> [TransactionListItem] {
        let startMonth = String(startDate.prefix(7))
        let endMonth = String(endDate.prefix(7))
        let candidates: [TransactionListItem]
        if startMonth == endMonth {
            candidates = months[startMonth, default: []]
        } else {
            candidates = months.keys.filter { $0 >= startMonth && $0 <= endMonth }.sorted()
                .flatMap { months[$0, default: []] }
        }
        return candidates.filter { $0.transactionDate >= startDate && $0.transactionDate <= endDate }
    }
}
