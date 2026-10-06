import SwiftUI

struct MonthlyDetailReportView: View {
    let months: [MonthlyReport]
    let report: MonthlyReport?
    @Binding var selectedMonth: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            MonthlyReportTable(months: months, selectedMonth: $selectedMonth)
            Divider()
            MonthlyComparisonView(months: months, report: report, selectedMonth: $selectedMonth)
        }
    }
}
