import Foundation
import GRDB

struct TransactionListItem: FetchableRecord, Decodable, Identifiable, Hashable {
    var id: String
    var transactionDate: String
    var transactionTime: String?
    var transactionType: TransactionType
    var amountCents: Int
    var currency: String
    var description: String
    var category: String
    var notes: String?
    var deletedAt: String?

    var isDeleted: Bool { deletedAt != nil }
    var amount: Decimal { Decimal(amountCents) / 100 }

    enum CodingKeys: String, CodingKey {
        case id
        case transactionDate = "transaction_date"
        case transactionTime = "transaction_time"
        case transactionType = "transaction_type"
        case amountCents = "amount_cents"
        case currency, description
        case category
        case notes
        case deletedAt = "deleted_at"
    }
}
