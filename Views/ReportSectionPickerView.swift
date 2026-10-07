import SwiftUI

struct ReportSectionPickerView: View {
    @Binding var selection: DashboardReportSection

    var body: some View {
        HStack(spacing: 4) {
            ForEach(DashboardReportSection.allCases) { section in
                Button(section.rawValue) { selection = section }
                    .buttonStyle(.borderedProminent)
                    .tint(selection == section ? .teal : Color(nsColor: .controlColor))
                    .foregroundStyle(selection == section ? Color.white : Color.primary)
                    .accessibilityAddTraits(selection == section ? [.isSelected] : [])
            }
        }
        .accessibilityLabel("Report view")
    }
}
