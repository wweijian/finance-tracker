import Charts
import SwiftUI

struct SpendingBarChart: View {
    let categoryTotals: [CategoryTotal]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReportChartHeaderView(title: "Category comparison", subtitle: "Selected period and the matching period last year")
            if categoryTotals.allSatisfy({ $0.amountCents == 0 && ($0.previousYearCents ?? 0) == 0 }) {
                ChartEmptyView(message: "No expenses in this period or the matching period last year.")
            } else {
                Chart(categoryTotals) { total in
                    BarMark(x: .value("SGD", total.amount), y: .value("Category", total.category))
                        .foregroundStyle(by: .value("Period", "Selected period"))
                        .position(by: .value("Period", "Selected period"))
                        .accessibilityLabel("\(total.category), selected period")
                        .accessibilityValue(CurrencyFormatter().string(for: total.amountCents))
                    if let previous = total.previousYearCents {
                        BarMark(x: .value("SGD", Decimal(previous) / 100), y: .value("Category", total.category))
                            .foregroundStyle(by: .value("Period", "Prior year"))
                            .position(by: .value("Period", "Prior year"))
                            .accessibilityLabel("\(total.category), prior year")
                            .accessibilityValue(CurrencyFormatter().string(for: previous))
                    }
                }
                .chartForegroundStyleScale(["Selected period": Color.blue, "Prior year": Color.gray.opacity(0.45)])
                .chartLegend(position: .top, alignment: .leading, spacing: 14)
                .chartXAxis {
                    AxisMarks {
                        AxisGridLine().foregroundStyle(Color.secondary.opacity(0.12))
                        AxisValueLabel()
                    }
                }
                .frame(height: max(260, CGFloat(categoryTotals.count * 42)))
                .accessibilityLabel("Category spending compared with the matching period last year")
                ForEach(categoryTotals) { total in
                    HStack {
                        Text(total.category)
                        Spacer()
                        Text(CurrencyFormatter().string(for: total.amountCents)).monospacedDigit()
                        Text("YoY: \(total.yearOverYear.description)").foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
