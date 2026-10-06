import Foundation

struct MonthlyReport: Sendable, Identifiable {
    let month: Int
    let startDate: String
    let endDate: String
    let totals: ReportTotals
    let monthOverMonth: ReportComparison
    let yearOverYear: ReportComparison
    let categories: [CategoryMonthlyReport]

    var id: Int { month }
    var label: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        return calendar.shortMonthSymbols[month - 1]
    }
}
