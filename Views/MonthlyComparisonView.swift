import SwiftUI

struct MonthlyComparisonView: View {
    let months: [MonthlyReport]
    let report: MonthlyReport?
    @Binding var selectedMonth: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Picker("Month", selection: $selectedMonth) {
                    ForEach(months) { Text($0.label).tag($0.month) }
                }.frame(width: 145)
                Spacer()
                if let report {
                    Text("\(report.startDate) – \(report.endDate)")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
            }
            if let report {
                HStack(spacing: 24) {
                    MonthlyMetricView(title: "Income", cents: report.totals.incomeCents, monthOverMonth: report.monthOverMonth.income, yearOverYear: report.yearOverYear.income)
                    Divider()
                    MonthlyMetricView(title: "Expenses", cents: report.totals.expenseCents, monthOverMonth: report.monthOverMonth.expenses, yearOverYear: report.yearOverYear.expenses)
                    Divider()
                    MonthlyMetricView(title: "Net balance", cents: report.totals.netCents, monthOverMonth: report.monthOverMonth.net, yearOverYear: report.yearOverYear.net)
                }
                .fixedSize(horizontal: false, vertical: true)
                CategoryMonthlyComparisonView(categories: report.categories)
            }
        }
    }
}
