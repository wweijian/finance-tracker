import SwiftUI

struct ImportCandidateCategoryCell: View {
    @Binding var category: String
    let categories: [String]

    var body: some View {
        Picker("Category", selection: $category) {
            if !categories.contains(category) {
                Text(category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Choose category" : category)
                    .tag(category)
            }
            ForEach(categories, id: \.self) { category in Text(category).tag(category) }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .controlSize(.small)
        .buttonStyle(.borderless)
        .accessibilityLabel("Category")
    }
}
