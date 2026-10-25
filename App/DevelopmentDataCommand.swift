#if DEBUG
import Foundation

enum DevelopmentDataCommand {
    static func run(arguments: [String], now: Date = Date()) throws -> Bool {
        guard arguments.contains("--seed-development-data") else { return false }

        let paths = try DatabasePaths(environment: .development)
        let repository = try SQLiteTransactionRepository(databaseURL: paths.databaseURL, schemaURL: paths.schemaURL)
        let samples = DevelopmentSampleData().transactions(asOf: now)
        let inserted = try repository.insertIfNew(samples)
        print("Added \(inserted.count) sample transactions (\(samples.count) available).")
        print("Date range: \(samples.first!.transactionDate) through \(samples.last!.transactionDate)")
        print("Development database: \(paths.databaseURL.path)")
        return true
    }
}
#endif
