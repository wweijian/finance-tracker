import SwiftUI

struct DashboardView: View {
    @ObservedObject var controller: DashboardController
    @State private var section: DashboardReportSection = .cashFlow
    @State private var showsDateFilter = false

    var body: some View {
        VStack(spacing: 0) {
            DashboardReportSelectorView(selection: $section, periodLabel: controller.periodLabel)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !controller.isLoading && controller.errorMessage == nil {
                        DashboardSummaryView(snapshot: controller.snapshot)
                        Divider()
                    }
                    DashboardContentView(
                        snapshot: controller.snapshot,
                        section: section,
                        isLoading: controller.isLoading,
                        errorMessage: controller.errorMessage,
                        comparisonReport: controller.comparisonReport,
                        comparisonMonth: $controller.comparisonMonth,
                        retry: controller.load
                    )
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                DashboardYearPickerView(
                    year: controller.selectedYear,
                    availableYears: controller.availableYears,
                    selectYear: controller.selectYear,
                    showPreviousYear: controller.showPreviousYear,
                    showNextYear: controller.showNextYear
                )
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Date range", systemImage: controller.filtersDateRange ? "calendar.badge.clock" : "calendar") {
                    showsDateFilter.toggle()
                }
                .help("Filter the reporting period")
                .popover(isPresented: $showsDateFilter) {
                    DashboardFilterView(controller: controller)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Refresh reports", systemImage: "arrow.clockwise", action: controller.load)
                    .disabled(controller.isLoading)
                    .help("Refresh reports")
            }
        }
        .task { controller.load() }
    }
}
