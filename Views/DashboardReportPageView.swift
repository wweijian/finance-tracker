import SwiftUI

struct DashboardReportPageView: View {
    let page: DashboardPage
    let snapshot: DashboardSnapshot
    let intervals: [ReportInterval]
    let peakMonths: [ReportInterval]
    let scope: DashboardScope
    let categoryComparisons: [CategorySpendingComparison]
    let dashboardController: DashboardController
    let transactionsController: TransactionsController

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            switch page {
            case .spending:
                DashboardSummaryView(snapshot: snapshot)
                CategorySpendingChart(intervals: intervals, peakMonths: peakMonths, scope: scope)
            case .categories:
                CategoryComparisonTableView(categories: categoryComparisons, scope: scope)
            case .distribution:
                SpendingPieChart(categoryTotals: snapshot.categoryTotals, peakMonths: peakMonths,
                                 highestTransactions: dashboardController.highestCategoryTransactions)
            case .cashFlow:
                PeriodCashFlowChart(intervals: intervals, scope: scope)
            case .balance:
                PeriodNetBalanceChart(intervals: intervals, scope: scope)
            case .transactions:
                DashboardTransactionsPageView(dashboardController: dashboardController, transactionsController: transactionsController)
            }
        }
        .padding(16)
        .padding(.trailing, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityIdentifier("dashboardReport.\(page.rawValue)")
    }
}
