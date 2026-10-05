import SwiftUI

struct DashboardEmptyView: View {
    var body: some View {
        ContentUnavailableView(
            "No transactions for this year",
            systemImage: "chart.bar.xaxis",
            description: Text("Use Transactions to add or import your financial activity.")
        )
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 20))
    }
}
