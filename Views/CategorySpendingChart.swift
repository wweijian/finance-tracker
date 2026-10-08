import Charts
import SwiftUI

struct CategorySpendingChart: View {
    let intervals: [ReportInterval]
    let peakMonths: [ReportInterval]
    let scope: DashboardScope
    @State private var hoveredInterval: String?
    @State private var hoveredCategory: String?

    private let categories: [String]

    init(intervals: [ReportInterval], peakMonths: [ReportInterval], scope: DashboardScope) {
        self.intervals = intervals
        self.peakMonths = peakMonths
        self.scope = scope
        categories = Set(intervals.flatMap { $0.categories.filter { $0.amountCents > 0 }.map(\.category) }).sorted()
    }
    private var selectedInterval: ReportInterval? { intervals.first { $0.label == hoveredInterval } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReportChartHeaderView(title: scope == .yearly ? "Monthly spending by category" : "Daily spending by category",
                                  subtitle: "Investments excluded")
            if categories.isEmpty {
                ChartEmptyView(message: "No spending in this period.")
                    .frame(maxHeight: .infinity)
            } else {
                chart
                SpendingHoverDetailView(interval: selectedInterval, category: hoveredCategory,
                                        peak: hoveredCategory.flatMap { ReportInterval.peak(for: $0, in: peakMonths) })
            }
        }
        .onHover { isHovered in if !isHovered { clearSelection() } }
    }

    private var chart: some View {
        Chart {
            ForEach(intervals) { interval in
                ForEach(interval.categories) { category in
                    if category.amountCents > 0 {
                        BarMark(x: .value(scope.intervalLabel, interval.label),
                                y: .value("SGD", Decimal(category.amountCents) / 100))
                            .foregroundStyle(by: .value("Category", category.category))
                            .opacity(hoveredCategory == nil || hoveredCategory == category.category ? 1 : 0.35)
                            .accessibilityLabel("\(interval.startDate), \(category.category)")
                            .accessibilityValue(CurrencyFormatter().string(for: category.amountCents))
                    }
                }
            }
        }
        .chartXScale(domain: intervals.map(\.label))
        .chartForegroundStyleScale(domain: categories, range: categories.map { CategoryChartStyle.color(for: $0) })
        .chartLegend(position: .top, alignment: .leading)
        .chartYAxis { AxisMarks(position: .leading) }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let point): select(at: point, proxy: proxy, geometry: geometry)
                        case .ended: break
                        }
                    }
            }
        }
        .frame(maxHeight: .infinity)
        .accessibilityLabel("\(scope == .yearly ? "Monthly" : "Daily") spending, stacked by category")
        .onChange(of: intervals.map(\.startDate)) { clearSelection() }
    }

    private func select(at point: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let frame = proxy.plotFrame else { return }
        let plot = geometry[frame]
        guard plot.contains(point) else { return }
        guard let label = proxy.value(atX: point.x - plot.minX, as: String.self),
              let amount = proxy.value(atY: point.y - plot.minY, as: Double.self),
              let interval = intervals.first(where: { $0.label == label }) else {
            clearSelection()
            return
        }
        let cents = (amount * 100).rounded(.down)
        guard cents.isFinite, cents >= 0, cents < Double(Int.max) else {
            clearSelection()
            return
        }
        let category = interval.category(atSpendingCents: Int(cents))
        guard hoveredInterval != label || hoveredCategory != category else { return }
        hoveredInterval = label
        hoveredCategory = category
    }

    private func clearSelection() {
        if hoveredInterval != nil { hoveredInterval = nil }
        if hoveredCategory != nil { hoveredCategory = nil }
    }
}
