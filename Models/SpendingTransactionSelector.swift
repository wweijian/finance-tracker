enum SpendingTransactionSelector {
    static func highestByCategory(in transactions: [TransactionListItem]) -> [String: TransactionListItem] {
        transactions.reduce(into: [:]) { result, transaction in
            guard transaction.transactionType == .expense, !transaction.isExcluded,
                  transaction.category != "Investment" else { return }
            if let current = result[transaction.category], !precedes(transaction, current) { return }
            result[transaction.category] = transaction
        }
    }

    private static func precedes(_ lhs: TransactionListItem, _ rhs: TransactionListItem) -> Bool {
        if lhs.amountCents != rhs.amountCents { return lhs.amountCents > rhs.amountCents }
        if lhs.transactionDate != rhs.transactionDate { return lhs.transactionDate < rhs.transactionDate }
        return lhs.id < rhs.id
    }
}
