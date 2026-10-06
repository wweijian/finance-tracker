import Foundation

enum CSVTransactionParserError: LocalizedError {
    case unsupportedHeader(CSVImportKind, foundHeader: String?)

    var errorDescription: String? {
        switch self {
        case .unsupportedHeader(let kind, let foundHeader):
            let found = foundHeader ?? "No transaction header was found."
            return "This is not the required \(kind.title.lowercased()) header. Found: \(found)"
        }
    }
}
