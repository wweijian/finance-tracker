import Foundation

struct ImportCandidate: Identifiable, Hashable, Sendable {
    var id: String
    var sourceRow: Int
    var transactionDate: String
    var transactionType: TransactionType
    var amount: String
    var description: String
    var category: String
    var rejectionReason: String?
    var remarks = ""
    var ledgerlyDetails: LedgerlyImportDetails?

    var isReady: Bool { rejectionReason == nil }
    var amountCents: Int? { CurrencyAmountFormatter().cents(from: amount) }
    var currency: String { ledgerlyDetails?.currency ?? "SGD" }
    var statusLabel: String { rejectionReason ?? (ledgerlyDetails?.deletedAt == nil ? "Ready" : "Ready · Deleted") }
}
