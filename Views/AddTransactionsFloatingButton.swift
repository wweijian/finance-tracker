import SwiftUI

struct AddTransactionsFloatingButton: View {
    @Binding var showsMenu: Bool

    var body: some View {
        Button {
            showsMenu.toggle()
        } label: {
            ZStack {
                Circle().fill(.teal)
                Image(systemName: showsMenu ? "xmark" : "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        .help("Add a single transaction or bulk import a CSV")
        .accessibilityLabel(showsMenu ? "Close add transactions menu" : "Add transactions")
        .accessibilityValue(showsMenu ? "Expanded" : "Collapsed")
        .accessibilityIdentifier("addTransactionsFloatingButton")
    }
}
