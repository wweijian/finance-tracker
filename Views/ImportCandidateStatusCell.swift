import SwiftUI

struct ImportCandidateStatusCell: View {
    let candidate: ImportCandidate

    var body: some View {
        Label(title, systemImage: candidate.isReady ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(candidate.isReady ? Color.teal : .orange)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background((candidate.isReady ? Color.teal : .orange).opacity(0.08), in: RoundedRectangle(cornerRadius: 5))
            .help(candidate.rejectionReason ?? candidate.statusLabel)
            .accessibilityLabel(candidate.statusLabel)
    }

    private var title: String {
        if !candidate.isReady { return "Review" }
        return candidate.financeDetails?.deletedAt == nil ? "Ready" : "Deleted"
    }
}
