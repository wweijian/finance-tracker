import Charts
import SwiftUI

struct NetBalanceChart: View {
    let months: [MonthlyReport]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReportChartHeaderView(title: "Net balance", subtitle: "Income minus expenses by month")
            if months.allSatisfy({ $0.totals.transactionCount == 0 }) {
                ChartEmptyView(message: "No transactions to calculate a net balance.")
            } else {
                Chart {
                    RuleMark(y: .value("Break even", 0))
                        .foregroundStyle(.secondary.opacity(0.4))
                        .accessibilityHidden(true)
                    ForEach(months) { month in
                        LineMark(x: .value("Month", month.label), y: .value("SGD", Decimal(month.totals.netCents) / 100))
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .symbol(.circle)
                            .symbolSize(22)
                            .accessibilityLabel("\(month.label) net balance")
                            .accessibilityValue(CurrencyFormatter().string(for: month.totals.netCents))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine().foregroundStyle(Color.secondary.opacity(0.12))
                        AxisValueLabel()
                    }
                }
                .frame(height: 160)
                .accessibilityLabel("Net balance trend line in Singapore dollars")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
