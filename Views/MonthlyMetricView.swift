import SwiftUI

struct MonthlyMetricView: View {
    let title: String
    let cents: Int
    let monthOverMonth: FinancialChange
    let yearOverYear: FinancialChange

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline)
            Text(CurrencyFormatter().string(for: cents)).font(.title3.monospacedDigit())
            ReportChangeView(monthOverMonth: monthOverMonth, yearOverYear: yearOverYear)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
