import Charts
import SwiftUI

struct CategoryMonthlyComparisonView: View {
    let categories: [CategoryMonthlyReport]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReportChartHeaderView(title: "Spending by category", subtitle: "Selected month compared with the previous month · investments excluded")
            if categories.isEmpty {
                ChartEmptyView(message: "No category spending in this month or the previous month.")
            } else {
                Chart(categories) { category in
                    BarMark(x: .value("SGD", Decimal(category.amountCents) / 100), y: .value("Category", category.category))
                        .foregroundStyle(by: .value("Month", "Selected month"))
                        .position(by: .value("Month", "Selected month"))
                        .annotation(position: .trailing) {
                            Text(category.monthOverMonth.description).font(.caption2).foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("\(category.category), selected month")
                        .accessibilityValue("\(CurrencyFormatter().string(for: category.amountCents)), change \(category.monthOverMonth.description)")
                    if let previous = category.monthOverMonth.previousCents {
                        BarMark(x: .value("SGD", Decimal(previous) / 100), y: .value("Category", category.category))
                            .foregroundStyle(by: .value("Month", "Previous month"))
                            .position(by: .value("Month", "Previous month"))
                            .accessibilityLabel("\(category.category), previous month")
                            .accessibilityValue(CurrencyFormatter().string(for: previous))
                    }
                }
                .chartForegroundStyleScale(["Selected month": Color.teal, "Previous month": Color.indigo.opacity(0.4)])
                .chartLegend(position: .top, alignment: .leading)
                .frame(height: max(240, CGFloat(categories.count * 56)))
                .accessibilityLabel("Category spending comparison with percentage changes from the previous month")
            }
        }
    }
}
