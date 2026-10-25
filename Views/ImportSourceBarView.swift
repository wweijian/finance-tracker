import SwiftUI

struct ImportSourceBarView: View {
    let filename: String?
    let hasPreview: Bool
    @Binding var kind: CSVImportKind
    let isWorking: Bool
    let chooseFile: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            VStack(alignment: .leading, spacing: 7) {
                Text(hasPreview ? "Review transactions" : "Import transactions")
                    .font(.system(size: 21, weight: .semibold))
                if let filename {
                    Label(filename, systemImage: "doc.text")
                        .font(.subheadline).foregroundStyle(.secondary).lineLimit(1).help(filename)
                } else {
                    Text(hasPreview ? "Edit cells directly. Nothing is saved until you import." : "Choose a CSV, then review and edit its transactions.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 16)
            Picker("CSV format", selection: $kind) {
                ForEach(CSVImportKind.allCases) { kind in Text(kind.title).tag(kind) }
            }
            .pickerStyle(.menu)
            .frame(width: 170)
            if hasPreview {
                Button("Change CSV…", systemImage: "doc.badge.arrow.up", action: chooseFile)
                    .keyboardShortcut("o", modifiers: [.command])
            }
        }
        .disabled(isWorking)
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
