import Charts
import SwiftUI

struct PeriodCashFlowChart: View {
    let intervals: [ReportInterval]
    let scope: DashboardScope

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ReportChartHeaderView(title: "Income, expenses & investments", subtitle: "By \(scope.intervalLabel.lowercased())")
            if intervals.allSatisfy({ $0.totals.transactionCount == 0 }) {
                ChartEmptyView(message: "No transactions in this period.")
            } else {
                Chart(intervals) { interval in
                    BarMark(x: .value(scope.intervalLabel, interval.label), y: .value("SGD", Decimal(interval.totals.incomeCents) / 100))
                        .foregroundStyle(by: .value("Type", "Income"))
                        .position(by: .value("Type", "Income"))
                        .accessibilityLabel("\(interval.startDate) income")
                        .accessibilityValue(CurrencyFormatter().string(for: interval.totals.incomeCents))
                    BarMark(x: .value(scope.intervalLabel, interval.label), y: .value("SGD", Decimal(interval.totals.expenseCents) / 100))
                        .foregroundStyle(by: .value("Type", "Expenses"))
                        .position(by: .value("Type", "Expenses"))
                        .accessibilityLabel("\(interval.startDate) expenses")
                        .accessibilityValue(CurrencyFormatter().string(for: interval.totals.expenseCents))
                    BarMark(x: .value(scope.intervalLabel, interval.label), y: .value("SGD", Decimal(interval.totals.investmentCents) / 100))
                        .foregroundStyle(by: .value("Type", "Investments"))
                        .position(by: .value("Type", "Investments"))
                        .accessibilityLabel("\(interval.startDate) investments")
                        .accessibilityValue(CurrencyFormatter().string(for: interval.totals.investmentCents))
                }
                .chartForegroundStyleScale(["Income": Color.teal, "Expenses": Color.orange, "Investments": Color.purple])
                .chartLegend(position: .top, alignment: .leading)
                .chartYAxis { AxisMarks(position: .leading) }
                .accessibilityLabel("\(scope == .monthly ? "Daily" : "Monthly") cash flow in Singapore dollars")
            }
        }
        .frame(maxHeight: .infinity)
    }
}
