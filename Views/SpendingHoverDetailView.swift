import SwiftUI

struct SpendingHoverDetailView: View {
    let interval: ReportInterval?
    let category: String?
    let peak: ReportInterval?

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 8) {
                if let interval, let category {
                    HStack {
                        Text("\(category) · \(interval.startDate)").fontWeight(.medium)
                        Spacer()
                        Text(CurrencyFormatter().string(for: interval.spendingCents(for: category)))
                    }
                    HighestTransactionDetailView(transaction: interval.highestSpendingTransaction(for: category))
                    if let peak {
                        Text("Highest month: \(peak.label) · \(CurrencyFormatter().string(for: peak.spendingCents(for: category)))")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Hover over a category to see spending and the full details of its highest transaction.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.callout)
        .monospacedDigit()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 116)
        .accessibilityElement(children: .combine)
    }
}
