import SwiftUI

struct DashboardPeriodControlsView: View {
    let scope: DashboardScope
    let periodLabel: String
    let canGoBack: Bool
    let canGoForward: Bool
    let goBack: () -> Void
    let goForward: () -> Void
    let selectScope: (DashboardScope) -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
            }
            .disabled(!canGoBack)
            .accessibilityLabel(scope == .monthly ? "Previous month" : "Previous year")
            Text(periodLabel)
                .font(.title3.weight(.medium))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(minWidth: 170)
            Button(action: goForward) {
                Image(systemName: "chevron.right")
            }
            .disabled(!canGoForward)
            .accessibilityLabel(scope == .monthly ? "Next month" : "Next year")
            Picker("Reporting period", selection: scopeSelection) {
                Text("Month").tag(DashboardScope.monthly)
                Text("Year").tag(DashboardScope.yearly)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 160)
            .accessibilityValue(scope == .monthly ? "Monthly" : "Yearly")
            .accessibilityIdentifier("dashboardScopePicker")
        }
    }

    private var scopeSelection: Binding<DashboardScope> {
        Binding(get: { scope }, set: { selection in
            // The native segmented control can update its binding during a view update.
            Task { @MainActor in selectScope(selection) }
        })
    }
}
