import SwiftUI

struct AddTransactionsMenuView: View {
    let addTransaction: () -> Void
    let importTransactions: () -> Void

    var body: some View {
        Menu("Add transactions", systemImage: "plus") {
            Button("Add single transaction…", systemImage: "plus.circle", action: addTransaction)
            Button("Bulk import transactions (CSV)…", systemImage: "square.and.arrow.down", action: importTransactions)
        }
        .help("Add a transaction or import a CSV")
        .accessibilityIdentifier("addTransactionsMenu")
    }
}
