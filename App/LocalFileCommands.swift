import SwiftUI

struct LocalFileCommands: Commands {
    @ObservedObject var controller: LocalFilesController
    @ObservedObject var transactionsController: TransactionsController

    var body: some Commands {
        CommandGroup(after: .importExport) {
            Button("Export filtered transactions as CSV…") {
                controller.chooseExport(transactionsController.filteredTransactions)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .disabled(controller.isWorking || transactionsController.isLoading || transactionsController.filteredTransactions.isEmpty)
            Button("Back up database…", action: controller.chooseBackup)
                .keyboardShortcut("b", modifiers: [.command, .shift])
                .disabled(controller.isWorking)
            Button("Restore database…", action: controller.chooseRestore)
                .disabled(controller.isWorking || controller.pendingRestore != nil || transactionsController.isImporting || transactionsController.isMutating || transactionsController.form != nil || transactionsController.isShowingBulkImport)
        }
    }
}
