import SwiftUI

struct SpendingDistributionSelectionView: View {
    let category: CategoryTotal?
    let totalCents: Int
    var peak: ReportInterval? = nil

    var body: some View {
        VStack(spacing: 8) {
            Text(category?.category ?? "Total spending")
                .font(.callout).foregroundStyle(.secondary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(CurrencyFormatter().string(for: category?.amountCents ?? totalCents))
                .font(.title2.monospacedDigit())
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(category.map { $0.percentage(of: totalCents) } ?? "100%")
                .font(.headline).foregroundStyle(.teal)
            if let category, let peak {
                Text("Highest: \(peak.label) · \(CurrencyFormatter().string(for: peak.spendingCents(for: category.category)))")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    .lineLimit(2).minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: 220)
    }
}
