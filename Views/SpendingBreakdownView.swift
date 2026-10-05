import SwiftUI

struct SpendingBreakdownView: View {
    let categoryTotals: [CategoryTotal]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 24) {
                SpendingPieChart(categoryTotals: categoryTotals)
                SpendingBarChart(categoryTotals: categoryTotals)
            }
            VStack(alignment: .leading, spacing: 24) {
                SpendingPieChart(categoryTotals: categoryTotals)
                SpendingBarChart(categoryTotals: categoryTotals)
            }
        }
    }
}
