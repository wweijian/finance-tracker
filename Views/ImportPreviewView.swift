import SwiftUI

struct ImportPreviewView: View {
    let preview: ImportPreview
    let isWorking: Bool
    let removedRowCount: Int
    let remove: (Set<String>) -> Void
    let undoRemovals: () -> Void
    let edit: (String) -> Void
    @State private var filter: ImportRowFilter = .all
    @State private var selection: Set<String> = []
    @State private var checkedRowIDs: Set<String> = []

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
                    description: Text(preview.candidates.isEmpty ? "Undo removals to bring rows back, or choose another CSV." : filter == .needsAttention ? "The remaining rows have passed validation." : "Edit rejected rows in the preview to correct them, or choose another CSV.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ImportCandidateTableView(candidates: visibleCandidates, selection: $selection,
                                         checkedRowIDs: $checkedRowIDs, edit: edit, remove: remove)
            }
            Divider()
            ImportRowDetailView(
                candidate: selectedCandidate,
                highlightedCount: selection.count,
                allRowsChecked: allRowsChecked,
                hasVisibleRows: !visibleCandidates.isEmpty,
                isWorking: isWorking,
                toggleSelectAll: toggleSelectAll
            )
        }
        .disabled(isWorking)
        .onChange(of: filter) { selection = [] }
        .onChange(of: preview.candidates) {
            selection.formIntersection(visibleCandidates.map(\.id))
            checkedRowIDs.formIntersection(preview.candidates.map(\.id))
        }
    }

    private var visibleCandidates: [ImportCandidate] { preview.rows(matching: filter) }
    private var allRowsChecked: Bool {
        !visibleCandidates.isEmpty && Set(visibleCandidates.map(\.id)).isSubset(of: checkedRowIDs)
    }
    private func toggleSelectAll() {
        let visibleIDs = Set(visibleCandidates.map(\.id))
        if allRowsChecked { checkedRowIDs.subtract(visibleIDs) }
        else { checkedRowIDs.formUnion(visibleIDs) }
    }
    private var selectedCandidate: ImportCandidate? {
        selection.count == 1 ? visibleCandidates.first { selection.contains($0.id) } : nil
    }
}
