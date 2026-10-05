import SwiftUI

struct TransactionsView: View {
    @ObservedObject var controller: TransactionsController
    @State private var selection: String?
    @State private var confirmsDeletion = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TransactionsHeaderView(
                    transactionCount: controller.filteredTransactions.count,
                    addTransaction: controller.presentNewTransaction,
                    editTransaction: { controller.edit(id: selection) },
                    deleteTransaction: { confirmsDeletion = true },
                    restoreTransaction: { controller.restore(id: selection) },
                    canEdit: selection != nil,
                    selectedTransactionIsDeleted: selectedTransaction?.isDeleted ?? false
                )
                TransactionFilterView(controller: controller)
                TransactionTableView(
                    transactions: controller.filteredTransactions,
                    selection: $selection,
                    isLoading: controller.isLoading
                )
                if let errorMessage = controller.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }
            .padding(28)
            .navigationTitle("Transactions")
        }
        .task {
            controller.load()
        }
        .sheet(item: $controller.form) { form in
            TransactionEditorView(
                form: form,
                categories: controller.categories,
                save: controller.save
            )
        }
        .alert("Delete transaction?", isPresented: $confirmsDeletion) {
            Button("Delete", role: .destructive) {
                controller.softDelete(id: selection)
                selection = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The transaction will be hidden but can be restored later.")
        }
    }

    private var selectedTransaction: TransactionListItem? {
        controller.filteredTransactions.first { $0.id == selection }
    }
}
