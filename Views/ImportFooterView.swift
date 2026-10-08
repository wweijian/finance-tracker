import SwiftUI

struct ImportFooterView: View {
    let readyCount: Int
    let rejectedCount: Int
    let activity: ImportActivity?
    let cancel: () -> Void
    let requestImport: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let activity, readyCount + rejectedCount > 0 {
                ProgressView().controlSize(.small)
                Text(activity.description).font(.caption).foregroundStyle(.secondary)
            } else if activity != nil {
                Text("Preparing preview…").font(.caption).foregroundStyle(.secondary)
            } else if readyCount + rejectedCount > 0 {
                Text(rejectedCount > 0 ? "\(readyCount) ready · \(rejectedCount) will be skipped" : "\(readyCount) transactions ready to import")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Preview before importing").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Cancel", action: cancel)
                .keyboardShortcut(.cancelAction)
                .disabled(activity != nil)
            Button(readyCount > 0 ? "Import \(readyCount) transactions" : "Import", action: requestImport)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("i", modifiers: [.command])
                .disabled(readyCount == 0 || activity != nil)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
