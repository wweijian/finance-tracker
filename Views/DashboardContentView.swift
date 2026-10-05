import SwiftUI

struct DashboardContentView: View {
    let snapshot: DashboardSnapshot
    let isLoading: Bool
    let errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading dashboard…")
                    .frame(maxWidth: .infinity, minHeight: 320)
            } else if let errorMessage {
                DashboardErrorView(message: errorMessage)
            } else if snapshot.transactionCount == 0 {
                DashboardEmptyView()
            } else {
                SpendingBreakdownView(categoryTotals: snapshot.categoryTotals)
            }
        }
    }
}
