import SwiftUI

struct FloatingScreenToggleButton: View {
    let screen: AppScreen
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            Image(systemName: destinationIcon)
                .font(.title3.weight(.semibold))
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.borderedProminent)
        .clipShape(Circle())
        .shadow(radius: 8, y: 4)
        .help(destinationLabel)
        .accessibilityLabel(destinationLabel)
    }

    private var destinationIcon: String {
        screen == .dashboard ? "list.bullet" : "chart.pie"
    }

    private var destinationLabel: String {
        screen == .dashboard ? "Show transactions" : "Show dashboard"
    }
}
