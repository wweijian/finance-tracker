import SwiftUI

struct DashboardSummaryView: View {
    let snapshot: DashboardSnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            DashboardMetricView(title: "Income", cents: snapshot.incomeCents, tint: .blue, change: snapshot.yearOverYear.income)
            Divider()
            DashboardMetricView(title: "Expenses", cents: snapshot.expenseCents, tint: .gray, change: snapshot.yearOverYear.expenses)
            Divider()
            DashboardMetricView(title: "Net balance", cents: snapshot.netCents, tint: .indigo, change: snapshot.yearOverYear.net)
            Divider()
            DashboardMetricView(title: "Transactions", value: String(snapshot.transactionCount), tint: .secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 4)
    }
}
