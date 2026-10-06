import SwiftUI

struct TransactionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var form: TransactionForm

    let categories: [String]
    let save: (TransactionForm) -> Void
    let errorMessage: String?

    init(form: TransactionForm, categories: [String], errorMessage: String?, save: @escaping (TransactionForm) -> Void) {
        _form = State(initialValue: form)
        self.categories = categories
        self.save = save
        self.errorMessage = errorMessage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(form.transactionID == nil ? "Add transaction" : "Edit transaction")
                .font(.title3.weight(.semibold))

            Form {
                DateSelectionView(title: "Date", date: $form.date)
                Picker("Type", selection: $form.transactionType) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                TextField("Amount (SGD)", text: $form.amount)
                TextField("Description", text: $form.description)
                Picker("Category", selection: $form.category) {
                    if !categories.contains(form.category) {
                        Text(form.category).tag(form.category)
                    }
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                TextField("Remarks (optional)", text: $form.notes, axis: .vertical)
                    .lineLimit(2...4)
            }
            .formStyle(.grouped)

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).textSelection(.enabled)
            }

            HStack {
                Spacer()
                Button("Cancel", action: dismiss.callAsFunction)
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    save(form)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}
