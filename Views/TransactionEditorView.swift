import SwiftUI

struct TransactionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var form: TransactionForm

    let categories: [String]
    let save: (TransactionForm) -> Void
    let errorMessage: String?
    let isMutating: Bool
    let delete: () -> Void
    let restore: () -> Void

    init(form: TransactionForm, categories: [String], errorMessage: String?, isMutating: Bool,
         save: @escaping (TransactionForm) -> Void, delete: @escaping () -> Void, restore: @escaping () -> Void) {
        _form = State(initialValue: form)
        self.categories = categories
        self.save = save
        self.errorMessage = errorMessage
        self.isMutating = isMutating
        self.delete = delete
        self.restore = restore
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
            }
            .formStyle(.grouped)
            .disabled(isMutating)

            RemarksEditorView(text: $form.notes)
                .disabled(isMutating)

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).textSelection(.enabled)
            }

            HStack {
                if form.transactionID != nil {
                    if form.isExcluded {
                        Button("Restore transaction", systemImage: "arrow.uturn.backward", action: restore)
                            .disabled(isMutating)
                    } else {
                        Button("Delete transaction", systemImage: "trash", role: .destructive, action: delete)
                            .disabled(isMutating)
                    }
                }
                Spacer()
                Button("Cancel", action: dismiss.callAsFunction)
                    .keyboardShortcut(.cancelAction)
                    .disabled(isMutating)
                Button("Save") {
                    save(form)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isMutating)
            }
        }
        .padding(24)
        .frame(width: 560, height: 540)
    }
}
