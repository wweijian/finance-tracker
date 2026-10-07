struct LedgerlyImportDetails: Hashable, Sendable {
    var transactionID: String
    var transactionType: String
    var currency: String
    var deletedAt: String?
}
