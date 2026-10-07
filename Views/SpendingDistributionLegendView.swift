import SwiftUI

struct SpendingDistributionLegendView: View {
    let categories: [CategoryTotal]
    let totalCents: Int
    let colors: [String: Color]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(categories) { category in
                HStack(spacing: 8) {
                    Circle().fill(colors[category.category] ?? .teal).frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                    Text(category.category)
                    Spacer()
                    Text(CurrencyFormatter().string(for: category.amountCents)).foregroundStyle(.secondary)
                    Text(category.percentage(of: totalCents))
                        .fontWeight(.medium).frame(width: 58, alignment: .trailing)
                }
                .font(.callout).monospacedDigit()
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
