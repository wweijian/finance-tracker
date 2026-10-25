import SwiftUI

struct ImportTableActionsView: View {
    let highlightedCount: Int
    let checkedCount: Int
    let allHighlightedChecked: Bool
    let allRowsChecked: Bool
    let hasVisibleRows: Bool
    let toggleAll: () -> Void
    let toggleChecks: () -> Void
    let remove: () -> Void
    @ObservedObject var scrollController: ImportTableScrollController

    var body: some View {
        HStack(spacing: 12) {
            Button(allRowsChecked ? "Uncheck all" : "Check all", action: toggleAll)
                .disabled(!hasVisibleRows)
            Button(allHighlightedChecked ? "Uncheck highlighted" : "Check highlighted", action: toggleChecks)
                .keyboardShortcut("k", modifiers: [.command, .shift])
                .disabled(highlightedCount == 0)
            if checkedCount > 0 {
                Button("Delete checked (\(checkedCount))", systemImage: "trash", role: .destructive, action: remove)
                    .keyboardShortcut(.delete, modifiers: [.command])
            }
            Spacer(minLength: 12)
            ImportHorizontalScrollControls(controller: scrollController)
        }
        .controlSize(.small)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
