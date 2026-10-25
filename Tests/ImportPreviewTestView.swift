import SwiftUI
@testable import FinanceApp

struct ImportPreviewTestView: View {
    @ObservedObject var controller: TransactionsController

    var body: some View {
        BulkImportView(
            candidates: Binding(get: { controller.importCandidates }, set: { controller.updateImportCandidates($0) }),
            summary: controller.bulkImportSummary, errorMessage: controller.bulkImportError,
            activity: controller.importActivity, previewCSV: controller.previewCSV,
            removedRowCount: controller.removedImportRowCount, removeRows: controller.requestImportRowRemoval,
            undoRowRemovals: controller.undoImportRowRemovals, commitAll: controller.commitBulkImport,
            undo: controller.undoBulkImport, cancel: controller.cancelBulkImport,
            categories: controller.categories,
            removalIDs: Binding(get: { controller.importRowRemovalIDs }, set: { controller.importRowRemovalIDs = $0 }),
            confirmRemoval: controller.confirmImportRowRemoval
        )
    }
}
