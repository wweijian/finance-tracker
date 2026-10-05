import SwiftUI

struct DashboardErrorView: View {
    let message: String

    var body: some View {
        ContentUnavailableView(
            "Dashboard unavailable",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }
}
