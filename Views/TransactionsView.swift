import SwiftUI

struct TransactionsView: View {
    @ObservedObject var controller: TransactionsController
    @ObservedObject var localFilesController: LocalFilesController
    @State private var selection: String?

    var body: some View {
        VStack(spacing: 0) {
            TransactionFilterView(controller: controller)
            Divider()
            TransactionTableView(
                transactions: controller.filteredTransactions,
                selection: $selection,
                sortOrder: $controller.sortOrder,
                isLoading: controller.isLoading,
                filterError: controller.filterErrorMessage,
                edit: controller.edit,
                delete: controller.exclude,
                restore: controller.include,
                isMutating: controller.isMutating
            )
            Divider()
            LedgerStatusBarView(
                transactionCount: controller.filteredTransactions.count,
                statusFilter: controller.statusFilter,
                isLoading: controller.isLoading,
                errorMessage: controller.filterErrorMessage ?? controller.errorMessage
            )
        }
        .searchable(text: $controller.searchText, placement: .toolbar, prompt: "Search transactions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                TransactionsToolbarView(
                    exportTransactions: { localFilesController.chooseExport(controller.filteredTransactions) },
                    canExport: !controller.isLoading && !localFilesController.isWorking && !controller.filteredTransactions.isEmpty,
                    editTransaction: { controller.edit(id: selection) },
                    canEdit: selection != nil && !controller.isMutating
                )
            }
        }
        .task {
            controller.load()
        }
        .onChange(of: controller.filteredTransactions.map(\.id)) {
            if !controller.filteredTransactions.contains(where: { $0.id == selection }) { selection = nil }
        }
    }
}
