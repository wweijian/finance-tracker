import SwiftUI

struct AppScreenFloatingButton: View {
    @Binding var screen: AppScreen

    var body: some View {
        Button {
            screen = screen == .dashboard ? .transactions : .dashboard
        } label: {
            Label(screen == .dashboard ? "Transactions" : "Overview",
                  systemImage: screen == .dashboard ? "list.bullet.rectangle" : "chart.xyaxis.line")
                .font(.system(size: 13, weight: .semibold))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.teal, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        .help(screen == .dashboard ? "Show transactions" : "Show overview")
        .accessibilityIdentifier("appScreenFloatingButton")
    }
}
