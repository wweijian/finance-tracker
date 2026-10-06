import Charts
import SwiftUI

struct MonthlyIncomeExpenseChart: View {
    let months: [MonthlyReport]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReportChartHeaderView(title: "Income & expenses")
            if months.allSatisfy({ $0.totals.transactionCount == 0 }) {
                ChartEmptyView(message: "No income or expenses in this period.")
            } else {
                Chart(months) { month in
                    BarMark(x: .value("Month", month.label), y: .value("SGD", Decimal(month.totals.incomeCents) / 100))
                        .foregroundStyle(by: .value("Type", "Income"))
                        .position(by: .value("Type", "Income"))
                        .cornerRadius(2)
                        .accessibilityLabel("\(month.label) income")
                        .accessibilityValue(CurrencyFormatter().string(for: month.totals.incomeCents))
                    BarMark(x: .value("Month", month.label), y: .value("SGD", Decimal(month.totals.expenseCents) / 100))
                        .foregroundStyle(by: .value("Type", "Expenses"))
                        .position(by: .value("Type", "Expenses"))
                        .cornerRadius(2)
                        .accessibilityLabel("\(month.label) expenses")
                        .accessibilityValue(CurrencyFormatter().string(for: month.totals.expenseCents))
                }
                .chartForegroundStyleScale(["Income": Color.blue, "Expenses": Color.gray.opacity(0.55)])
                .chartLegend(position: .top, alignment: .leading, spacing: 14)
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine().foregroundStyle(Color.secondary.opacity(0.12))
                        AxisValueLabel()
                    }
                }
                .frame(height: 235)
                .accessibilityLabel("Monthly income versus expense bar chart in Singapore dollars")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
