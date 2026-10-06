import Foundation

struct CategoryMonthlyReport: Sendable, Identifiable {
    let category: String
    let amountCents: Int
    let monthOverMonth: FinancialChange
    let yearOverYear: FinancialChange

    var id: String { category }
}
