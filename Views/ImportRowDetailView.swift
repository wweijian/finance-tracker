import SwiftUI

struct ImportRowDetailView: View {
    let candidate: ImportCandidate?
    let highlightedCount: Int
    let allRowsChecked: Bool
    let hasVisibleRows: Bool
    let isWorking: Bool
    let toggleSelectAll: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(allRowsChecked ? "Deselect All" : "Select All", action: toggleSelectAll)
                .disabled(isWorking || !hasVisibleRows)
                .help("Check or uncheck all rows in this filter")
            if let candidate {
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
                Text(highlightedCount > 1 ? "\(highlightedCount) rows highlighted · Use Check highlighted to mark them for deletion" : "Check rows for deletion · Double-click a row to edit")
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
