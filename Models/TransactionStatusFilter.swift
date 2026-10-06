import Foundation

enum TransactionStatusFilter: String, CaseIterable, Identifiable {
    case included = "Included only"
    case excluded = "Excluded only"
    case all = "All rows"

    var id: String { rawValue }
}
