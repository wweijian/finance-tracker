import Charts
import SwiftUI

struct MonthlySpendingChart: View {
    let months: [MonthlyReport]
    let selectedMonth: String?
    @State private var hoveredMonth: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReportChartHeaderView(title: "Monthly spending", subtitle: "Twelve months ending with the selected month · investments excluded")
            if months.allSatisfy({ $0.totals.expenseCents == 0 }) {
                ChartEmptyView(message: "No spending in these months.")
            } else {
                Chart(months, id: \.startDate) { month in
                    BarMark(x: .value("Month", month.periodLabel), y: .value("SGD", Decimal(month.totals.expenseCents) / 100))
                        .foregroundStyle(month.startDate == selectedMonth ? Color.teal : Color.indigo.opacity(0.4))
                        .cornerRadius(3)
                        .accessibilityLabel("\(month.periodLabel) spending")
                        .accessibilityValue(CurrencyFormatter().string(for: month.totals.expenseCents))
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .onContinuousHover { phase in
                                switch phase {
                                case .active(let point):
                                    if let frame = proxy.plotFrame {
                                        hoveredMonth = proxy.value(atX: point.x - geometry[frame].minX, as: String.self)
                                    }
                                case .ended: hoveredMonth = nil
                                }
                            }
                    }
                }
                .frame(height: 280)
                Text(hoveredReport.map { "\($0.periodLabel): \(CurrencyFormatter().string(for: $0.totals.expenseCents))" } ?? "Hover over a month to see its spending")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(height: 18)
                .accessibilityLabel("Monthly spending over the past twelve months")
            }
        }
    }

    private var hoveredReport: MonthlyReport? {
        months.first { $0.periodLabel == hoveredMonth }
    }
}
