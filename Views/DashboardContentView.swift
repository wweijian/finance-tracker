import SwiftUI

struct DashboardContentView: View {
    let snapshot: DashboardSnapshot
    let section: DashboardReportSection
    let isLoading: Bool
    let errorMessage: String?
    let comparisonReport: MonthlyReport?
    @Binding var comparisonMonth: Int
    let retry: () -> Void

    var body: some View {
        if isLoading {
            ProgressView("Loading reports…").frame(maxWidth: .infinity, minHeight: 400)
        } else if let errorMessage {
            DashboardErrorView(message: errorMessage, retry: retry)
        } else if snapshot.transactionCount == 0 {
            DashboardEmptyView()
        } else {
            switch section {
            case .cashFlow:
                CashFlowReportView(months: snapshot.months)
            case .categories:
                SpendingBreakdownView(categoryTotals: snapshot.categoryTotals)
            case .monthly:
                MonthlyDetailReportView(months: snapshot.months, report: comparisonReport, selectedMonth: $comparisonMonth)
            }
        }
    }
}
