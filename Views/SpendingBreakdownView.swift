import SwiftUI

struct SpendingBreakdownView: View {
    let categoryTotals: [CategoryTotal]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            SpendingPieChart(categoryTotals: categoryTotals)
                .frame(maxWidth: .infinity)
            Divider()
            SpendingBarChart(categoryTotals: categoryTotals)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
