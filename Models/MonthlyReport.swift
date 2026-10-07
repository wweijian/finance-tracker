import Foundation

struct MonthlyReport: Sendable, Identifiable {
    let month: Int
    let startDate: String
    let endDate: String
    let totals: ReportTotals
    let monthOverMonth: ReportComparison
    let yearOverYear: ReportComparison
    let categories: [CategoryMonthlyReport]
    var categoryAmounts: [String: Int] = [:]

    var id: Int { month }
    var periodLabel: String { "\(label) ’\(startDate.prefix(4).suffix(2))" }
    var spendingDistribution: [CategoryTotal] {
        categories.map { CategoryTotal(category: $0.category, amountCents: $0.amountCents, previousYearCents: nil) }
            .sorted { $0.amountCents == $1.amountCents ? $0.category < $1.category : $0.amountCents > $1.amountCents }
    }
    func amountCents(for category: String) -> Int {
        categoryAmounts[category, default: 0]
    }
    var label: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        return calendar.shortMonthSymbols[month - 1]
    }
}
