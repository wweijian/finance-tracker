import SwiftUI

struct CategoryComparisonTableView: View {
    let categories: [CategorySpendingComparison]
    let scope: DashboardScope
    @State private var sortOrder = [
        KeyPathComparator(\CategorySpendingComparison.amountCents, order: .reverse),
        KeyPathComparator(\CategorySpendingComparison.category)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ReportChartHeaderView(title: "Category comparison",
                                  subtitle: "\(scope == .monthly ? "Month-on-month" : "Year-on-year") spending · investments excluded")
            if categories.isEmpty {
                ContentUnavailableView("No category spending", systemImage: "list.bullet.rectangle",
                                       description: Text("No expenses in this period or the previous one."))
            } else {
                Table(categories.sorted(using: sortOrder), sortOrder: $sortOrder) {
                    TableColumn("Category", value: \.category)
                        .width(min: 110, ideal: 160)
                    TableColumn(scope == .monthly ? "This month" : "This year", value: \.amountCents) { category in
                        amount(category.amountCents)
                    }.width(min: 90, ideal: 120)
                    TableColumn(scope == .monthly ? "Last month" : "Last year", sortUsing: KeyPathComparator(\CategorySpendingComparison.change.previousCents)) { category in
                        amount(category.change.previousCents)
                    }.width(min: 90, ideal: 120)
                    TableColumn("Difference", sortUsing: KeyPathComparator(\CategorySpendingComparison.change.differenceCents)) { category in
                        amount(category.change.differenceCents)
                    }.width(min: 90, ideal: 120)
                    TableColumn("Change", sortUsing: KeyPathComparator(\CategorySpendingComparison.change.percentage)) { category in
                        Text(category.change.description).monospacedDigit()
                    }.width(min: 90, ideal: 120)
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .accessibilityLabel("Category spending compared with the previous period. Click column headings to sort.")
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .accessibilityIdentifier("categoryComparisonTable")
    }

    private func amount(_ cents: Int?) -> some View {
        Text(cents.map { CurrencyFormatter().string(for: $0) } ?? "—")
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
