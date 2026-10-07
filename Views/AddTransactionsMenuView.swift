import SwiftUI

struct AddTransactionsMenuView: View {
    let addTransaction: () -> Void
    let importTransactions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Add transactions")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            Button(action: addTransaction) {
                Label("Add single transaction…", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .contentShape(Rectangle())
            }
            Divider()
            Button(action: importTransactions) {
                Label("Bulk add transactions (CSV)…", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .font(.body)
        .padding(8)
        .frame(width: 290)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.primary.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        .accessibilityIdentifier("addTransactionsMenu")
    }
}
