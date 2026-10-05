import Foundation

enum TransactionDateFilterMode: String, CaseIterable, Identifiable {
    case all = "All dates"
    case year = "Year"
    case range = "Date range"

    var id: String { rawValue }
}
