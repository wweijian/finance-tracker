import Foundation

enum BulkImportError: LocalizedError {
    case invalidCandidate

    var errorDescription: String? {
        "A transaction was changed after validation. Revalidate it before importing."
    }
}
