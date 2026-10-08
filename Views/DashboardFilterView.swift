import SwiftUI

struct DashboardFilterView: View {
    @ObservedObject var controller: DashboardController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reporting period").font(.headline)
            Toggle("Use a custom date range", isOn: $controller.filtersDateRange)
                .toggleStyle(.checkbox)
                .onChange(of: controller.filtersDateRange) { controller.load() }
            LabeledContent("From") {
                DateTextField(title: "From date", text: $controller.startDateText)
            }
            LabeledContent("Through") {
                DateTextField(title: "Through date", text: $controller.endDateText)
            }
            Text("Choose dates within \(String(controller.selectedYear)), then apply the range.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let error = controller.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }
            HStack {
                Spacer()
                Button("Apply date range", action: controller.applyDateRange)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .frame(width: 310)
    }
}
