import SwiftUI

struct ImportCandidateFieldsView: View {
    @Binding var candidate: ImportCandidate
    let categories: [String]

    var body: some View {
        Form {
            LabeledContent("Date") {
                DateTextField(title: "Date", text: $candidate.transactionDate)
            }
            Picker("Type", selection: typeBinding) {
                if let rawType = candidate.ledgerlyDetails?.transactionType, TransactionType(rawValue: rawType) == nil {
                    Text("\(rawType.isEmpty ? "Missing type" : rawType) (invalid)").tag(rawType)
                }
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Text(type.rawValue.capitalized).tag(type.rawValue)
                }
            }
            TextField("Amount (\(candidate.currency))", text: $candidate.amount)
            TextField("Description", text: $candidate.description)
            Picker("Category", selection: $candidate.category) {
                if !categories.contains(candidate.category) {
                    Text(candidate.category.isEmpty ? "Choose a category" : candidate.category).tag(candidate.category)
                }
                ForEach(categories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }
            if candidate.ledgerlyDetails != nil {
                TextField("Currency", text: Binding(
                    get: { candidate.currency },
                    set: { candidate.ledgerlyDetails?.currency = $0 }
                ))
            }
            RemarksEditorView(text: $candidate.remarks)
        }
        .formStyle(.grouped)
    }

    private var typeBinding: Binding<String> {
        Binding(
            get: { candidate.ledgerlyDetails?.transactionType ?? candidate.transactionType.rawValue },
            set: { value in
                guard let type = TransactionType(rawValue: value) else { return }
                candidate.transactionType = type
                candidate.ledgerlyDetails?.transactionType = value
            }
        )
    }
}
