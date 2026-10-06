import SwiftUI

struct ImportCandidateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var candidate: ImportCandidate

    let categories: [String]
    let save: (ImportCandidate) -> Void

    init(candidate: ImportCandidate, categories: [String], save: @escaping (ImportCandidate) -> Void) {
        _candidate = State(initialValue: candidate)
        self.categories = categories
        self.save = save
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Edit imported transaction").font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("Row \(candidate.sourceRow)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            .padding(20)
            Divider()
            Form {
                LabeledContent("Date") {
                    DateTextField(title: "Transaction date", text: $candidate.transactionDate)
                }
                Picker("Type", selection: $candidate.transactionType) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                TextField("Amount (SGD)", text: $candidate.amount)
                TextField("Description", text: $candidate.description)
                Picker("Category", selection: $candidate.category) {
                    if !categories.contains(candidate.category) { Text(candidate.category).tag(candidate.category) }
                    ForEach(categories, id: \.self) { Text($0).tag($0) }
                }
                TextField("Remarks (optional)", text: $candidate.remarks, axis: .vertical)
                    .lineLimit(2...4)
            }
            .formStyle(.grouped)
            if let reason = candidate.rejectionReason { ImportErrorBannerView(message: reason) }
            Divider()
            HStack {
                Spacer()
                Button("Cancel", action: dismiss.callAsFunction).keyboardShortcut(.cancelAction)
                Button("Save and revalidate") {
                    save(candidate)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 480)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
