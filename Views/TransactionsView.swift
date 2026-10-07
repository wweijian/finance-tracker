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
                    addTransaction: controller.presentNewTransaction,
                    importTransactions: controller.presentBulkImport,
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
        .sheet(item: $controller.form) { form in
            TransactionEditorView(
                form: form,
                categories: controller.categories,
                errorMessage: controller.errorMessage,
                isMutating: controller.isMutating,
                save: controller.save,
                delete: { controller.exclude(id: form.transactionID) },
                restore: { controller.include(id: form.transactionID) }
            )
        }
        .sheet(isPresented: $controller.isShowingBulkImport) {
            BulkImportView(
                preview: controller.importPreview,
                summary: controller.bulkImportSummary,
                errorMessage: controller.bulkImportError,
                activity: controller.importActivity,
                previewCSV: controller.previewCSV,
                removedRowCount: controller.removedImportRowCount,
                removeRows: controller.requestImportRowRemoval,
                undoRowRemovals: controller.undoImportRowRemovals,
                commitAll: controller.commitBulkImport,
                undo: controller.undoBulkImport,
                cancel: controller.cancelBulkImport,
                editingCandidate: $controller.importEditorCandidate,
                categories: controller.categories,
                editorError: controller.importEditorError,
                editCandidate: controller.editImportCandidate,
                saveCandidate: controller.saveImportCandidate,
                removalIDs: $controller.importRowRemovalIDs,
                confirmRemoval: controller.confirmImportRowRemoval
            )
        }
    }
}
