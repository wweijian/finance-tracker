import SwiftUI

struct TransactionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var form: TransactionForm

    let categories: [String]
    let save: (TransactionForm) -> Void

    init(form: TransactionForm, categories: [String], save: @escaping (TransactionForm) -> Void) {
        _form = State(initialValue: form)
        self.categories = categories
        self.save = save
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(form.transactionID == nil ? "Add transaction" : "Edit transaction")
                .font(.title2.weight(.bold))

            Form {
                DatePicker("Date", selection: $form.date, displayedComponents: .date)
                TextField("Time (optional)", text: $form.time, prompt: Text("HH:mm"))
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
                TextField("Notes (optional)", text: $form.notes, axis: .vertical)
                    .lineLimit(2...4)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", action: dismiss.callAsFunction)
                Button("Save") {
                    save(form)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}
