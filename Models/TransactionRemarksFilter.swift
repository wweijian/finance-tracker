import Foundation

enum TransactionRemarksFilter: String, CaseIterable, Identifiable {
    case all = "Any remarks"
    case withRemarks = "With remarks"
    case withoutRemarks = "Without remarks"

    var id: String { rawValue }
}
