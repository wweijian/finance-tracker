import SwiftUI
import UniformTypeIdentifiers

struct BulkImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsFileImporter = false
    @State private var selectedKind: CSVImportKind = .debit
    @State private var selectedFileURL: URL?
    @State private var fileSelectionError: String?
    @State private var editingCandidate: ImportCandidate?
    @State private var showsSkipWarning = false

    let preview: ImportPreview
    let categories: [String]
    let summary: BulkImportSummary?
    let errorMessage: String?
    let activity: ImportActivity?
    let previewCSV: (URL, CSVImportKind) -> Void
    let revalidate: (ImportCandidate) -> Void
    let removedRowCount: Int
    let removeRows: (Set<String>) -> Void
    let undoRowRemovals: () -> Void
    let commitAll: () -> Void
    let undo: () -> Void
    let cancel: () -> Void

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
        .interactiveDismissDisabled(activity != nil)
        .onExitCommand { if activity == nil { close() } }
        .fileImporter(isPresented: $showsFileImporter, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            selectFile(result)
        }
        .sheet(item: $editingCandidate) { candidate in
            ImportCandidateEditorView(candidate: candidate, categories: categories, save: revalidate)
        }
        .alert("Import without rejected rows?", isPresented: $showsSkipWarning) {
            Button("Cancel", role: .cancel) {}
            Button("Skip rows and import", role: .destructive, action: commitAll)
        } message: {
            Text("\(preview.rejectedCount) rows still need attention. Ledgerly will import \(preview.readyCount) ready transactions and skip the rejected rows. The CSV file stays unchanged.")
        }
    }

    private var importSheet: some View {
        VStack(spacing: 0) {
            ImportSourceBarView(
                filename: selectedFileURL?.lastPathComponent,
                kind: $selectedKind,
                isWorking: activity != nil,
                chooseFile: chooseFile
            )
            Divider()
            ImportContentView(
                preview: preview,
                filename: selectedFileURL?.lastPathComponent,
                activity: activity,
                errorMessage: fileSelectionError ?? errorMessage,
                chooseFile: chooseFile,
                edit: edit,
                removedRowCount: removedRowCount,
                remove: removeRows,
                undoRemovals: undoRowRemovals
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
        .frame(width: isCompact ? 600 : 1_100, height: isCompact ? 380 : 620)
        .onChange(of: selectedKind) {
            guard let selectedFileURL, activity == nil else { return }
            fileSelectionError = nil
            previewCSV(selectedFileURL, selectedKind)
        }
    }

    private var isCompact: Bool { selectedFileURL == nil && preview.candidates.isEmpty }

    private func chooseFile() {
        guard activity == nil else { return }
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

    private func edit(_ candidate: ImportCandidate) {
        guard activity == nil else { return }
        editingCandidate = candidate
    }

    private func requestImport() {
        guard activity == nil, preview.readyCount > 0 else { return }
        if preview.rejectedCount > 0 { showsSkipWarning = true }
        else { commitAll() }
    }

    private func close() {
        guard activity == nil else { return }
        cancel()
        dismiss()
    }
}
