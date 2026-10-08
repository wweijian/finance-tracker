import SwiftUI

struct ReportSectionPickerView: View {
    @Binding var selection: DashboardReportSection

    var body: some View {
        Picker("Report view", selection: $selection) {
            ForEach(DashboardReportSection.allCases) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}
