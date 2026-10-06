import SwiftUI

struct TransactionDateFilterView: View {
    @ObservedObject var controller: TransactionsController

    var body: some View {
        HStack(spacing: 8) {
            Picker("Date filter", selection: $controller.dateFilterMode) {
                ForEach(TransactionDateFilterMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .labelsHidden()
            .frame(width: 110)
            switch controller.dateFilterMode {
            case .all:
                EmptyView()
            case .year:
                Picker("Year", selection: $controller.selectedYear) {
                    ForEach(controller.availableYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .labelsHidden()
                .frame(width: 80)
            case .range:
                Text("From").foregroundStyle(.secondary)
                DateTextField(title: "From date", text: $controller.startDateText)
                Text("Through").foregroundStyle(.secondary)
                DateTextField(title: "Through date", text: $controller.endDateText)
            }
        }
    }
}
