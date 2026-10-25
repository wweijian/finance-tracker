import SwiftUI

struct ImportCandidateAmountCell: View {
    @Binding var candidate: ImportCandidate
    var editingChanged: (Bool) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 2) {
            ImportCandidateTextCell(title: "Amount", text: $candidate.amount,
                                    editingChanged: editingChanged, alignment: .trailing)
                .monospacedDigit()
            if candidate.financeDetails != nil {
                ImportCandidateTextCell(title: "Currency", text: Binding(
                    get: { candidate.currency },
                    set: { candidate.financeDetails?.currency = $0 }
                ), editingChanged: editingChanged)
                .frame(width: 44)
            } else {
                Text(candidate.currency).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
