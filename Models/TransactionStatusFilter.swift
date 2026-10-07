import Foundation

enum TransactionStatusFilter: String, CaseIterable, Identifiable {
    case included = "Active only"
    case excluded = "Deleted only"
    case all = "All rows"

    var id: String { rawValue }
}
