import SwiftUI

struct ImportTableActionsView: View {
    let highlightedCount: Int
    let checkedCount: Int
    let allHighlightedChecked: Bool
    let toggleChecks: () -> Void
    let edit: () -> Void
    let remove: () -> Void

    var body: some View {
        HStack {
            Button(allHighlightedChecked ? "Uncheck highlighted" : "Check highlighted", action: toggleChecks)
                .keyboardShortcut("k", modifiers: [.command, .shift])
                .help("Check or uncheck highlighted rows (⇧⌘K)")
                .disabled(highlightedCount == 0)
            Button("Edit highlighted…", systemImage: "pencil", action: edit)
                .keyboardShortcut("e", modifiers: [.command])
                .disabled(highlightedCount != 1)
            Spacer()
            Button("Delete checked (\(checkedCount))", systemImage: "trash", role: .destructive, action: remove)
                .keyboardShortcut(.delete, modifiers: [.command])
                .disabled(checkedCount == 0)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
