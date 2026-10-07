import SwiftUI

struct CashFlowReportView: View {
    let months: [MonthlyReport]
    @State private var selectedCategory: String?
    private var categories: [String] { Set(months.flatMap { $0.categoryAmounts.keys }).subtracting(["Investment"]).sorted() }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack {
                Text("Cash flow").font(.headline)
                Spacer()
                Picker("Graph category", selection: $selectedCategory) {
                    Text("All categories").tag(String?.none)
                    ForEach(categories, id: \.self) { Text($0).tag(Optional($0)) }
                    Text("Investment").tag(Optional("Investment"))
                }
                .tint(.teal)
                .frame(width: 220)
            }
            if let selectedCategory {
                CategoryCashFlowChart(months: months, category: selectedCategory)
            } else {
                MonthlyIncomeExpenseChart(months: months)
                Divider()
                NetBalanceChart(months: months)
            }
        }
        .onChange(of: categories) {
            if let selectedCategory, selectedCategory != "Investment", !categories.contains(selectedCategory) {
                self.selectedCategory = nil
            }
        }
    }
}
