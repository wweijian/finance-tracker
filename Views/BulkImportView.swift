import SwiftUI
import UniformTypeIdentifiers

struct BulkImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsFileImporter = false
    @State private var selectedKind: CSVImportKind = .debit
    @State private var selectedFileURL: URL?
    @State private var fileSelectionError: String?
    @State private var showsSkipWarning = false

    let preview: ImportPreview
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
    @Binding var editingCandidate: ImportCandidate?
    let categories: [String]
    let editorError: String?
    let editCandidate: (String) -> Void
    let saveCandidate: (ImportCandidate) -> Void
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
        .interactiveDismissDisabled(activity != nil)
        .onExitCommand { if activity == nil && editingCandidate == nil { close() } }
        .sheet(item: $editingCandidate) { candidate in
            ImportCandidateEditorView(
                candidate: candidate,
                categories: categories,
                errorMessage: editorError,
                isWorking: activity != nil,
                save: saveCandidate,
                remove: { removeRows([candidate.id]) }
            )
            .modifier(ImportRemovalConfirmationModifier(rowIDs: $removalIDs, isActive: true, confirm: confirmRemoval))
        }
        .fileImporter(isPresented: $showsFileImporter, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            selectFile(result)
        }
        .alert("Import without rejected rows?", isPresented: $showsSkipWarning) {
            Button("Cancel", role: .cancel) {}
            Button("Skip rows and import", action: commitAll)
        } message: {
            Text("Ledgerly will import \(preview.readyCount) ready transactions and skip \(preview.rejectedCount) rejected rows. The CSV file stays unchanged.")
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
                removedRowCount: removedRowCount,
                remove: removeRows,
                undoRemovals: undoRowRemovals,
                edit: editCandidate
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
        .modifier(ImportRemovalConfirmationModifier(rowIDs: $removalIDs, isActive: editingCandidate == nil, confirm: confirmRemoval))
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
