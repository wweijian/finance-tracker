import SwiftUI

struct AppShellView: View {
    @ObservedObject var dashboardController: DashboardController
    @ObservedObject var transactionsController: TransactionsController
    @ObservedObject var localFilesController: LocalFilesController
    @ObservedObject var feedbackController: FeedbackController
    @State private var screen: AppScreen = .dashboard

    var body: some View {
        VStack(spacing: 0) {
            DashboardView(controller: dashboardController, transactionsController: transactionsController, screen: $screen)
                .disabled(localFilesController.isWorking || localFilesController.pendingRestore != nil)
            LocalFileStatusView(statusMessage: localFilesController.statusMessage, errorMessage: localFilesController.errorMessage)
        }
        .frame(minWidth: 640, minHeight: 520)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                AddTransactionsMenuView(
                    addTransaction: transactionsController.presentNewTransaction,
                    importTransactions: transactionsController.presentBulkImport
                )
                .disabled(localFilesController.isWorking || localFilesController.pendingRestore != nil || transactionsController.isImporting || transactionsController.isMutating || transactionsController.form != nil || transactionsController.isShowingBulkImport)
            }
            ToolbarItem(placement: .automatic) {
                FeedbackButton {
                    Task { await feedbackController.present() }
                }
                .disabled(localFilesController.pendingRestore != nil || transactionsController.form != nil || transactionsController.isShowingBulkImport)
            }
        }
        .onChange(of: localFilesController.restoreRevision) {
            transactionsController.resetAfterDatabaseRestore()
            dashboardController.load()
        }
        .onChange(of: transactionsController.dataRevision) {
            dashboardController.load()
        }
        .onChange(of: dashboardController.reportingPeriod) {
            if let period = dashboardController.reportingPeriod {
                transactionsController.selectReportingPeriod(period)
            }
        }
        .focusedSceneValue(\.appScreen, $screen)
        .sheet(isPresented: $feedbackController.isPresented) {
            FeedbackView(controller: feedbackController)
        }
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

}
