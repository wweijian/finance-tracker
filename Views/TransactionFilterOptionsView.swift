import SwiftUI

struct TransactionFilterOptionsView: View {
    @ObservedObject var controller: TransactionsController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("More filters").font(.headline)
            Text("Amount (SGD)").foregroundStyle(.secondary)
            HStack {
                TextField("Minimum amount", text: $controller.minimumAmount, prompt: Text("Minimum"))
                Text("to").foregroundStyle(.secondary)
                TextField("Maximum amount", text: $controller.maximumAmount, prompt: Text("Maximum"))
            }
            .textFieldStyle(.roundedBorder)
            Picker("Remarks", selection: $controller.remarksFilter) {
                ForEach(TransactionRemarksFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            Picker("Status", selection: Binding(get: { controller.statusFilter }, set: controller.selectStatus)) {
                ForEach(TransactionStatusFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            if let error = controller.filterErrorMessage {
                Text(error).foregroundStyle(.red).font(.callout)
            }
            Text("Filters apply automatically. Click a column heading to sort.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Clear all filters", action: controller.clearFilters)
                    .disabled(!controller.hasActiveFilters)
            }
        }
        .padding(18)
        .frame(width: 330)
    }
}
