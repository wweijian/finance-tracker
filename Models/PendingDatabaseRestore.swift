import Foundation

struct PendingDatabaseRestore: Identifiable {
    let id = UUID()
    let url: URL
    let transactionCount: Int
}
