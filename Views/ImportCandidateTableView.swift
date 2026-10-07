import SwiftUI

struct ImportCandidateTableView: View {
    let candidates: [ImportCandidate]
    @Binding var selection: Set<String>
    @Binding var checkedRowIDs: Set<String>
    let edit: (String) -> Void
    let remove: (Set<String>) -> Void
    @State private var sortOrder = [KeyPathComparator(\ImportCandidate.sourceRow)]

    var body: some View {
        ImportTableScrollView(
            activateSelection: { editSelection(selection) },
            toggleChecks: { toggleChecks(selection) },
            deleteSelection: { if !checkedRowIDs.isEmpty { remove(checkedRowIDs) } }
        ) {
            table
        }
    }

    private var table: some View {
        Table(candidates.sorted(using: sortOrder), selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Select") { candidate in
                Toggle("Select row \(candidate.sourceRow) for deletion", isOn: Binding(
                    get: { checkedRowIDs.contains(candidate.id) },
                    set: { isSelected in
                        if isSelected { checkedRowIDs.insert(candidate.id) }
                        else { checkedRowIDs.remove(candidate.id) }
                    }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()
            }.width(44)
            TableColumn("Row", value: \.sourceRow) { candidate in
                Text(String(candidate.sourceRow)).monospacedDigit().foregroundStyle(.secondary)
            }.width(36)
            TableColumn("Date", value: \.transactionDate) { candidate in
                Text(candidate.transactionDate).monospacedDigit().foregroundStyle(.secondary)
            }.width(92)
            TableColumn("Description", value: \.description) { candidate in
                Text(candidate.description).lineLimit(1).help(candidate.description)
            }.width(min: 150, ideal: 200)
            TableColumn("Type", value: \.transactionType.rawValue) { candidate in
                Text(candidate.transactionType.rawValue.capitalized).foregroundStyle(.secondary)
            }.width(68)
            TableColumn("Amount", sortUsing: KeyPathComparator(\ImportCandidate.amountCents)) { candidate in
                Text(candidate.amount.isEmpty ? "—" : "\(candidate.amount) \(candidate.currency)")
                    .monospacedDigit().frame(maxWidth: .infinity, alignment: .trailing)
            }.width(110)
            TableColumn("Category", value: \.category) { candidate in
                Text(candidate.category).foregroundStyle(.secondary).lineLimit(1).help(candidate.category)
            }.width(min: 110, ideal: 125)
            TableColumn("Remarks", value: \.remarks) { candidate in
                Text(candidate.remarks.isEmpty ? "—" : candidate.remarks)
                    .foregroundStyle(.secondary).lineLimit(1)
                    .help(candidate.remarks.isEmpty ? "No remarks" : candidate.remarks)
            }.width(min: 100, ideal: 140)
            TableColumn("Status", value: \.statusLabel) { candidate in
                Label(candidate.statusLabel, systemImage: candidate.isReady ? "checkmark.circle" : "exclamationmark.circle")
                    .foregroundStyle(candidate.isReady ? Color.secondary : .orange)
                    .lineLimit(1)
                    .help(candidate.rejectionReason ?? "Ready to import")
            }.width(min: 160, ideal: 180)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .scrollIndicators(.visible)
        .contextMenu(forSelectionType: String.self) { ids in
            if ids.count == 1, let id = ids.first {
                Button("Edit transaction…", systemImage: "pencil") { edit(id) }
            }
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
        } primaryAction: { ids in
            editSelection(ids)
        }
        .accessibilityLabel("CSV import preview. Checkboxes mark rows for deletion. Click or use arrow keys to highlight rows without changing their checkboxes. Shift-click highlights a range; Command-click highlights separate rows. Space checks or unchecks highlighted rows. Double-click or Return edits one highlighted transaction. Click column headings to sort.")
    }

    private func toggleChecks(_ ids: Set<String>) {
        guard !ids.isEmpty else { return }
        if ids.isSubset(of: checkedRowIDs) { checkedRowIDs.subtract(ids) }
        else { checkedRowIDs.formUnion(ids) }
    }

    private func editSelection(_ ids: Set<String>) {
        guard ids.count == 1, let id = ids.first else { return }
        edit(id)
    }
}
