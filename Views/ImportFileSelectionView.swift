import SwiftUI

struct ImportFileSelectionView: View {
    let filename: String?
    let errorMessage: String?
    let chooseFile: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(errorMessage != nil ? "Couldn’t read this file" : filename == nil ? "Choose a transaction CSV" : "No transactions found",
                  systemImage: errorMessage == nil ? "doc.badge.plus" : "exclamationmark.triangle")
        } description: {
            Text(errorMessage ?? (filename == nil ? "Select a cleaned debit or credit CSV, or a Finance CSV exported from the app. You can upload without a Category column. Choose missing categories directly in the preview before importing." : "This CSV contains no transaction rows. Choose another file to preview."))
                .textSelection(.enabled)
        } actions: {
            HStack(spacing: 12) {
                if let errorMessage { CopyImportErrorButton(message: errorMessage) }
                Button("Choose CSV…", action: chooseFile)
                    .keyboardShortcut("o", modifiers: [.command])
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
