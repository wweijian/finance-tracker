import SwiftUI

struct DashboardPageIndicatorView: View {
    let selection: DashboardPage?
    let select: (DashboardPage) -> Void

    var body: some View {
        VStack(spacing: 14) {
            ForEach(DashboardPage.allCases) { page in
                Button { select(page) } label: {
                    Capsule()
                        .fill(selection == page ? Color.teal : Color.secondary.opacity(0.35))
                        .frame(width: 7, height: selection == page ? 24 : 7)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(page.rawValue)
                .accessibilityLabel("Show \(page.rawValue)")
                .accessibilityValue(selection == page ? "Current page" : "")
                .accessibilityIdentifier("dashboardPage.\(page.rawValue)")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selection)
    }
}
