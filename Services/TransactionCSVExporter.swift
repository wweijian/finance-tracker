import Foundation

struct TransactionCSVExporter {
    func csv(_ transactions: [TransactionListItem]) -> String {
        let header = "id,transaction_date,transaction_type,amount,currency,description,category,notes,deleted_at"
        let rows = transactions.map { transaction in
            [transaction.id, transaction.transactionDate, transaction.transactionType.rawValue,
             amount(transaction.amountCents), transaction.currency, transaction.description,
             transaction.category, transaction.notes ?? "", transaction.deletedAt ?? ""]
                .map(escaped).joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\r\n") + "\r\n"
    }

    private func amount(_ cents: Int) -> String {
        CurrencyAmountFormatter().inputString(for: cents)
    }

    private func escaped(_ value: String) -> String {
        guard value.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
