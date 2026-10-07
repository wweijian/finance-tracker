import SwiftUI

struct DashboardEmptyView: View {
    var body: some View {
        ContentUnavailableView(
            "No transactions in this period",
            systemImage: "chart.bar.xaxis",
            description: Text("Choose another year, widen the date range, or use the + button to add a transaction or import a CSV.")
        )
        .frame(maxWidth: .infinity, minHeight: 320)
    }
}
