import Charts
import SwiftUI

struct CategoryCashFlowChart: View {
    let months: [MonthlyReport]
    let category: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReportChartHeaderView(title: "\(category) by month", subtitle: "By month in the selected reporting period")
            if months.allSatisfy({ $0.amountCents(for: category) == 0 }) {
                ChartEmptyView(message: "No transactions for \(category) in this period.")
            } else {
                Chart(months) { month in
                    LineMark(x: .value("Month", month.label), y: .value("SGD", Decimal(month.amountCents(for: category)) / 100))
                        .foregroundStyle(category == "Investment" ? Color.purple : Color.teal)
                        .symbol(.circle)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .accessibilityLabel("\(month.label), \(category)")
                        .accessibilityValue(CurrencyFormatter().string(for: month.amountCents(for: category)))
                }
                .frame(height: 320)
                .accessibilityLabel("Monthly \(category) trend in Singapore dollars")
            }
        }
    }
}
