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
                    MonthlyMetricView(title: "Monthly spending", cents: report.totals.expenseCents, monthOverMonth: report.monthOverMonth.expenses)
                    Divider()
                    MonthlyMetricView(title: "Previous month", cents: report.monthOverMonth.expenses.previousCents, monthOverMonth: nil)
                    Divider()
                    MonthlyMetricView(title: "Spending difference", cents: report.monthOverMonth.expenses.differenceCents, monthOverMonth: nil)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
