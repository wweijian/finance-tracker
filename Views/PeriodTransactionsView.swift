import SwiftUI

struct PeriodTransactionsView: View {
    let intervals: [ReportInterval]
    let scope: DashboardScope
    @ObservedObject var controller: TransactionsController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                ReportChartHeaderView(title: "Transactions", subtitle: "Grouped by \(scope.intervalLabel.lowercased()) · expand to view and edit")
                Menu {
                    Picker("Transaction status", selection: Binding(get: { controller.statusFilter }, set: controller.selectStatus)) {
                        ForEach(TransactionStatusFilter.allCases) { filter in Text(filter.rawValue).tag(filter) }
                    }
                } label: {
                    Label(controller.statusFilter.rawValue, systemImage: "line.3.horizontal.decrease")
                }
                .fixedSize()
                .disabled(controller.isMutating)
                .help("Show active or deleted transactions")
            }
            if controller.isLoading {
                ProgressView("Loading transactions…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = controller.errorMessage {
                DashboardErrorView(message: error, retry: controller.load)
            } else if intervals.allSatisfy({ $0.transactions.isEmpty }) {
                ContentUnavailableView("No transactions", systemImage: "list.bullet.rectangle", description: Text("Add a transaction or import a CSV to begin."))
            } else {
                List(intervals.filter { !$0.transactions.isEmpty }) { interval in
                    PeriodTransactionGroupView(interval: interval, scope: scope, edit: controller.edit,
                                               exclude: controller.exclude, restore: controller.include, isMutating: controller.isMutating)
                }
                .listStyle(.inset)
                .accessibilityLabel("Transactions grouped by \(scope.intervalLabel.lowercased())")
            }
        }
        .frame(maxHeight: .infinity)
    }
}
