import Foundation
import GRDB

struct DashboardSnapshot {
    var incomeCents: Int
    var expenseCents: Int
    var transactionCount: Int
    var categoryTotals: [CategoryTotal]

    var netCents: Int { incomeCents - expenseCents }

    static let empty = DashboardSnapshot(
        incomeCents: 0,
        expenseCents: 0,
        transactionCount: 0,
        categoryTotals: []
    )
}

struct CategoryTotal: FetchableRecord, Decodable, Hashable, Identifiable {
    var category: String
    var amountCents: Int

    var id: String { category }
    var amount: Decimal { Decimal(amountCents) / 100 }

    enum CodingKeys: String, CodingKey {
        case category
        case amountCents = "amount_cents"
    }
}
