import SwiftUI

struct AppScreenCommands: Commands {
    @FocusedBinding(\.appScreen) private var screen: AppScreen?
    @ObservedObject var transactionsController: TransactionsController
    @ObservedObject var localFilesController: LocalFilesController

    var body: some Commands {
        CommandGroup(after: .sidebar) {
            Button(screen == .transactions ? "Show Overview" : "Show Transactions Table") {
                screen = screen == .transactions ? .dashboard : .transactions
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            .disabled(screen == nil || localFilesController.isWorking || localFilesController.pendingRestore != nil || transactionsController.isImporting || transactionsController.isMutating || transactionsController.form != nil || transactionsController.isShowingBulkImport)
        }
    }
}
