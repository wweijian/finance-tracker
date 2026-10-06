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
                edit: controller.edit
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
                    addTransaction: controller.presentNewTransaction,
                    importTransactions: controller.presentBulkImport,
                    exportTransactions: { localFilesController.chooseExport(controller.filteredTransactions) },
                    canExport: !controller.isLoading && !localFilesController.isWorking && !controller.filteredTransactions.isEmpty,
                    editTransaction: { controller.edit(id: selection) },
                    excludeTransaction: { controller.exclude(id: selection) },
                    includeTransaction: { controller.include(id: selection) },
                    canEdit: selection != nil && !controller.isMutating,
                    selectedTransactionIsExcluded: selectedTransaction?.isExcluded ?? false
                )
            }
        }
        .task {
            controller.load()
        }
        .onChange(of: controller.filteredTransactions.map(\.id)) {
            if !controller.filteredTransactions.contains(where: { $0.id == selection }) { selection = nil }
        }
        .sheet(item: $controller.form) { form in
            TransactionEditorView(
                form: form,
                categories: controller.categories,
                errorMessage: controller.errorMessage,
                save: controller.save
            )
        }
        .sheet(isPresented: $controller.isShowingBulkImport) {
            BulkImportView(
                preview: controller.importPreview,
                categories: controller.categories,
                summary: controller.bulkImportSummary,
                errorMessage: controller.bulkImportError,
                activity: controller.importActivity,
                previewCSV: controller.previewCSV,
                revalidate: controller.revalidate,
                removedRowCount: controller.removedImportRowCount,
                removeRows: controller.removeImportRows,
                undoRowRemovals: controller.undoImportRowRemovals,
                commitAll: controller.commitBulkImport,
                undo: controller.undoBulkImport,
                cancel: controller.cancelBulkImport
            )
        }
    }

    private var selectedTransaction: TransactionListItem? {
        controller.filteredTransactions.first { $0.id == selection }
    }
}
