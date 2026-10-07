import Foundation

struct CategoryTotal: Sendable, Hashable, Identifiable {
    let category: String
    let amountCents: Int
    let previousYearCents: Int?

    var id: String { category }
    var amount: Decimal { Decimal(amountCents) / 100 }
    func percentage(of totalCents: Int) -> String {
        guard totalCents > 0 else { return "0%" }
        let share = Decimal(amountCents) / Decimal(totalCents) * 100
        return "\(share.formatted(.number.precision(.fractionLength(1))))%"
    }
    var yearOverYear: FinancialChange {
        FinancialChange(currentCents: amountCents, previousCents: previousYearCents)
    }
}
