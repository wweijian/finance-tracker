import SwiftUI

struct SpendingBreakdownView: View {
    let categoryTotals: [CategoryTotal]

    var body: some View {
        HStack(alignment: .top, spacing: 28) {
            SpendingPieChart(categoryTotals: categoryTotals)
                .frame(width: 290)
            Divider()
            SpendingBarChart(categoryTotals: categoryTotals)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
