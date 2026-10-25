import SwiftUI

struct ImportCandidateTableView: View {
    @Binding var candidates: [ImportCandidate]
    @Binding var selection: Set<String>
    @Binding var checkedRowIDs: Set<String>
    let remove: (Set<String>) -> Void
    let categories: [String]
    var filter: ImportRowFilter = .all
    @State private var focusedRowID: String?
    @StateObject private var scrollController = ImportTableScrollController()
    @State private var sortOrder = [KeyPathComparator(\ImportCandidate.sourceRow)]

    var body: some View {
        VStack(spacing: 0) {
            table
            Divider()
            ImportTableActionsView(
                highlightedCount: selection.count,
                checkedCount: checkedRowIDs.count,
                allHighlightedChecked: !selection.isEmpty && selection.isSubset(of: checkedRowIDs),
                allRowsChecked: allRowsChecked,
                hasVisibleRows: !visibleCandidates.isEmpty,
                toggleAll: toggleAll,
                toggleChecks: { toggleChecks(selection) },
                remove: { remove(checkedRowIDs) },
                scrollController: scrollController
            )
        }
    }

    private var table: some View {
        Table(visibleCandidates.sorted(using: sortOrder), selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Row", value: \.sourceRow) { candidate in
                HStack(spacing: 8) {
                    Toggle("Select row \(candidate.sourceRow) for deletion", isOn: Binding(
                    get: { checkedRowIDs.contains(candidate.id) },
                    set: { isSelected in
                        if isSelected { checkedRowIDs.insert(candidate.id) }
                        else { checkedRowIDs.remove(candidate.id) }
                    }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()
                    Text(String(candidate.sourceRow)).font(.caption).monospacedDigit().foregroundStyle(.secondary)
                }
            }.width(70)
            TableColumn("Status", value: \.statusLabel) { candidate in
                ImportCandidateStatusCell(candidate: candidate)
            }.width(90)
            TableColumn("Date", value: \.transactionDate) { candidate in
                ImportCandidateTextCell(title: "Date", text: binding(for: candidate).transactionDate,
                                        editingChanged: { focusChanged($0, rowID: candidate.id) })
                    .monospacedDigit()
            }.width(118)
            TableColumn("Description", value: \.description) { candidate in
                ImportCandidateTextCell(title: "Description", text: binding(for: candidate).description,
                                        editingChanged: { focusChanged($0, rowID: candidate.id) })
            }.width(min: 220, ideal: 280)
            TableColumn("Type", value: \.transactionType.rawValue) { candidate in
                ImportCandidateTypeCell(candidate: binding(for: candidate))
            }.width(106)
            TableColumn("Amount", sortUsing: KeyPathComparator(\ImportCandidate.amountCents)) { candidate in
                ImportCandidateAmountCell(candidate: binding(for: candidate),
                                          editingChanged: { focusChanged($0, rowID: candidate.id) })
            }.width(145)
            TableColumn("Category", value: \.category) { candidate in
                ImportCandidateCategoryCell(category: binding(for: candidate).category, categories: categories)
            }.width(min: 160, ideal: 180)
            TableColumn("Remarks", value: \.remarks) { candidate in
                ImportCandidateTextCell(title: "Remarks", text: binding(for: candidate).remarks,
                                        editingChanged: { focusChanged($0, rowID: candidate.id) })
            }.width(min: 220, ideal: 280)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .font(.system(size: 13))
        .scrollIndicators(.visible)
        .background {
            ImportTableScrollBridge(controller: scrollController)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        }
        .overlay {
            if visibleCandidates.isEmpty {
                ImportPreviewEmptyView(filter: filter)
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: filter) { focusedRowID = nil }
        .contextMenu(forSelectionType: String.self) { ids in
            if !ids.isEmpty {
                Button(ids.isSubset(of: checkedRowIDs) ? "Uncheck highlighted rows" : "Check highlighted rows") {
                    toggleChecks(ids)
                }
            }
            if !checkedRowIDs.isEmpty {
                Button("Delete checked (\(checkedRowIDs.count))", systemImage: "trash", role: .destructive) {
                    remove(checkedRowIDs)
                }
            }
        }
        .accessibilityLabel("CSV import preview. Checkboxes mark rows for deletion. Click or use arrow keys to highlight rows without changing their checkboxes. Shift-click highlights a range; Command-click highlights separate rows. All transaction fields are editable immediately. Changes are checked automatically and stay in this preview until imported. Click column headings to sort.")
    }

    private var visibleCandidates: [ImportCandidate] {
        var rows = ImportPreview(candidates: candidates).rows(matching: filter)
        // Keep a row under the user's cursor while edits change its validation status.
        if let focusedRowID, !rows.contains(where: { $0.id == focusedRowID }),
           let focused = candidates.first(where: { $0.id == focusedRowID }) {
            rows.append(focused)
        }
        return rows
    }

    private func binding(for candidate: ImportCandidate) -> Binding<ImportCandidate> {
        Binding(
            get: { candidates.first { $0.id == candidate.id } ?? candidate },
            set: { updated in
                guard let index = candidates.firstIndex(where: { $0.id == candidate.id }) else { return }
                candidates[index] = updated
            }
        )
    }

    private func focusChanged(_ focused: Bool, rowID: String) {
        if focused { focusedRowID = rowID }
        else if focusedRowID == rowID { focusedRowID = nil }
    }

    private func toggleChecks(_ ids: Set<String>) {
        guard !ids.isEmpty else { return }
        if ids.isSubset(of: checkedRowIDs) { checkedRowIDs.subtract(ids) }
        else { checkedRowIDs.formUnion(ids) }
    }

    private var allRowsChecked: Bool {
        !visibleCandidates.isEmpty && Set(visibleCandidates.map(\.id)).isSubset(of: checkedRowIDs)
    }

    private func toggleAll() {
        let ids = Set(visibleCandidates.map(\.id))
        if allRowsChecked { checkedRowIDs.subtract(ids) }
        else { checkedRowIDs.formUnion(ids) }
    }

}
