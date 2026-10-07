import SwiftUI

struct TransactionsToolbarView: View {
    let addTransaction: () -> Void
    let importTransactions: () -> Void
    let exportTransactions: () -> Void
    let canExport: Bool
    let editTransaction: () -> Void
    let canEdit: Bool

    var body: some View {
        HStack(spacing: 12) {
            Button("Edit transaction", systemImage: "square.and.pencil", action: editTransaction)
                .disabled(!canEdit)
                .keyboardShortcut("e", modifiers: [.command])
                .help("Edit the selected transaction (⌘E)")
            Menu("Import and export", systemImage: "arrow.up.arrow.down") {
                Button("Import CSV…", systemImage: "square.and.arrow.down", action: importTransactions)
                    .keyboardShortcut("i", modifiers: [.command, .shift])
                Button("Export filtered transactions as CSV…", systemImage: "square.and.arrow.up", action: exportTransactions)
                    .disabled(!canExport)
            }
            .help("Import or export transactions")
            Button("Add transaction", systemImage: "plus", action: addTransaction)
                .keyboardShortcut("n", modifiers: [.command])
                .help("Add a transaction (⌘N)")
        }
        .labelStyle(.iconOnly)
    }
}
