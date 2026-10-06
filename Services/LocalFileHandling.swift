import Foundation

protocol LocalFileHandling: Sendable {
    func export(_ transactions: [TransactionListItem], to url: URL) async throws
    func backUp(to url: URL) async throws
    func validateBackup(at url: URL) async throws -> Int
    func restore(from url: URL) async throws
}
