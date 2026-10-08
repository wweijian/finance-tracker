import Foundation
struct DashboardSnapshot: Sendable {
    var totals: ReportTotals
    var yearOverYear: ReportComparison
    var months: [MonthlyReport]
    var categoryTotals: [CategoryTotal]
    var availableYears: [Int]
    var spendingHistoryMonths: [MonthlyReport] = []
    var days: [ReportInterval] = []
    var transactions: [TransactionListItem] = []

    func intervals(for scope: DashboardScope) -> [ReportInterval] {
        if scope == .monthly { return days }
        let grouped = Dictionary(grouping: transactions) { String($0.transactionDate.prefix(7)) }
        return months.map { month in
            ReportInterval(startDate: month.startDate, label: month.label, totals: month.totals,
                           categories: month.spendingDistribution,
                           transactions: grouped[String(month.startDate.prefix(7)), default: []])
        }
    }

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
