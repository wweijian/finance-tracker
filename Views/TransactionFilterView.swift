import SwiftUI

struct TransactionFilterView: View {
    @ObservedObject var controller: TransactionsController
    @State private var showsOptions = false

    var body: some View {
        ScreenControlBar {
            Picker("Type", selection: $controller.selectedType) {
                Text("All types").tag(TransactionType?.none)
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Text(type.rawValue.capitalized).tag(TransactionType?.some(type))
                }
            }
            .labelsHidden()
            .frame(width: 110)
            Picker("Category", selection: $controller.selectedCategory) {
                Text("All categories").tag(String?.none)
                ForEach(controller.categories, id: \.self) { category in
                    Text(category).tag(String?.some(category))
                }
            }
            .labelsHidden()
            .frame(width: 170)
            TransactionDateFilterView(controller: controller)
            Spacer(minLength: 8)
            Button(controller.additionalFilterCount == 0 ? "Filters" : "Filters (\(controller.additionalFilterCount))", systemImage: "line.3.horizontal.decrease") {
                showsOptions.toggle()
            }
            .labelStyle(.titleAndIcon)
            .help("Filter by amount, remarks, and transaction status")
            .popover(isPresented: $showsOptions) {
                TransactionFilterOptionsView(controller: controller)
            }
            Button("Clear filters", systemImage: "xmark.circle", action: controller.clearFilters)
                .labelStyle(.iconOnly)
                .disabled(!controller.hasActiveFilters)
                .help("Clear all filters and search")
        }
    }
}
