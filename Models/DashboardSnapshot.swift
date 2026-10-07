import Foundation
struct DashboardSnapshot: Sendable {
    var totals: ReportTotals
    var yearOverYear: ReportComparison
    var months: [MonthlyReport]
    var categoryTotals: [CategoryTotal]
    var availableYears: [Int]
    var spendingHistoryMonths: [MonthlyReport] = []

    var incomeCents: Int { totals.incomeCents }
    var expenseCents: Int { totals.expenseCents }
    var investmentCents: Int { totals.investmentCents }
    var netCents: Int { totals.netCents }
    var transactionCount: Int { totals.transactionCount }

    func spendingHistory(through report: MonthlyReport) -> [MonthlyReport] {
        Array((spendingHistoryMonths.isEmpty ? months : spendingHistoryMonths)
            .filter { $0.startDate.prefix(7) <= report.startDate.prefix(7) }
            .sorted { $0.startDate < $1.startDate }
            .suffix(12))
            .map { $0.month == report.month && $0.startDate.prefix(4) == report.startDate.prefix(4) ? report : $0 }
    }

    static let empty = DashboardSnapshot(
        totals: .empty, yearOverYear: .empty, months: [], categoryTotals: [], availableYears: []
    )
}
