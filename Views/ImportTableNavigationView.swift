import SwiftUI

struct ImportTableNavigationView: View {
    let showFirstColumns: () -> Void
    let showLastColumns: () -> Void

    var body: some View {
        HStack {
            Button("First columns", systemImage: "chevron.left", action: showFirstColumns)
                .help("Show row numbers, dates, and descriptions")
            Spacer()
            Text("Scroll sideways or use these buttons to see every column")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Last columns", systemImage: "chevron.right", action: showLastColumns)
                .help("Show remarks and validation status")
        }
        .font(.caption)
        .controlSize(.small)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
