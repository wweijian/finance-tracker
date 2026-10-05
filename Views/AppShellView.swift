import SwiftUI

struct AppShellView: View {
    @ObservedObject var dashboardController: DashboardController
    @ObservedObject var transactionsController: TransactionsController
    @State private var screen: AppScreen = .dashboard

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            content
            FloatingScreenToggleButton(screen: screen, toggle: toggleScreen)
                .padding(28)
        }
        .frame(minWidth: 1_000, minHeight: 700)
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case .dashboard:
            DashboardView(controller: dashboardController)
        case .transactions:
            TransactionsView(controller: transactionsController)
        }
    }

    private func toggleScreen() {
        screen = screen == .dashboard ? .transactions : .dashboard
    }
}
