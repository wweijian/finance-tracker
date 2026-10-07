import AppKit
import SwiftUI

final class ImportTableHostingView: NSHostingView<AnyView> {
    var activateSelection: (() -> Void)?
    var toggleChecks: (() -> Void)?
    var deleteSelection: (() -> Void)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Keep table actions ahead of the sheet's shortcuts, while leaving text editors alone.
        guard event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty,
              let window, window.attachedSheet == nil,
              let table = window.firstResponder as? NSTableView,
              table.isDescendant(of: self) else {
            return super.performKeyEquivalent(with: event)
        }
        let action: (() -> Void)? = switch event.keyCode {
        case 36, 76: activateSelection // Return and keypad Enter.
        case 49: toggleChecks // Space toggles checkboxes without changing the highlight.
        case 51, 117: deleteSelection // Backward and forward Delete.
        default: nil
        }
        guard let action else { return super.performKeyEquivalent(with: event) }
        action()
        return true
    }
}
