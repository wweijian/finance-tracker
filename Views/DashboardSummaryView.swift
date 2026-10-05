import SwiftUI

struct DashboardSummaryView: View {
    let snapshot: DashboardSnapshot

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 175), spacing: 16)],
            spacing: 16
        ) {
            DashboardMetricCard(title: "Income", cents: snapshot.incomeCents, tint: .green)
            DashboardMetricCard(title: "Expenses", cents: snapshot.expenseCents, tint: .red)
            DashboardMetricCard(title: "Net", cents: snapshot.netCents, tint: netTint)
            DashboardMetricCard(title: "Transactions", value: String(snapshot.transactionCount), tint: .blue)
        }
    }

    private var netTint: Color {
        snapshot.netCents >= 0 ? .teal : .orange
    }
}
