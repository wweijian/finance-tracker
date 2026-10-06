import SwiftUI

struct MonthlyReportTable: View {
    let months: [MonthlyReport]
    @Binding var selectedMonth: Int
    @State private var sortOrder = [KeyPathComparator(\MonthlyReport.month)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Monthly ledger").font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("Select a month to inspect its categories")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Table(months.sorted(using: sortOrder), selection: Binding<Int?>(get: { selectedMonth }, set: { if let month = $0 { selectedMonth = month } }), sortOrder: $sortOrder) {
                TableColumn("Month", value: \.month) { month in
                    Text(month.label).help("\(month.startDate) through \(month.endDate)")
                }.width(min: 44, ideal: 50)
                TableColumn("Income", value: \.totals.incomeCents) { month in
                    Text(CurrencyFormatter().string(for: month.totals.incomeCents)).monospacedDigit()
                }.width(min: 90, ideal: 110)
                TableColumn("Income change", sortUsing: KeyPathComparator(\MonthlyReport.monthOverMonth.income.percentage)) { month in
                    ReportChangeView(monthOverMonth: month.monthOverMonth.income, yearOverYear: month.yearOverYear.income)
                }.width(min: 100, ideal: 115)
                TableColumn("Expenses", value: \.totals.expenseCents) { month in
                    Text(CurrencyFormatter().string(for: month.totals.expenseCents)).monospacedDigit()
                }.width(min: 90, ideal: 110)
                TableColumn("Expense change", sortUsing: KeyPathComparator(\MonthlyReport.monthOverMonth.expenses.percentage)) { month in
                    ReportChangeView(monthOverMonth: month.monthOverMonth.expenses, yearOverYear: month.yearOverYear.expenses)
                }.width(min: 100, ideal: 115)
                TableColumn("Net balance", value: \.totals.netCents) { month in
                    Text(CurrencyFormatter().string(for: month.totals.netCents)).monospacedDigit()
                }.width(min: 90, ideal: 110)
                TableColumn("Net change", sortUsing: KeyPathComparator(\MonthlyReport.monthOverMonth.net.percentage)) { month in
                    ReportChangeView(monthOverMonth: month.monthOverMonth.net, yearOverYear: month.yearOverYear.net)
                }.width(min: 100, ideal: 115)
            }
            .tableStyle(.bordered(alternatesRowBackgrounds: true))
            .frame(height: CGFloat(months.count * 42 + 32))
            .accessibilityLabel("Monthly income, expenses, net balance and percentage changes. Click column headings to sort. Change columns sort by month-on-month percentage.")
        }
    }
}
