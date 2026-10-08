import SwiftUI

struct ImportSourceBarView: View {
    let filename: String?
    @Binding var kind: CSVImportKind
    let isWorking: Bool
    let chooseFile: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Import transactions").font(.headline)
                Label(filename ?? "No file selected", systemImage: "doc.text")
                    .font(.caption).foregroundStyle(.secondary)
                    .lineLimit(1).help(filename ?? "Choose a cleaned bank CSV or a Ledgerly export")
            }
            Spacer(minLength: 12)
            Picker("Format", selection: $kind) {
                ForEach(CSVImportKind.allCases) { kind in Text(kind.title).tag(kind) }
            }
            .frame(width: 150)
            if filename != nil {
                Button("Change file…", action: chooseFile)
                    .keyboardShortcut("o", modifiers: [.command])
                    .help("Choose a debit, credit, or Ledgerly CSV from this Mac")
            }
        }
        .disabled(isWorking)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
