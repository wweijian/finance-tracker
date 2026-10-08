import SwiftUI

struct SpendingPieChart: View {
    let categoryTotals: [CategoryTotal]
    var peakMonths: [ReportInterval] = []
    var highestTransactions: [String: TransactionListItem] = [:]
    private var spending: [CategoryTotal] { categoryTotals.filter { $0.amountCents > 0 } }
    private var totalCents: Int { spending.reduce(0) { $0 + $1.amountCents } }
    private var categoryColors: [String: Color] {
        Dictionary(uniqueKeysWithValues: spending.map { ($0.category, CategoryChartStyle.color(for: $0.category)) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ReportChartHeaderView(title: "Spending distribution", subtitle: "Share of total expenses · hover over a category · investments excluded")
            if spending.isEmpty {
                ChartEmptyView(message: "No expenses in this period.")
            } else {
                GeometryReader { geometry in
                    if geometry.size.width >= 800 {
                        HStack(alignment: .center, spacing: 24) {
                            SpendingDistributionChart(categories: spending, totalCents: totalCents, colors: categoryColors,
                                                      peakMonths: peakMonths, highestTransactions: highestTransactions)
                                .frame(width: geometry.size.width * 0.48)
                            legend
                        }
                    } else {
                        VStack(spacing: 16) {
                            SpendingDistributionChart(categories: spending, totalCents: totalCents, colors: categoryColors,
                                                      peakMonths: peakMonths, highestTransactions: highestTransactions)
                                .frame(height: geometry.size.height * (highestTransactions.isEmpty ? 0.58 : 0.74))
                            legend
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var legend: some View {
        SpendingDistributionLegendView(categories: spending, totalCents: totalCents)
    }
}
