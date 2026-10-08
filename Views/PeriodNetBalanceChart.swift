import Charts
import SwiftUI

struct PeriodNetBalanceChart: View {
    let intervals: [ReportInterval]
    let scope: DashboardScope

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ReportChartHeaderView(title: "Net cash flow", subtitle: "Income minus expenses and investments by \(scope.intervalLabel.lowercased())")
            if intervals.allSatisfy({ $0.totals.transactionCount == 0 }) {
                ChartEmptyView(message: "No transactions to calculate a balance.")
            } else {
                Chart {
                    RuleMark(y: .value("Break even", 0))
                        .foregroundStyle(.secondary.opacity(0.4))
                    ForEach(intervals) { interval in
                        LineMark(x: .value(scope.intervalLabel, interval.label), y: .value("SGD", Decimal(interval.totals.netCents) / 100))
                            .foregroundStyle(.teal)
                            .symbol(.circle)
                            .accessibilityLabel("\(interval.startDate) net cash flow")
                            .accessibilityValue(CurrencyFormatter().string(for: interval.totals.netCents))
                    }
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .accessibilityLabel("\(scope == .monthly ? "Daily" : "Monthly") net cash flow in Singapore dollars")
            }
        }
        .frame(maxHeight: .infinity)
    }
}
