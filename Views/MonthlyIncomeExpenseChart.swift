import Charts
import SwiftUI

struct MonthlyIncomeExpenseChart: View {
    let months: [MonthlyReport]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReportChartHeaderView(title: "Income, expenses & investments")
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
                    BarMark(x: .value("Month", month.label), y: .value("SGD", Decimal(month.totals.investmentCents) / 100))
                        .foregroundStyle(by: .value("Type", "Investments"))
                        .position(by: .value("Type", "Investments"))
                        .cornerRadius(2)
                        .accessibilityLabel("\(month.label) investments")
                        .accessibilityValue(CurrencyFormatter().string(for: month.totals.investmentCents))
                }
                .chartForegroundStyleScale(["Income": Color.teal, "Expenses": Color.orange, "Investments": Color.purple])
                .chartLegend(position: .top, alignment: .leading, spacing: 14)
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine().foregroundStyle(Color.secondary.opacity(0.12))
                        AxisValueLabel()
                    }
                }
                .frame(height: 300)
                .accessibilityLabel("Monthly income, expenses and investments in Singapore dollars")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
