import Charts
import SwiftUI

struct SpendingDistributionChart: View {
    let categories: [CategoryTotal]
    let totalCents: Int
    let colors: [String: Color]
    @State private var selectedAngle: Int?

    private var selectedCategory: CategoryTotal? {
        guard let selectedAngle else { return nil }
        var cumulative = 0
        return categories.first { total in
            cumulative += total.amountCents
            return selectedAngle < cumulative
        }
    }

    var body: some View {
        Chart(categories) { total in
            SectorMark(angle: .value("Spending in cents", total.amountCents), innerRadius: .ratio(0.68), angularInset: 1)
                .foregroundStyle(by: .value("Category", total.category))
                .opacity(selectedCategory == nil || selectedCategory?.id == total.id ? 1 : 0.45)
                .accessibilityLabel(total.category)
                .accessibilityValue("\(CurrencyFormatter().string(for: total.amountCents)), \(total.percentage(of: totalCents)) of spending")
        }
        .chartLegend(.hidden)
        .chartForegroundStyleScale(domain: categories.map(\.category), range: categories.map { colors[$0.category] ?? .teal })
        .chartAngleSelection(value: $selectedAngle)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let point):
                            guard let frame = proxy.plotFrame else { return }
                            let plot = geometry[frame]
                            selectCategory(at: point, in: plot)
                        case .ended: selectedAngle = nil
                        }
                    }
            }
        }
        .chartBackground { _ in
            SpendingDistributionSelectionView(category: selectedCategory, totalCents: totalCents)
                .allowsHitTesting(false)
        }
        .frame(width: 430, height: 400)
        .accessibilityLabel("Spending distribution by category, with percentage shares")
    }

    private func selectCategory(at point: CGPoint, in plot: CGRect) {
        let dx = point.x - plot.midX
        let dy = point.y - plot.midY
        let radius = min(plot.width, plot.height) / 2
        let distance = hypot(dx, dy)
        guard distance <= radius && distance >= radius * 0.68 else {
            selectedAngle = nil
            return
        }
        let angle = (atan2(dy, dx) + .pi / 2 + 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi)
        selectedAngle = Int(angle / (2 * .pi) * Double(totalCents))
    }
}
