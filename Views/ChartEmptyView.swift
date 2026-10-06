import SwiftUI

struct ChartEmptyView: View {
    let message: String

    var body: some View {
        ContentUnavailableView("No chart data", systemImage: "chart.bar", description: Text(message))
            .frame(maxWidth: .infinity, minHeight: 260)
    }
}
