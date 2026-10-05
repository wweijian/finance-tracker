import SwiftUI

@main
struct LedgerlyApp: App {
    @StateObject private var dashboardController: DashboardController
    @StateObject private var transactionsController: TransactionsController

    init() {
        do {
            let container = try AppContainer()
            _dashboardController = StateObject(
                wrappedValue: DashboardController(reportService: container.dashboardReportService)
            )
            _transactionsController = StateObject(
                wrappedValue: TransactionsController(service: container.transactionService)
            )
        } catch {
            fatalError("Ledgerly could not open its local database: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppShellView(
                dashboardController: dashboardController,
                transactionsController: transactionsController
            )
        }
    }
}
