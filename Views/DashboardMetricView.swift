import SwiftUI

struct DashboardMetricView: View {
    let title: String
    let value: String
    let tint: Color
    var detail: String? = nil

    init(title: String, cents: Int, tint: Color, change: FinancialChange? = nil) {
        self.title = title
        value = CurrencyFormatter().string(for: cents)
        self.tint = tint
        detail = change.map { $0.previousCents == nil ? "No prior-year data" : "\($0.description) vs last year" }
    }

    init(title: String, value: String, tint: Color) {
        self.title = title
        self.value = value
        self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(tint).frame(width: 5, height: 5).accessibilityHidden(true)
                Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 26, weight: .regular))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(detail ?? "In the selected period")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
