import SwiftUI

struct TransactionDateFilterView: View {
    @ObservedObject var controller: TransactionsController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("Date filter", selection: $controller.dateFilterMode) {
                ForEach(TransactionDateFilterMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }

            switch controller.dateFilterMode {
            case .all:
                EmptyView()
            case .year:
                Picker("Year", selection: $controller.selectedYear) {
                    ForEach(controller.availableYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
            case .range:
                HStack {
                    DatePicker("From", selection: $controller.startDate, displayedComponents: .date)
                    DatePicker("To", selection: $controller.endDate, displayedComponents: .date)
                }
            }
        }
    }
}
