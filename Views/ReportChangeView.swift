import SwiftUI

struct ReportChangeView: View {
    let monthOverMonth: FinancialChange

    var body: some View {
        Text("MoM: \(monthOverMonth.description)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .help("Change from previous month: \(monthOverMonth.differenceCents.map { CurrencyFormatter().string(for: $0) } ?? "No prior data")")
    }
}
