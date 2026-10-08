import Charts
import SwiftUI

struct SpendingDistributionChart: View {
    let categories: [CategoryTotal]
    let totalCents: Int
    let colors: [String: Color]
    var peakMonths: [ReportInterval] = []
    var highestTransactions: [String: TransactionListItem] = [:]
    @State private var selectedCategoryID: String?

    private var selectedCategory: CategoryTotal? {
        categories.first { $0.id == selectedCategoryID }
    }

    var body: some View {
        VStack(spacing: 12) {
            chart
            if !highestTransactions.isEmpty {
                ScrollView(.vertical) {
                    HighestTransactionDetailView(transaction: selectedCategoryID.flatMap { highestTransactions[$0] })
                }
                .frame(height: 100)
            }
        }
        .onHover { isHovered in if !isHovered { selectAngle(nil) } }
    }

    private var chart: some View {
        Chart(categories) { total in
            SectorMark(angle: .value("Spending in cents", total.amountCents), innerRadius: .ratio(0.68), angularInset: 1)
                .foregroundStyle(by: .value("Category", total.category))
                .opacity(selectedCategory == nil || selectedCategory?.id == total.id ? 1 : 0.45)
                .accessibilityLabel(total.category)
                .accessibilityValue("\(CurrencyFormatter().string(for: total.amountCents)), \(total.percentage(of: totalCents)) of spending")
        }
        .chartLegend(position: .top, alignment: .leading)
        .chartForegroundStyleScale(domain: categories.map(\.category), range: categories.map { colors[$0.category] ?? .teal })
        .chartAngleSelection(value: Binding<Int?>(get: { selectedCategoryAngle }, set: selectAngle))
        .chartBackground { proxy in
            GeometryReader { geometry in
                if let frame = proxy.plotFrame {
                    let plot = geometry[frame]
                    SpendingDistributionSelectionView(category: selectedCategory, totalCents: totalCents,
                                                       peak: selectedCategory.flatMap { ReportInterval.peak(for: $0.category, in: peakMonths) })
                        .frame(width: min(plot.width, plot.height) * 0.6)
                        .position(x: plot.midX, y: plot.midY)
                }
            }
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Spending distribution by category, with percentage shares")
        .onChange(of: categories.map(\.amountCents)) { selectAngle(nil) }
    }

    private var selectedCategoryAngle: Int? {
        var cumulative = 0
        for category in categories {
            if category.id == selectedCategoryID { return cumulative + category.amountCents / 2 }
            cumulative += category.amountCents
        }
        return nil
    }

    private func selectAngle(_ angle: Int?) {
        var cumulative = 0
        let category = angle.flatMap { value in
            categories.first {
                cumulative += $0.amountCents
                return value < cumulative
            }
        }
        if selectedCategoryID != category?.id { selectedCategoryID = category?.id }
    }
}
