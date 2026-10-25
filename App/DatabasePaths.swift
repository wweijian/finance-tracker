import Foundation

struct DatabasePaths {
    let databaseURL: URL
    let feedbackURL: URL
    let schemaURL: URL

    init(
        environment: AppEnvironment = .current,
        applicationSupportURL: URL? = nil,
        fileManager: FileManager = .default
    ) throws {
        let baseURL = try applicationSupportURL ?? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let supportURL = baseURL.appendingPathComponent(environment.supportDirectoryName, isDirectory: true)
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
