import SwiftUI

struct SpendingDistributionSelectionView: View {
    let category: CategoryTotal?
    let totalCents: Int

    var body: some View {
        VStack(spacing: 8) {
            Text(category?.category ?? "Total spending")
                .font(.callout).foregroundStyle(.secondary)
            Text(CurrencyFormatter().string(for: category?.amountCents ?? totalCents))
                .font(.title2.monospacedDigit())
            Text(category.map { $0.percentage(of: totalCents) } ?? "100%")
                .font(.headline).foregroundStyle(.teal)
        }
        .frame(width: 220)
    }
}
