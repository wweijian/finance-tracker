import SwiftUI

struct TransactionsToolbarView: View {
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
            Button("Export filtered transactions as CSV…", systemImage: "square.and.arrow.up", action: exportTransactions)
                .disabled(!canExport)
                .help("Export filtered transactions as CSV")
        }
        .labelStyle(.iconOnly)
    }
}
