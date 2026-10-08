import SwiftUI

struct MonthlyReportTable: View {
    let months: [MonthlyReport]
    @Binding var selectedMonth: Int
    @State private var sortOrder = [KeyPathComparator(\MonthlyReport.month)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Monthly ledger").font(.headline)
                Spacer()
                Text("Select a month to inspect its categories")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Table(Array(months.prefix(12)).sorted(using: sortOrder), selection: Binding<Int?>(get: { selectedMonth }, set: { if let month = $0 { selectedMonth = month } }), sortOrder: $sortOrder) {
                TableColumn("Month", value: \.month) { month in
                    Text(month.label).help("\(month.startDate) through \(month.endDate)")
                }.width(min: 44, ideal: 50)
                TableColumn("Income", value: \.totals.incomeCents) { month in
                    Text(CurrencyFormatter().string(for: month.totals.incomeCents)).monospacedDigit()
                }.width(min: 90, ideal: 110)
                TableColumn("Income change", sortUsing: KeyPathComparator(\MonthlyReport.monthOverMonth.income.percentage)) { month in
                    ReportChangeView(monthOverMonth: month.monthOverMonth.income)
                }.width(min: 100, ideal: 115)
                TableColumn("Spending", value: \.totals.expenseCents) { month in
                    Text(CurrencyFormatter().string(for: month.totals.expenseCents)).monospacedDigit()
                }.width(min: 90, ideal: 110)
                TableColumn("Spending change", sortUsing: KeyPathComparator(\MonthlyReport.monthOverMonth.expenses.percentage)) { month in
                    ReportChangeView(monthOverMonth: month.monthOverMonth.expenses)
                }.width(min: 100, ideal: 115)
                TableColumn("Investments", value: \.totals.investmentCents) { month in
                    Text(CurrencyFormatter().string(for: month.totals.investmentCents)).monospacedDigit()
                }.width(min: 90, ideal: 110)
                TableColumn("Net balance", value: \.totals.netCents) { month in
                    Text(CurrencyFormatter().string(for: month.totals.netCents)).monospacedDigit()
                }.width(min: 90, ideal: 110)
                TableColumn("Net change", sortUsing: KeyPathComparator(\MonthlyReport.monthOverMonth.net.percentage)) { month in
                    ReportChangeView(monthOverMonth: month.monthOverMonth.net)
                }.width(min: 100, ideal: 115)
            }
            .tableStyle(.bordered(alternatesRowBackgrounds: true))
            .frame(height: CGFloat(min(months.count, 12) * 24 + 32))
            .accessibilityLabel("Monthly income, spending, investments, net balance and percentage changes. Click column headings to sort. Change columns sort by month-on-month percentage.")
        }
    }
}
