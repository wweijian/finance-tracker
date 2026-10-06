import SwiftUI

struct DashboardFilterView: View {
    @ObservedObject var controller: DashboardController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reporting period").font(.headline)
            Toggle("Use a custom date range", isOn: $controller.filtersDateRange)
                .toggleStyle(.checkbox)
                .onChange(of: controller.filtersDateRange) { controller.load() }
            DateSelectionView(title: "From", date: $controller.startDate)
                .onChange(of: controller.startDate) { if controller.filtersDateRange { controller.load() } }
                .disabled(!controller.filtersDateRange)
            DateSelectionView(title: "Through", date: $controller.endDate)
                .onChange(of: controller.endDate) { if controller.filtersDateRange { controller.load() } }
                .disabled(!controller.filtersDateRange)
            Text("Dates must fall within \(String(controller.selectedYear)). Changes apply automatically.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(width: 310)
    }
}
