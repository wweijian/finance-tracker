import Foundation

struct DatabasePaths {
    let databaseURL: URL
    let feedbackURL: URL
    let schemaURL: URL

    init(fileManager: FileManager = .default) throws {
        let supportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("Ledgerly", isDirectory: true)
        try fileManager.createDirectory(at: supportURL, withIntermediateDirectories: true)
        databaseURL = supportURL.appendingPathComponent("finance.sqlite")
        feedbackURL = supportURL.appendingPathComponent("feedback.txt")
        guard let resourceURL = Bundle.module.url(
            forResource: "schema",
            withExtension: "sql",
            subdirectory: "Resources"
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }
        schemaURL = resourceURL
    }
}
