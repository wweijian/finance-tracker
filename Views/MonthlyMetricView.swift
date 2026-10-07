import SwiftUI

struct MonthlyMetricView: View {
    let title: String
    let cents: Int?
    let monthOverMonth: FinancialChange?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline)
            Text(cents.map { CurrencyFormatter().string(for: $0) } ?? "—").font(.title3.monospacedDigit())
            if let monthOverMonth {
                ReportChangeView(monthOverMonth: monthOverMonth)
            } else if cents == nil {
                Text("No prior data").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
