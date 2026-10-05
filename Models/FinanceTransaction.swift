import Foundation
import GRDB

struct FinanceTransaction: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    static let databaseTableName = "transactions"

    var id: String
    var transactionDate: String
    var transactionTime: String?
    var transactionYear: Int
    var transactionType: TransactionType
    var amountCents: Int
    var currency: String
    var description: String
    var category: String
    var notes: String?
    var dateCreated: String
    var updatedAt: String
    var deletedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case transactionDate = "transaction_date"
        case transactionTime = "transaction_time"
        case transactionYear = "transaction_year"
        case transactionType = "transaction_type"
        case amountCents = "amount_cents"
        case currency, description
        case category
        case notes
        case dateCreated = "date_created"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

enum TransactionType: String, Codable, CaseIterable, DatabaseValueConvertible {
    case income
    case expense
}
