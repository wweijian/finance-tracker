import SwiftUI

@main
struct LedgerlyApp: App {
    @NSApplicationDelegateAdaptor(LedgerlyAppDelegate.self) private var appDelegate
    @StateObject private var dashboardController: DashboardController
    @StateObject private var transactionsController: TransactionsController
    @StateObject private var localFilesController: LocalFilesController

    init() {
        do {
            let container = try AppContainer()
            _localFilesController = StateObject(wrappedValue: LocalFilesController(service: container.localFileService))
            _dashboardController = StateObject(
                wrappedValue: DashboardController(reportService: container.dashboardReportService)
            )
            _transactionsController = StateObject(
                wrappedValue: TransactionsController(
                    service: container.transactionService,
                    bulkImportService: container.bulkImportService
                )
            )
        } catch {
            fatalError("Ledgerly could not open its local database: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppShellView(
                dashboardController: dashboardController,
                transactionsController: transactionsController,
                localFilesController: localFilesController
            )
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 1_240, height: 820)
        .commands {
            LocalFileCommands(controller: localFilesController, transactionsController: transactionsController)
        }
    }
}
