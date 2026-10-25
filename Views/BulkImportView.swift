import SwiftUI
import UniformTypeIdentifiers

struct BulkImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsFileImporter = false
    @State private var selectedKind: CSVImportKind = .debit
    @State private var selectedFileURL: URL?
    @State private var fileSelectionError: String?
    @State private var showsSkipWarning = false

    @Binding var candidates: [ImportCandidate]
    let summary: BulkImportSummary?
    let errorMessage: String?
    let activity: ImportActivity?
    let previewCSV: (URL, CSVImportKind) -> Void
    let removedRowCount: Int
    let removeRows: (Set<String>) -> Void
    let undoRowRemovals: () -> Void
    let commitAll: () -> Void
    let undo: () -> Void
    let cancel: () -> Void
    let categories: [String]
    @Binding var removalIDs: Set<String>
    let confirmRemoval: (Set<String>) -> Void

    var body: some View {
        Group {
            if let summary {
                BulkImportSummaryView(
                    summary: summary,
                    filename: selectedFileURL?.lastPathComponent,
                    isUndoing: activity != nil,
                    errorMessage: errorMessage,
                    undo: undo,
                    done: close
                )
            } else {
                importSheet
            }
        }
        .interactiveDismissDisabled(isWorking)
        .onExitCommand { if !isWorking { close() } }
        .fileImporter(isPresented: $showsFileImporter, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            selectFile(result)
        }
        .alert("Import without rejected rows?", isPresented: $showsSkipWarning) {
            Button("Cancel", role: .cancel) {}
            Button("Skip rows and import", action: commitAll)
        } message: {
            Text("Finance will import \(preview.readyCount) ready transactions and skip \(preview.rejectedCount) rejected rows. The CSV file stays unchanged.")
        }
    }

    private var importSheet: some View {
        VStack(spacing: 0) {
            ImportSourceBarView(
                filename: selectedFileURL?.lastPathComponent,
                hasPreview: !isCompact,
                kind: $selectedKind,
                isWorking: isWorking,
                chooseFile: chooseFile
            )
            Divider()
            ImportContentView(
                candidates: $candidates,
                filename: selectedFileURL?.lastPathComponent,
                activity: activity,
                errorMessage: fileSelectionError ?? errorMessage,
                chooseFile: chooseFile,
                removedRowCount: removedRowCount,
                remove: removeRows,
                undoRemovals: undoRowRemovals,
                categories: categories
            )
            Divider()
            ImportFooterView(
                readyCount: preview.readyCount,
                rejectedCount: preview.rejectedCount,
                activity: activity,
                cancel: close,
                requestImport: requestImport
            )
        }
        .frame(
            minWidth: isCompact ? 600 : 980, idealWidth: isCompact ? 600 : 1_280,
            maxWidth: isCompact ? 600 : .infinity,
            minHeight: isCompact ? 380 : 560, idealHeight: isCompact ? 380 : 740,
            maxHeight: isCompact ? 380 : .infinity
        )
        .modifier(ImportRemovalConfirmationModifier(rowIDs: $removalIDs, isActive: true, confirm: confirmRemoval))
        .onChange(of: selectedKind) {
            guard let selectedFileURL, !isWorking else { return }
            fileSelectionError = nil
            previewCSV(selectedFileURL, selectedKind)
        }
    }

    private var preview: ImportPreview { ImportPreview(candidates: candidates) }
    private var isWorking: Bool { activity != nil && activity != .validatingRows }
    private var isCompact: Bool { selectedFileURL == nil && candidates.isEmpty }

    private func chooseFile() {
        guard !isWorking else { return }
        fileSelectionError = nil
        showsFileImporter = true
    }

    private func selectFile(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            selectedFileURL = url
            fileSelectionError = nil
            previewCSV(url, selectedKind)
        case .failure(let error):
            guard (error as? CocoaError)?.code != .userCancelled else { return }
            fileSelectionError = error.localizedDescription
        }
    }

    private func requestImport() {
        guard activity == nil, preview.readyCount > 0 else { return }
        if preview.rejectedCount > 0 { showsSkipWarning = true }
        else { commitAll() }
    }

    private func close() {
        guard !isWorking else { return }
        cancel()
        dismiss()
    }
}
