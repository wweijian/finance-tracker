import SwiftUI

struct TransactionsHeaderView: View {
    let transactionCount: Int
    let addTransaction: () -> Void
    let editTransaction: () -> Void
    let deleteTransaction: () -> Void
    let restoreTransaction: () -> Void
    let canEdit: Bool
    let selectedTransactionIsDeleted: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                heading
                Spacer()
                actions
            }
            VStack(alignment: .leading, spacing: 16) {
                heading
                actions
            }
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Transaction ledger")
                .font(.largeTitle.weight(.bold))
            Text("\(transactionCount) matching transactions")
                .foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        HStack {
            Button(action: addTransaction) {
                Label("Add transaction", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)

            if selectedTransactionIsDeleted {
                Button("Restore", action: restoreTransaction)
                    .disabled(!canEdit)
            } else {
                Button("Edit", action: editTransaction)
                    .disabled(!canEdit)
                Button("Delete", role: .destructive, action: deleteTransaction)
                    .disabled(!canEdit)
            }
        }
    }
}
