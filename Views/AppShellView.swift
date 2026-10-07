import SwiftUI

struct AppShellView: View {
    @ObservedObject var dashboardController: DashboardController
    @ObservedObject var transactionsController: TransactionsController
    @ObservedObject var localFilesController: LocalFilesController
    @State private var screen: AppScreen = .dashboard

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
            AppScreenFloatingButton(screen: $screen)
                .disabled(localFilesController.isWorking || localFilesController.pendingRestore != nil)
                .padding(.trailing, 24)
                .padding(.bottom, 48)
        }
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
