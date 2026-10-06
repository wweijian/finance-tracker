import SwiftUI

struct ImportPreviewView: View {
    let preview: ImportPreview
    let isWorking: Bool
    let edit: (ImportCandidate) -> Void
    let removedRowCount: Int
    let remove: (Set<String>) -> Void
    let undoRemovals: () -> Void
    @State private var filter: ImportRowFilter = .all
    @State private var selection: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Preview rows", selection: $filter) {
                    ForEach(ImportRowFilter.allCases) { filter in
                        Text("\(filter.rawValue) (\(preview.count(for: filter)))").tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 370)
                Spacer()
                if removedRowCount > 0 {
                    Button("Undo removals", systemImage: "arrow.uturn.backward", action: undoRemovals)
                        .help("Put all removed rows back into this preview")
                }
                Text(removedRowCount == 0 ? "\(preview.candidates.count) rows in file" : "\(preview.candidates.count) remaining · \(removedRowCount) removed")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .controlSize(.small)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))
            Divider()
            if visibleCandidates.isEmpty {
                ContentUnavailableView(
                    preview.candidates.isEmpty ? "No rows left to import" : filter == .needsAttention ? "No rows need attention" : "No ready rows",
                    systemImage: filter == .needsAttention ? "checkmark.circle" : "list.bullet.rectangle",
                    description: Text(preview.candidates.isEmpty ? "Undo removals to bring rows back, or choose another CSV." : filter == .needsAttention ? "The remaining rows have passed validation." : "Review the rows that need attention, then correct their dates, amounts, or categories.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ImportCandidateTableView(candidates: visibleCandidates, selection: $selection, edit: edit, remove: remove)
            }
            Divider()
            ImportRowDetailView(candidate: selectedCandidate, selectedCount: selection.count, isWorking: isWorking, edit: edit, remove: { remove(selection) })
        }
        .disabled(isWorking)
        .onChange(of: filter) { selection = [] }
        .onChange(of: preview.candidates) {
            selection.formIntersection(visibleCandidates.map(\.id))
        }
    }

    private var visibleCandidates: [ImportCandidate] { preview.rows(matching: filter) }
    private var selectedCandidate: ImportCandidate? {
        selection.count == 1 ? visibleCandidates.first { selection.contains($0.id) } : nil
    }
}
