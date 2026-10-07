import SwiftUI

struct SpendingPieChart: View {
    let categoryTotals: [CategoryTotal]
    private let colors: [Color] = [.teal, .indigo, .orange, .purple, .blue, .mint, .pink, .brown]
    private var spending: [CategoryTotal] { categoryTotals.filter { $0.amountCents > 0 } }
    private var totalCents: Int { spending.reduce(0) { $0 + $1.amountCents } }
    private var categoryColors: [String: Color] {
        Dictionary(uniqueKeysWithValues: spending.enumerated().map { ($0.element.category, colors[$0.offset % colors.count]) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ReportChartHeaderView(title: "Spending distribution", subtitle: "Share of total expenses · hover over a category · investments excluded")
            if spending.isEmpty {
                ChartEmptyView(message: "No expenses in this period.")
            } else {
                HStack(alignment: .center, spacing: 32) {
                    SpendingDistributionChart(categories: spending, totalCents: totalCents, colors: categoryColors)
                    SpendingDistributionLegendView(categories: spending, totalCents: totalCents, colors: categoryColors)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
