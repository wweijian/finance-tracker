import Foundation

struct BulkImportSummary: Sendable {
    var importedTransactionIDs: [String]
    var rejectedCount: Int

    var acceptedCount: Int { importedTransactionIDs.count }
}
