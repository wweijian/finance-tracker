import SwiftUI

struct ReportChartHeaderView: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer()
            Text("SGD").font(.caption).foregroundStyle(.tertiary)
        }
    }
}
