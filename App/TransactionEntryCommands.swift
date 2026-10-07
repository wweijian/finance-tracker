import SwiftUI

struct TransactionEntryCommands: Commands {
    @ObservedObject var transactionsController: TransactionsController
    @ObservedObject var localFilesController: LocalFilesController

    private var canAddTransactions: Bool {
        !localFilesController.isWorking && localFilesController.pendingRestore == nil
            && !transactionsController.isImporting && !transactionsController.isMutating
            && transactionsController.form == nil && !transactionsController.isShowingBulkImport
    }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Add single transaction…", action: transactionsController.presentNewTransaction)
                .keyboardShortcut("n", modifiers: [.command])
                .disabled(!canAddTransactions)
        }
        CommandGroup(before: .importExport) {
            Button("Bulk add transactions (CSV)…", action: transactionsController.presentBulkImport)
                .keyboardShortcut("i", modifiers: [.command, .shift])
                .disabled(!canAddTransactions)
        }
    }
}
