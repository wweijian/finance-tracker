import Foundation

final class AppContainer {
    let dashboardReportService: DashboardReportService
    let transactionService: TransactionService

    init() throws {
        let paths = try DatabasePaths()
        let repository = try SQLiteTransactionRepository(
            databaseURL: paths.databaseURL,
            schemaURL: paths.schemaURL
        )
        dashboardReportService = DashboardReportService(repository: repository)
        transactionService = TransactionService(repository: repository)
    }
}
