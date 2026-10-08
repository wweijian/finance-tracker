struct CategorySpendingComparison: Sendable, Identifiable {
    let category: String
    let change: FinancialChange

    var id: String { category }
    var amountCents: Int { change.currentCents }
}
