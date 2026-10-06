import SwiftUI

struct DashboardReportSelectorView: View {
    @Binding var selection: DashboardReportSection
    let periodLabel: String
    @State private var showsComparisonHelp = false

    var body: some View {
        ScreenControlBar {
            Picker("Report", selection: $selection) {
                ForEach(DashboardReportSection.allCases) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 300)
            Spacer()
            Text(periodLabel)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Button("About comparisons", systemImage: "info.circle") {
                showsComparisonHelp.toggle()
            }
            .labelStyle(.iconOnly)
            .help("How month-on-month and year-on-year changes are calculated")
            .popover(isPresented: $showsComparisonHelp) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comparing periods").font(.headline)
                    Text("MoM compares the previous month. YoY compares the matching period last year. Full months compare whole months; partial periods use matching days, clamped to shorter months.")
                    Text("Changes from zero have no percentage. Negative balances use the magnitude of the prior balance, so improvements are positive.")
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .padding(18)
                .frame(width: 330)
            }
        }
    }
}
