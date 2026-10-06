import SwiftUI

struct CashFlowReportView: View {
    let months: [MonthlyReport]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            MonthlyIncomeExpenseChart(months: months)
            Divider()
            NetBalanceChart(months: months)
        }
    }
}
