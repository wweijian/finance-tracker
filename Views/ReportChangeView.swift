import SwiftUI

struct ReportChangeView: View {
    let monthOverMonth: FinancialChange
    let yearOverYear: FinancialChange

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("MoM: \(monthOverMonth.description)")
            Text("YoY: \(yearOverYear.description)")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
        .help("MoM amount change: \(amountChange(monthOverMonth)); YoY amount change: \(amountChange(yearOverYear))")
    }

    private func amountChange(_ change: FinancialChange) -> String {
        change.differenceCents.map { CurrencyFormatter().string(for: $0) } ?? "No prior data"
    }
}
