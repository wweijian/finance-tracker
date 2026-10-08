import SwiftUI

struct PeriodTransactionRowView: View {
    let transaction: TransactionListItem
    let edit: (String?) -> Void
    let exclude: (String?) -> Void
    let restore: (String?) -> Void
    let isMutating: Bool

    var body: some View {
        HStack(spacing: 16) {
            Text(String(transaction.transactionDate.suffix(5)))
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.description).lineLimit(1)
                Text(transaction.isExcluded ? "\(transaction.category) · Deleted" : transaction.category)
                    .font(.caption).foregroundStyle(transaction.isExcluded ? .orange : .secondary)
            }
            Spacer(minLength: 8)
            Text(CurrencyFormatter(code: transaction.currency).string(for: transaction.amountCents))
                .monospacedDigit()
                .foregroundStyle(transaction.transactionType == .income ? .teal : .primary)
            Button("Edit transaction", systemImage: "pencil") { edit(transaction.id) }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help("Edit \(transaction.description)")
        }
        .padding(.vertical, 8)
        .disabled(isMutating)
        .help("Edit \(transaction.description)")
        .contextMenu {
            Button("Edit transaction…") { edit(transaction.id) }
            if transaction.isExcluded {
                Button("Restore transaction") { restore(transaction.id) }
            } else {
                Button("Delete transaction", role: .destructive) { exclude(transaction.id) }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
