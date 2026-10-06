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
            VStack(alignment: .leading, spacing: 4) {
                Text("Import complete").font(.system(size: 13, weight: .semibold))
                if let filename { Text(filename).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            Divider()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 30, weight: .light)).foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Grid(alignment: .leading, horizontalSpacing: 36, verticalSpacing: 10) {
                    GridRow {
                        Text("Imported transactions")
                        Text(String(summary.acceptedCount)).monospacedDigit().fontWeight(.semibold)
                    }
                    GridRow {
                        Text("Skipped rows").foregroundStyle(.secondary)
                        Text(String(summary.rejectedCount)).monospacedDigit().foregroundStyle(.secondary)
                    }
                }
                Text("The CSV file is unchanged.").font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
            if let errorMessage { ImportErrorBannerView(message: errorMessage) }
            Divider()
            HStack {
                Button("Undo import", role: .destructive, action: undo)
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
        .frame(width: 480)
        .frame(minHeight: 320)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
