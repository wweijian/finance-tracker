import SwiftUI

struct DashboardTransactionsPageView: View {
    @ObservedObject var dashboardController: DashboardController
    @ObservedObject var transactionsController: TransactionsController

    var body: some View {
        PeriodTransactionsView(intervals: dashboardController.transactionIntervals(for: transactionsController.filteredTransactions),
                               scope: dashboardController.scope, controller: transactionsController)
    }
}
