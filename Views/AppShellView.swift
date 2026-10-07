import SwiftUI

struct AppShellView: View {
    @ObservedObject var dashboardController: DashboardController
    @ObservedObject var transactionsController: TransactionsController
    @ObservedObject var localFilesController: LocalFilesController
    @State private var screen: AppScreen = .dashboard
    @State private var showsAddMenu = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content
                    .disabled(localFilesController.isWorking || localFilesController.pendingRestore != nil)
                LocalFileStatusView(statusMessage: localFilesController.statusMessage, errorMessage: localFilesController.errorMessage)
            }
        }
        .frame(minWidth: 1_100, minHeight: 680)
        .overlay(alignment: .bottomTrailing) {
            ZStack(alignment: .bottomTrailing) {
                if showsAddMenu {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { showsAddMenu = false }
                }
                VStack(alignment: .trailing, spacing: 12) {
                    if showsAddMenu {
                        AddTransactionsMenuView(
                            addTransaction: {
                                showsAddMenu = false
                                transactionsController.presentNewTransaction()
                            },
                            importTransactions: {
                                showsAddMenu = false
                                transactionsController.presentBulkImport()
                            }
                        )
                    }
                    AddTransactionsFloatingButton(showsMenu: $showsAddMenu)
                }
                .disabled(localFilesController.isWorking || localFilesController.pendingRestore != nil || transactionsController.isImporting || transactionsController.isMutating || transactionsController.form != nil || transactionsController.isShowingBulkImport)
                .padding(.trailing, 24)
                .padding(.bottom, 48)
            }
        }
        .onExitCommand { showsAddMenu = false }
        .onChange(of: screen) { showsAddMenu = false }
        .onChange(of: transactionsController.form?.id) { showsAddMenu = false }
        .onChange(of: transactionsController.isShowingBulkImport) { showsAddMenu = false }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                LocalFileActionsView(controller: localFilesController)
                    .disabled(transactionsController.isImporting || transactionsController.isMutating || transactionsController.form != nil || transactionsController.isShowingBulkImport)
            }
        }
        .onChange(of: localFilesController.restoreRevision) {
            transactionsController.resetAfterDatabaseRestore()
            dashboardController.load()
        }
        .onChange(of: transactionsController.dataRevision) {
            dashboardController.load()
        }
        .focusedSceneValue(\.appScreen, $screen)
        .sheet(item: $transactionsController.form) { form in
            TransactionEditorView(
                form: form,
                categories: transactionsController.categories,
                errorMessage: transactionsController.errorMessage,
                isMutating: transactionsController.isMutating,
                save: transactionsController.save,
                delete: { transactionsController.exclude(id: form.transactionID) },
                restore: { transactionsController.include(id: form.transactionID) }
            )
        }
        .sheet(isPresented: $transactionsController.isShowingBulkImport) {
            BulkImportView(
                preview: transactionsController.importPreview,
                summary: transactionsController.bulkImportSummary,
                errorMessage: transactionsController.bulkImportError,
                activity: transactionsController.importActivity,
                previewCSV: transactionsController.previewCSV,
                removedRowCount: transactionsController.removedImportRowCount,
                removeRows: transactionsController.requestImportRowRemoval,
                undoRowRemovals: transactionsController.undoImportRowRemovals,
                commitAll: transactionsController.commitBulkImport,
                undo: transactionsController.undoBulkImport,
                cancel: transactionsController.cancelBulkImport,
                editingCandidate: $transactionsController.importEditorCandidate,
                categories: transactionsController.categories,
                editorError: transactionsController.importEditorError,
                editCandidate: transactionsController.editImportCandidate,
                saveCandidate: transactionsController.saveImportCandidate,
                removalIDs: $transactionsController.importRowRemovalIDs,
                confirmRemoval: transactionsController.confirmImportRowRemoval
            )
        }
        .alert("Replace the current database?", isPresented: Binding(
            get: { localFilesController.pendingRestore != nil },
            set: { if !$0 { localFilesController.pendingRestore = nil } }
        ), presenting: localFilesController.pendingRestore) { restore in
            Button("Cancel", role: .cancel) {}
            Button("Replace database", role: .destructive) { localFilesController.confirmRestore(restore) }
        } message: { restore in
            Text("Restoring \(restore.url.lastPathComponent) will replace ALL current transactions, including excluded rows, with \(restore.transactionCount) backed-up transactions. This cannot be undone. Back up the current database first if you need to keep it.")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case .dashboard:
            DashboardView(controller: dashboardController)
        case .transactions:
            TransactionsView(controller: transactionsController, localFilesController: localFilesController)
        }
    }
}
