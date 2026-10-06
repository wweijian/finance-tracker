import Foundation
@testable import LedgerlyApp

final class SQLiteTestStore {
    let directory: URL
    let databaseURL: URL
    let schemaURL: URL
    let repository: SQLiteTransactionRepository

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        databaseURL = directory.appendingPathComponent("test.sqlite")
        schemaURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/schema.sql")
        repository = try SQLiteTransactionRepository(databaseURL: databaseURL, schemaURL: schemaURL)
    }

    deinit { try? FileManager.default.removeItem(at: directory) }
}
