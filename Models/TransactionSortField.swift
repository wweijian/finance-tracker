import Foundation

enum TransactionSortField: String, CaseIterable, Identifiable {
    case date = "Date"
    case amount = "Amount"
    case description = "Description"
    case category = "Category"

    var id: String { rawValue }
}
