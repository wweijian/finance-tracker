import SwiftUI

struct BulkImportSummaryView: View {
    let summary: BulkImportSummary
    let filename: String?
    let isUndoing: Bool
    let errorMessage: String?
    let undo: () -> Void
    let done: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2).foregroundStyle(.teal)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Imported \(summary.acceptedCount) transactions")
                        .font(.headline)
                    if summary.rejectedCount > 0 {
                        Text("\(summary.rejectedCount) rows skipped")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if let filename {
                        Text(filename).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding(24)
            if let errorMessage { ImportErrorBannerView(message: errorMessage) }
            Divider()
            HStack {
                Button("Undo import", role: .destructive, action: undo)
                    .help("Remove only the transactions added by this import")
                    .disabled(isUndoing || summary.acceptedCount == 0)
                if isUndoing { ProgressView().controlSize(.small).accessibilityLabel("Undoing import") }
                Spacer()
                Button("Done", action: done)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(isUndoing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
