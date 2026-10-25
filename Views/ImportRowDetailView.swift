import SwiftUI

struct ImportRowDetailView: View {
    let candidate: ImportCandidate

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: candidate.isReady ? "checkmark.circle" : "exclamationmark.circle")
                .foregroundStyle(candidate.isReady ? Color.teal : .orange)
            VStack(alignment: .leading, spacing: 3) {
                Text("Row \(candidate.sourceRow): \(candidate.description)")
                    .font(.callout.weight(.medium)).lineLimit(2)
                Text(candidate.rejectionReason ?? (candidate.financeDetails?.deletedAt == nil
                     ? "Ready to import." : "This transaction will be imported as deleted."))
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
