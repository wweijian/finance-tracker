import SwiftUI

struct CategoryMonthlyComparisonView: View {
    let categories: [CategoryMonthlyReport]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category detail").font(.system(size: 13, weight: .semibold))
            if categories.isEmpty {
                Text("No category spending in this month or either comparison period.").foregroundStyle(.secondary)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 32, verticalSpacing: 10) {
                    ForEach(categories) { category in
                        GridRow {
                            Text(category.category)
                            Text(CurrencyFormatter().string(for: category.amountCents)).monospacedDigit()
                            ReportChangeView(monthOverMonth: category.monthOverMonth, yearOverYear: category.yearOverYear)
                        }.accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}
