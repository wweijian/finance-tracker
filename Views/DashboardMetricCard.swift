import SwiftUI

struct DashboardMetricCard: View {
    let title: String
    let value: String
    let tint: Color

    init(title: String, cents: Int, tint: Color) {
        self.title = title
        value = CurrencyFormatter().string(for: cents)
        self.tint = tint
    }

    init(title: String, value: String, tint: Color) {
        self.title = title
        self.value = value
        self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
    }
}
