import SwiftUI

struct ImportRowDetailView: View {
    let candidate: ImportCandidate?
    let selectedCount: Int
    let isWorking: Bool
    let edit: (ImportCandidate) -> Void
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if let candidate {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Row \(candidate.sourceRow) · \(candidate.description)")
                        .font(.callout.weight(.medium))
                        .lineLimit(2)
                    Label(
                        candidate.rejectionReason ?? "This transaction is ready to import.",
                        systemImage: candidate.isReady ? "checkmark.circle" : "exclamationmark.circle"
                    )
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                }
                Spacer(minLength: 12)
                Button("Edit row…", systemImage: "square.and.pencil") { edit(candidate) }
                    .keyboardShortcut("e", modifiers: [.command])
                    .disabled(isWorking)
                    .help("Edit the selected row (⌘E)")
            } else {
                Text(selectedCount > 1 ? "\(selectedCount) rows selected" : "Select rows to inspect, edit, or remove them from the import.")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
            if selectedCount > 0 {
                Button(selectedCount == 1 ? "Remove row" : "Remove \(selectedCount) rows", systemImage: "trash", action: remove)
                    .disabled(isWorking)
                    .help("Remove selected rows from this preview. The source CSV stays unchanged.")
            }
        }
        .frame(minHeight: 36)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
