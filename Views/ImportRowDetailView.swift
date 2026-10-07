import SwiftUI

struct ImportRowDetailView: View {
    let candidate: ImportCandidate?
    let highlightedCount: Int
    let checkedCount: Int
    let allRowsChecked: Bool
    let hasVisibleRows: Bool
    let isWorking: Bool
    let toggleSelectAll: () -> Void
    let edit: () -> Void
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(allRowsChecked ? "Deselect All" : "Select All", action: toggleSelectAll)
                .disabled(isWorking || !hasVisibleRows)
                .help("Check or uncheck all rows in this filter")
            if checkedCount > 0 {
                Button("Delete checked (\(checkedCount))", systemImage: "trash", role: .destructive, action: remove)
                    .disabled(isWorking)
                    .help("Confirm removal of checked rows from this preview. The source CSV stays unchanged.")
            }
            if let candidate {
                Button("Edit…", systemImage: "pencil", action: edit)
                    .disabled(isWorking)
                    .help("Edit the highlighted transaction. You can also double-click a row or press Return.")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Row \(candidate.sourceRow) · \(candidate.description)")
                        .font(.callout.weight(.medium))
                        .lineLimit(2)
                    Label(
                        candidate.rejectionReason ?? (candidate.ledgerlyDetails?.deletedAt == nil
                            ? "This transaction is ready to import."
                            : "This transaction will be imported as deleted."),
                        systemImage: candidate.isReady ? "checkmark.circle" : "exclamationmark.circle"
                    )
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                }
            } else {
                Text(highlightedCount > 1 ? "\(highlightedCount) rows highlighted · Space to check or uncheck" : "Check rows for deletion · Double-click or Enter to edit")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
        }
        .frame(minHeight: 36)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
