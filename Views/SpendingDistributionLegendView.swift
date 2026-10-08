import SwiftUI

struct SpendingDistributionLegendView: View {
    let categories: [CategoryTotal]
    let totalCents: Int

    var body: some View {
        Table(categories) {
            TableColumn("Category", value: \.category)
                .width(min: 90, ideal: 120)
            TableColumn("Spending") { category in
                Text(CurrencyFormatter().string(for: category.amountCents))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }.width(min: 90, ideal: 110)
            TableColumn("Share") { category in
                Text(category.percentage(of: totalCents)).monospacedDigit()
            }.width(min: 50, ideal: 60)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .accessibilityLabel("Spending by category, amount and percentage of total expenses")
    }
}
