import Foundation

final class AppContainer {
    let dashboardReportService: DashboardReportService
    let transactionService: TransactionService
    let bulkImportService: BulkImportService
    let localFileService: LocalFileService
    let feedbackRepository: LocalFeedbackRepository

    init() throws {
        let paths = try DatabasePaths()
        let repository = try SQLiteTransactionRepository(
            databaseURL: paths.databaseURL,
            schemaURL: paths.schemaURL
        )
        dashboardReportService = DashboardReportService(repository: repository)
        transactionService = TransactionService(repository: repository)
        bulkImportService = BulkImportService(repository: repository)
        localFileService = LocalFileService(repository: repository)
        feedbackRepository = LocalFeedbackRepository(fileURL: paths.feedbackURL)
    }
}
