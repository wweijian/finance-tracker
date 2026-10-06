import Foundation

struct CategoryTotal: Sendable, Hashable, Identifiable {
    let category: String
    let amountCents: Int
    let previousYearCents: Int?

    var id: String { category }
    var amount: Decimal { Decimal(amountCents) / 100 }
    var yearOverYear: FinancialChange {
        FinancialChange(currentCents: amountCents, previousCents: previousYearCents)
    }
}
