import Foundation

enum CSVImportKind: String, CaseIterable, Identifiable, Sendable {
    case debit
    case credit
    case finance

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}
