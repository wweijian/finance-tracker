import SwiftUI

struct TransactionTableView: View {
    let transactions: [TransactionListItem]
    @Binding var selection: String?
    @Binding var sortOrder: [KeyPathComparator<TransactionListItem>]
    let isLoading: Bool
    let filterError: String?
    let edit: (String?) -> Void
    let delete: (String?) -> Void
    let restore: (String?) -> Void
    let isMutating: Bool

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading transactions…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let filterError {
                ContentUnavailableView("Check the filters", systemImage: "line.3.horizontal.decrease", description: Text(filterError))
            } else if transactions.isEmpty {
                ContentUnavailableView(
                    "No matching transactions",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Clear or widen the filters, or add or import transactions to begin your ledger.")
                )
            } else {
                Table(transactions, selection: $selection, sortOrder: $sortOrder) {
                    TableColumn("Date", value: \.transactionDate) { transaction in
                        Text(transaction.transactionDate)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .width(min: 100, ideal: 110)

                    TableColumn("Description", value: \.description) { transaction in
                        Text(transaction.description)
                            .lineLimit(1)
                            .help(transaction.description)
                    }
                    .width(min: 180, ideal: 280)

                    TableColumn("Category", value: \.category) { transaction in
                        Text(transaction.category).foregroundStyle(.secondary)
                    }
                    .width(min: 120, ideal: 150)

                    TableColumn("Type", value: \.transactionType.rawValue) { transaction in
                        Text(transaction.transactionType.rawValue.capitalized)
                            .foregroundStyle(transaction.transactionType == .income ? .green : .secondary)
                    }
                    .width(min: 80, ideal: 90)

                    TableColumn("Amount", value: \.amountCents) { transaction in
                        Text(CurrencyFormatter(code: transaction.currency).string(for: transaction.amountCents))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .monospacedDigit()
                    }
                    .width(min: 100, ideal: 120)

                    TableColumn("Remarks", value: \.remarks) { transaction in
                        Text(transaction.remarks.isEmpty ? "—" : transaction.remarks)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .help(transaction.remarks.isEmpty ? "No remarks" : transaction.remarks)
                    }
                    .width(min: 140, ideal: 220)

                    TableColumn("Status", value: \.statusLabel) { transaction in
                        Text(transaction.statusLabel)
                            .foregroundStyle(transaction.isExcluded ? .orange : .secondary)
                    }
                    .width(min: 85, ideal: 95)
                }
                .accessibilityLabel("Transactions. Click column headings to sort. Double-click a row to edit its remarks or other details.")
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .contextMenu(forSelectionType: String.self) { ids in
                    if let id = ids.first {
                        Button("Edit transaction…") { edit(id) }
                            .disabled(isMutating)
                        if let transaction = transactions.first(where: { $0.id == id }) {
                            if transaction.isExcluded {
                                Button("Restore transaction", systemImage: "arrow.uturn.backward") { restore(id) }
                                    .disabled(isMutating)
                            } else {
                                Button("Delete transaction", systemImage: "trash", role: .destructive) { delete(id) }
                                    .disabled(isMutating)
                            }
                        }
                    }
                } primaryAction: { ids in
                    if !isMutating { edit(ids.first) }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}
