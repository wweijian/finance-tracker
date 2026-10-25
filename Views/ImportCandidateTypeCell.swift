import SwiftUI

struct ImportCandidateTypeCell: View {
    @Binding var candidate: ImportCandidate

    var body: some View {
        Picker("Type", selection: Binding(
            get: { candidate.financeDetails?.transactionType ?? candidate.transactionType.rawValue },
            set: { value in
                guard let type = TransactionType(rawValue: value) else { return }
                var updated = candidate
                updated.transactionType = type
                updated.financeDetails?.transactionType = value
                candidate = updated
            }
        )) {
            if let raw = candidate.financeDetails?.transactionType, TransactionType(rawValue: raw) == nil {
                Text("Invalid type").tag(raw)
            }
            ForEach(TransactionType.allCases, id: \.self) { type in
                Text(type.rawValue.capitalized).tag(type.rawValue)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .controlSize(.small)
        .buttonStyle(.borderless)
        .accessibilityLabel("Type")
    }
}
