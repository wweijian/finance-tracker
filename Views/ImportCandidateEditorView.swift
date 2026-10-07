import SwiftUI

struct ImportCandidateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var candidate: ImportCandidate

    let categories: [String]
    let errorMessage: String?
    let isWorking: Bool
    let save: (ImportCandidate) -> Void
    let remove: () -> Void

    init(candidate: ImportCandidate, categories: [String], errorMessage: String?, isWorking: Bool,
         save: @escaping (ImportCandidate) -> Void, remove: @escaping () -> Void) {
        _candidate = State(initialValue: candidate)
        self.categories = categories
        self.errorMessage = errorMessage
        self.isWorking = isWorking
        self.save = save
        self.remove = remove
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit import transaction").font(.title3.weight(.semibold))
            Text("Row \(candidate.sourceRow) · Changes apply to this import preview.")
                .font(.caption).foregroundStyle(.secondary)
            ImportCandidateFieldsView(candidate: $candidate, categories: categories)
                .disabled(isWorking)
            if let message = errorMessage ?? candidate.rejectionReason {
                Text(message).foregroundStyle(.red).textSelection(.enabled)
            }
            HStack {
                Button("Delete from preview", systemImage: "trash", role: .destructive, action: remove)
                Spacer()
                Button("Cancel", action: dismiss.callAsFunction)
                    .keyboardShortcut(.cancelAction)
                Button("Save") { save(candidate) }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .disabled(isWorking)
        }
        .padding(24)
        .frame(width: 560, height: candidate.ledgerlyDetails == nil ? 540 : 600)
        .interactiveDismissDisabled(isWorking)
    }
}
