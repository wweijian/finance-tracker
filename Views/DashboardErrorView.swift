import SwiftUI

struct DashboardErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack {
            ContentUnavailableView(
                "Dashboard unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
            Button("Retry", action: retry)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }
}
