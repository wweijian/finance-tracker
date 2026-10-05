import SwiftUI

struct TransactionFilterView: View {
    @ObservedObject var controller: TransactionsController

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 180), spacing: 12)],
            alignment: .leading,
            spacing: 12
        ) {
            TextField("Search description, category, or date", text: $controller.searchText)
                .textFieldStyle(.roundedBorder)

            Picker("Type", selection: $controller.selectedType) {
                Text("All types").tag(TransactionType?.none)
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Text(type.rawValue.capitalized).tag(TransactionType?.some(type))
                }
            }

            Picker("Category", selection: $controller.selectedCategory) {
                Text("All categories").tag(String?.none)
                ForEach(controller.categories, id: \.self) { category in
                    Text(category).tag(String?.some(category))
                }
            }

            TransactionDateFilterView(controller: controller)

            Picker("Sort", selection: $controller.sortField) {
                ForEach(TransactionSortField.allCases) { field in
                    Text(field.rawValue).tag(field)
                }
            }

            HStack {
                Button {
                    controller.sortsAscending.toggle()
                } label: {
                    Image(systemName: controller.sortsAscending ? "arrow.up" : "arrow.down")
                }
                .help(controller.sortsAscending ? "Ascending" : "Descending")

                Toggle("Show deleted", isOn: $controller.includesDeleted)
                    .toggleStyle(.checkbox)
                    .onChange(of: controller.includesDeleted) {
                        controller.load()
                    }
            }
        }
    }
}
