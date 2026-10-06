import SwiftUI

struct ImportCandidateTableView: View {
    let candidates: [ImportCandidate]
    @Binding var selection: Set<String>
    let edit: (ImportCandidate) -> Void
    let remove: (Set<String>) -> Void
    @State private var sortOrder = [KeyPathComparator(\ImportCandidate.sourceRow)]

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    ScrollView(.horizontal) {
                        table
                            .frame(width: max(1_180, geometry.size.width), height: max(0, geometry.size.height - 16))
                            .id("import-table")
                    }
                    .scrollIndicators(.visible, axes: .horizontal)
                }
                Divider()
                ImportTableNavigationView(
                    showFirstColumns: { proxy.scrollTo("import-table", anchor: .leading) },
                    showLastColumns: { proxy.scrollTo("import-table", anchor: .trailing) }
                )
            }
        }
    }

    private var table: some View {
        Table(candidates.sorted(using: sortOrder), selection: $selection, sortOrder: $sortOrder) {
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
            TableColumn("Amount (SGD)", sortUsing: KeyPathComparator(\ImportCandidate.amountCents)) { candidate in
                Text(candidate.amount.isEmpty ? "—" : candidate.amount)
                    .monospacedDigit().frame(maxWidth: .infinity, alignment: .trailing)
            }.width(95)
            TableColumn("Category", value: \.category) { candidate in
                Text(candidate.category).foregroundStyle(.secondary).lineLimit(1).help(candidate.category)
            }.width(min: 110, ideal: 125)
            TableColumn("Remarks", value: \.remarks) { candidate in
                Text(candidate.remarks.isEmpty ? "—" : candidate.remarks)
                    .foregroundStyle(.secondary).lineLimit(1)
                    .help(candidate.remarks.isEmpty ? "No remarks" : candidate.remarks)
            }.width(min: 100, ideal: 140)
            TableColumn("Status", value: \.statusLabel) { candidate in
                Label(candidate.rejectionReason ?? "Ready", systemImage: candidate.isReady ? "checkmark.circle" : "exclamationmark.circle")
                    .foregroundStyle(candidate.isReady ? Color.secondary : .orange)
                    .lineLimit(1)
                    .help(candidate.rejectionReason ?? "Ready to import")
            }.width(min: 160, ideal: 180)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .contextMenu(forSelectionType: String.self) { ids in
            if let candidate = candidates.first(where: { ids.contains($0.id) }) {
                Button("Edit row…") { edit(candidate) }
                Button(ids.count == 1 ? "Remove row from import" : "Remove \(ids.count) rows from import", systemImage: "trash") {
                    remove(ids)
                }
            }
        } primaryAction: { ids in
            if let candidate = candidates.first(where: { ids.contains($0.id) }) { edit(candidate) }
        }
        .scrollIndicators(.visible)
        .onKeyPress(.return) {
            guard selection.count == 1, let candidate = candidates.first(where: { selection.contains($0.id) }) else { return .ignored }
            edit(candidate)
            return .handled
        }
        .onDeleteCommand { if !selection.isEmpty { remove(selection) } }
        .accessibilityLabel("CSV import preview. Click column headings to sort dates, descriptions, types, amounts, categories, remarks, or validation status.")
    }
}
