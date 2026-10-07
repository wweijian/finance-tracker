import SwiftUI

struct LedgerStatusBarView: View {
    let transactionCount: Int
    let statusFilter: TransactionStatusFilter
    let isLoading: Bool
    let errorMessage: String?

    var body: some View {
        HStack(spacing: 8) {
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            } else {
                Text(isLoading ? "Loading transactions…" : "\(transactionCount) transactions")
                if statusFilter != .included {
                    Text(statusFilter == .excluded ? "· Deleted only" : "· Including deleted").foregroundStyle(.tertiary)
                }
            }
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityElement(children: .combine)
    }
}
