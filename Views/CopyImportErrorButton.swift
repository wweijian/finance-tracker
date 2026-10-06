import AppKit
import SwiftUI

struct CopyImportErrorButton: View {
    let message: String

    var body: some View {
        Button("Copy error") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(message, forType: .string)
        }
        .buttonStyle(.bordered)
    }
}
