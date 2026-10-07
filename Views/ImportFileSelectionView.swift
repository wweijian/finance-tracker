import SwiftUI

struct ImportFileSelectionView: View {
    let filename: String?
    let errorMessage: String?
    let chooseFile: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: errorMessage == nil ? "doc.badge.plus" : "exclamationmark.triangle")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(errorMessage != nil ? "Couldn’t read this file" : filename == nil ? "Choose a transaction CSV" : "No transactions found")
                .font(.system(size: 15, weight: .semibold))
            Text(errorMessage ?? (filename == nil ? "Select a cleaned debit or credit CSV, or a Ledgerly CSV exported from the app. You’ll review every row before importing." : "This CSV contains no transaction rows. Choose another file to preview."))
                .font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                if let errorMessage { CopyImportErrorButton(message: errorMessage) }
                Button("Choose CSV…", action: chooseFile)
                    .keyboardShortcut("o", modifiers: [.command])
            }
        }
        .frame(maxWidth: 460)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
