import Charts
import SwiftUI

struct SpendingBarChart: View {
    let categoryTotals: [CategoryTotal]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category comparison")
                .font(.headline)
            Chart(categoryTotals) { total in
                BarMark(
                    x: .value("Amount", total.amount),
                    y: .value("Category", total.category)
                )
                .foregroundStyle(.indigo.gradient)
            }
            .frame(height: 260)
            .accessibilityLabel("Bar chart comparing spending categories")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 20))
    }
}
