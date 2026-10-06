import Foundation
struct DashboardSnapshot: Sendable {
    var totals: ReportTotals
    var yearOverYear: ReportComparison
    var months: [MonthlyReport]
    var categoryTotals: [CategoryTotal]
    var availableYears: [Int]

    var incomeCents: Int { totals.incomeCents }
    var expenseCents: Int { totals.expenseCents }
    var netCents: Int { totals.netCents }
    var transactionCount: Int { totals.transactionCount }

    static let empty = DashboardSnapshot(
        totals: .empty, yearOverYear: .empty, months: [], categoryTotals: [], availableYears: []
    )
}
