import SwiftUI

struct PeriodTransactionGroupView: View {
    let interval: ReportInterval
    let scope: DashboardScope
    let edit: (String?) -> Void
    let exclude: (String?) -> Void
    let restore: (String?) -> Void
    let isMutating: Bool

    var body: some View {
        DisclosureGroup {
            ForEach(interval.transactions) { transaction in
                PeriodTransactionRowView(transaction: transaction, edit: edit, exclude: exclude, restore: restore, isMutating: isMutating)
            }
        } label: {
            HStack(spacing: 12) {
                Text(scope == .monthly ? interval.startDate : interval.label).fontWeight(.medium)
                Text("\(interval.transactions.count) transactions").font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.vertical, 10)
        }
    }
}
