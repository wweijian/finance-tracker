import SwiftUI

struct HighestTransactionDetailView: View {
    let transaction: TransactionListItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let transaction {
                HStack(alignment: .firstTextBaseline) {
                    Text("Highest transaction").font(.caption).foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Text("\(CurrencyFormatter(code: transaction.currency).string(for: transaction.amountCents)) \(transaction.currency)")
                        .font(.callout.weight(.medium)).monospacedDigit()
                }
                Text(transaction.description).font(.callout).textSelection(.enabled)
                Text("\(transaction.transactionDate) · \(transaction.category) · \(transaction.transactionType.rawValue.capitalized)")
                    .font(.caption).foregroundStyle(.secondary)
                if !transaction.remarks.isEmpty {
                    Text("Remarks: \(transaction.remarks)").font(.caption).textSelection(.enabled)
                }
            } else {
                Text("Hover over a category to see its highest transaction, including the description, date and remarks.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("highestTransactionDetail")
    }
}
