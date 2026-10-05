import Foundation

struct ImportCandidate: Codable, Identifiable, Hashable {
    var id: String
    var sourceFilename: String
    var sourceLine: Int
    var transaction: ImportTransaction?
    var status: ImportStatus
    var warnings: [ImportWarning]

    var isReady: Bool { status == .ready }
}

struct ImportTransaction: Codable, Hashable {
    var transactionDate: String
    var transactionTime: String?
    var transactionType: TransactionType
    var amountCents: Int
    var currency: String
    var description: String
    var category: String
    var notes: String?

    var amount: Decimal { Decimal(amountCents) / 100 }
}

struct ImportWarning: Codable, Hashable, Identifiable {
    var type: String
    var reason: String
    var matchedTransactionID: String

    var id: String { "\(type):\(reason):\(matchedTransactionID)" }
}

enum ImportStatus: String, Codable {
    case ready
    case warning
}

struct ImportResult: Codable {
    var mode: ImportMode
    var committed: Bool
    var summary: ImportSummary
    var warningCSV: String?
    var candidates: [ImportCandidate]
}

struct ImportSummary: Codable {
    var total: Int
    var ready: Int
    var warnings: Int
}

enum ImportMode: String, Codable {
    case preview
    case commit
}
