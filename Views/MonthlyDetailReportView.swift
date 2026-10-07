import SwiftUI

struct MonthlyDetailReportView: View {
    let months: [MonthlyReport]
    let spendingHistory: [MonthlyReport]
    let report: MonthlyReport?
    @Binding var selectedMonth: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            MonthlyComparisonView(months: months, report: report, selectedMonth: $selectedMonth)
            MonthlySpendingChart(months: spendingHistory, selectedMonth: report?.startDate)
            if let report {
                SpendingPieChart(categoryTotals: report.spendingDistribution)
                CategoryMonthlyComparisonView(categories: report.categories)
            }
            Divider()
            MonthlyReportTable(months: months, selectedMonth: $selectedMonth)
        }
    }
}
