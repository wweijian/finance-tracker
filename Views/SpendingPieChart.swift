import Charts
import SwiftUI

struct SpendingPieChart: View {
    let categoryTotals: [CategoryTotal]
    private var spending: [CategoryTotal] { categoryTotals.filter { $0.amountCents > 0 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReportChartHeaderView(title: "Spending distribution")
            if spending.isEmpty {
                ChartEmptyView(message: "No expenses in this period. Income still appears in the monthly charts.")
            } else {
                Chart(spending) { total in
                    SectorMark(angle: .value("Spending in SGD", total.amount), innerRadius: .ratio(0.72))
                        .foregroundStyle(by: .value("Category", total.category))
                        .accessibilityLabel(total.category)
                        .accessibilityValue(CurrencyFormatter().string(for: total.amountCents))
                }
                .chartLegend(position: .bottom)
                .chartForegroundStyleScale(range: [.blue, .teal, .indigo, .orange, .purple, .mint])
                .frame(height: 280)
                .accessibilityLabel("Pie chart of selected period spending by category in Singapore dollars")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
