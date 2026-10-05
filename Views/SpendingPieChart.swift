import Charts
import SwiftUI

struct SpendingPieChart: View {
    let categoryTotals: [CategoryTotal]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by category")
                .font(.headline)
            Chart(categoryTotals) { total in
                SectorMark(
                    angle: .value("Spending", total.amount),
                    innerRadius: .ratio(0.58)
                )
                .foregroundStyle(by: .value("Category", total.category))
            }
            .chartLegend(position: .bottom)
            .frame(height: 260)
            .accessibilityLabel("Pie chart of spending by category")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 20))
    }
}
