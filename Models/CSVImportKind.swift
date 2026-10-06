import Foundation

enum CSVImportKind: String, CaseIterable, Identifiable, Sendable {
    case debit
    case credit

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}
