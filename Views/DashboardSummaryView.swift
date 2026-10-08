import SwiftUI

struct DashboardSummaryView: View {
    let snapshot: DashboardSnapshot

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), alignment: .leading)], alignment: .leading, spacing: 16) {
            DashboardMetricView(title: "Income", cents: snapshot.incomeCents, tint: .blue, change: snapshot.yearOverYear.income)
            DashboardMetricView(title: "Expenses", cents: snapshot.expenseCents, tint: .orange, change: snapshot.yearOverYear.expenses)
            DashboardMetricView(title: "Investments", cents: snapshot.investmentCents, tint: .purple)
            DashboardMetricView(title: "Net balance", cents: snapshot.netCents, tint: .indigo, change: snapshot.yearOverYear.net)
            DashboardMetricView(title: "Transactions", value: String(snapshot.transactionCount), tint: .secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 4)
    }
}
