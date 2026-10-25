import SwiftUI

struct ImportPreviewView: View {
    @Binding var candidates: [ImportCandidate]
    let isWorking: Bool
    let removedRowCount: Int
    let remove: (Set<String>) -> Void
    let undoRemovals: () -> Void
    let categories: [String]
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
                .frame(width: 470)
                Spacer()
                if removedRowCount > 0 {
                    Button("Undo removals (\(removedRowCount))", systemImage: "arrow.uturn.backward", action: undoRemovals)
                        .help("Put all removed rows back into this preview")
                }
                Text("\(preview.candidates.count) transactions")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))
            Divider()
            if candidates.isEmpty {
                ContentUnavailableView(
                    "No rows left to import", systemImage: "list.bullet.rectangle",
                    description: Text("Undo removals to bring rows back, or choose another CSV.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ImportCandidateTableView(candidates: $candidates, selection: $selection,
                                         checkedRowIDs: $checkedRowIDs, remove: remove,
                                         categories: categories, filter: filter)
            }
            if let selectedCandidate {
                Divider()
                ImportRowDetailView(candidate: selectedCandidate)
            }
        }
        .disabled(isWorking)
        .onChange(of: filter) { selection = [] }
        .onChange(of: preview.candidates) {
            selection.formIntersection(visibleCandidates.map(\.id))
            checkedRowIDs.formIntersection(preview.candidates.map(\.id))
        }
    }

    private var preview: ImportPreview { ImportPreview(candidates: candidates) }
    private var visibleCandidates: [ImportCandidate] { preview.rows(matching: filter) }
    private var selectedCandidate: ImportCandidate? {
        selection.count == 1 ? visibleCandidates.first { selection.contains($0.id) } : nil
    }
}
