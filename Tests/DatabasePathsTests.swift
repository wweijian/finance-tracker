import Foundation
import Testing
@testable import FinanceApp

struct DatabasePathsTests {
    @Test func developmentAndProductionUseSeparateFiles() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }

        let development = try DatabasePaths(environment: .development, applicationSupportURL: root)
        let production = try DatabasePaths(environment: .production, applicationSupportURL: root)
        let defaults = try DatabasePaths(applicationSupportURL: root)

        #expect(development.databaseURL.path == root.appendingPathComponent("Ledgerly Development/finance.sqlite").path)
        #expect(production.databaseURL.path == root.appendingPathComponent("Ledgerly/finance.sqlite").path)
        #expect(development.feedbackURL != production.feedbackURL)
        #expect(development.schemaURL == production.schemaURL)
        #expect(!FileManager.default.fileExists(atPath: development.databaseURL.path))
        #expect(!FileManager.default.fileExists(atPath: production.databaseURL.path))
        #if DEBUG
        #expect(defaults.databaseURL == development.databaseURL)
        #else
        #expect(defaults.databaseURL == production.databaseURL)
        #endif
    }
}
