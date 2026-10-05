import SwiftUI

struct TransactionTableView: View {
    let transactions: [TransactionListItem]
    @Binding var selection: String?
    let isLoading: Bool

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading transactions…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if transactions.isEmpty {
                ContentUnavailableView(
                    "No matching transactions",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Add a transaction to begin your ledger.")
                )
            } else {
                Table(transactions, selection: $selection) {
                    TableColumn("Date") { transaction in
                        Text(transaction.transactionDate)
                    }
                    .width(min: 100, ideal: 110)

                    TableColumn("Description") { transaction in
                        Text(transaction.description)
                            .lineLimit(1)
                    }
                    .width(min: 220, ideal: 380)

                    TableColumn("Category") { transaction in
                        Text(transaction.category)
                    }
                    .width(min: 120, ideal: 150)

                    TableColumn("Type") { transaction in
                        Text(transaction.transactionType.rawValue.capitalized)
                            .foregroundStyle(transaction.transactionType == .income ? .green : .secondary)
                    }
                    .width(min: 80, ideal: 90)

                    TableColumn("Amount") { transaction in
                        Text(CurrencyFormatter(code: transaction.currency).string(for: transaction.amountCents))
                            .monospacedDigit()
                    }
                    .width(min: 100, ideal: 120)

                    TableColumn("Status") { transaction in
                        Text(transaction.isDeleted ? "Deleted" : "Active")
                            .foregroundStyle(transaction.isDeleted ? .orange : .secondary)
                    }
                    .width(min: 70, ideal: 80)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
    }
}
