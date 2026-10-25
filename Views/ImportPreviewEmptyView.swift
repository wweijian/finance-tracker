import SwiftUI

struct ImportPreviewEmptyView: View {
    let filter: ImportRowFilter

    var body: some View {
        ContentUnavailableView(
            filter == .needsAttention ? "No rows need attention" : "No ready rows",
            systemImage: filter == .needsAttention ? "checkmark.circle" : "list.bullet.rectangle",
            description: Text(filter == .needsAttention
                              ? "The remaining rows have passed validation."
                              : "Switch to All rows to correct rejected transactions.")
        )
    }
}
