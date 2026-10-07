import SwiftUI

struct DashboardReportSelectorView: View {
    @Binding var selection: DashboardReportSection
    let periodLabel: String
    @State private var showsComparisonHelp = false

    var body: some View {
        ScreenControlBar {
            Text(periodLabel)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Spacer()
            ReportSectionPickerView(selection: $selection)
            Button("About comparisons", systemImage: "info.circle") {
                showsComparisonHelp.toggle()
            }
            .labelStyle(.iconOnly)
            .help("How period comparisons are calculated")
            .popover(isPresented: $showsComparisonHelp) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comparing periods").font(.headline)
                    Text(selection == .monthly ? "Monthly spending compares the selected month with the previous month. The trend shows the twelve months ending with your selection. Full months compare whole months; partial periods use matching days, clamped to shorter months." : "YoY compares the matching period last year. Full months compare whole months; partial periods use matching days, clamped to shorter months.")
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
