import Foundation

actor LocalFileService: LocalFileHandling {
    private let repository: any DatabaseFileRepository
    private let exporter = TransactionCSVExporter()

    init(repository: any DatabaseFileRepository) {
        self.repository = repository
    }

    func export(_ transactions: [TransactionListItem], to url: URL) throws {
        try withAccess(to: url) {
            try repository.checkFileLocation(url)
            try exporter.csv(transactions).write(to: url, atomically: true, encoding: .utf8)
        }
    }

    func backUp(to url: URL) throws {
        try withAccess(to: url) { try repository.backUp(to: url) }
    }

    func validateBackup(at url: URL) throws -> Int {
        try withAccess(to: url) { try repository.validateBackup(at: url) }
    }

    func restore(from url: URL) throws {
        try withAccess(to: url) { try repository.restoreDatabase(from: url) }
    }

    private func withAccess<T>(to url: URL, operation: () throws -> T) rethrows -> T {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        return try operation()
    }
}
