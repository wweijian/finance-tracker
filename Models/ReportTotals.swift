import Foundation

struct ReportTotals: Sendable, Equatable {
    var incomeCents = 0
    var expenseCents = 0
    var transactionCount = 0

    var netCents: Int { incomeCents - expenseCents }
    static let empty = ReportTotals()
}
