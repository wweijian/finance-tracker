import AppKit

@MainActor
final class LedgerlyAppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        guard let application = notification.object as? NSApplication else { return }
        // A standalone executable launched by `swift run` needs a foreground app policy.
        application.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let application = notification.object as? NSApplication else { return }
        // Let SwiftUI finish creating its initial window before requesting keyboard focus.
        DispatchQueue.main.async {
            application.windows.first { $0.isVisible && $0.canBecomeKey }?.makeKeyAndOrderFront(nil)
            application.activate()
        }
    }
}
