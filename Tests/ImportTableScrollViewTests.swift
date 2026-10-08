import AppKit
import SwiftUI
import XCTest
@testable import LedgerlyApp

@MainActor
final class ImportTableScrollViewTests: XCTestCase {
    func testImportGoesDirectlyFromPreviewToSuccessAndUndoClosesImport() async throws {
        _ = NSApplication.shared
        let store = try SQLiteTestStore()
        let controller = TransactionsController(service: TransactionService(repository: store.repository),
                                                bulkImportService: BulkImportService(repository: store.repository))
        let url = store.directory.appendingPathComponent("import.csv")
        let csv = "Transaction Date,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount,Category\n08 May 2026,ICT,Coffee,,,,Settled,4.50,,Food"
        try csv.write(to: url, atomically: true, encoding: .utf8)
        controller.presentBulkImport()
        controller.previewCSV(at: url, kind: .debit)
        try await waitForImport(controller)
        let hostingView = NSHostingView(rootView: importView(controller))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1_100, height: 620),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hostingView
        defer { window.close() }
        try await settleLayout(hostingView)
        let scrollView = try XCTUnwrap(findHorizontalScrollView(in: hostingView))
        XCTAssertGreaterThan(scrollView.visibleRect.height, 200)

        controller.commitBulkImport()
        try await waitForImport(controller)
        XCTAssertEqual(controller.bulkImportSummary?.acceptedCount, 1)
        XCTAssertEqual(try store.repository.transactions(includeDeleted: false).count, 1)
        hostingView.rootView = importView(controller)
        try await settleLayout(hostingView)
        XCTAssertNil(findHorizontalScrollView(in: hostingView))

        controller.undoBulkImport()
        try await waitForImport(controller)
        XCTAssertFalse(controller.isShowingBulkImport)
        XCTAssertNil(controller.bulkImportSummary)
        XCTAssertTrue(controller.importCandidates.isEmpty)
        XCTAssertTrue(try store.repository.transactions(includeDeleted: false).isEmpty)
    }

    func testNativeTableScrollingReachesLastColumnsAndSurvivesResize() async throws {
        _ = NSApplication.shared
        let candidate = ImportCandidate(
            id: "preview", sourceRow: 2, transactionDate: "2026-05-08", transactionType: .expense,
            amount: "4.50", description: "Coffee", category: "Food", rejectionReason: nil
        )
        let hostingView = NSHostingView(rootView: ImportCandidateTableView(
            candidates: [candidate], selection: .constant([]), checkedRowIDs: .constant([]), edit: { _ in }, remove: { _ in }
        ))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1_100, height: 400),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hostingView
        defer { window.close() }
        try await settleLayout(hostingView)
        let scrollView = try XCTUnwrap(findHorizontalScrollView(in: hostingView))
        let document = try XCTUnwrap(scrollView.documentView)
        let scroller = try XCTUnwrap(scrollView.horizontalScroller)
        XCTAssertLessThan(scroller.knobProportion, 1)

        scrollView.contentView.scroll(to: NSPoint(x: document.frame.width - scrollView.contentView.bounds.width, y: 0))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        XCTAssertGreaterThan(scrollView.contentView.bounds.minX, 0)
        XCTAssertEqual(scrollView.contentView.bounds.maxX, document.frame.maxX, accuracy: 1)
        XCTAssertEqual(scroller.doubleValue, 1, accuracy: 0.01)

        window.setContentSize(NSSize(width: 1_000, height: 500))
        try await settleLayout(hostingView)
        scrollView.contentView.scroll(to: NSPoint(x: document.frame.width - scrollView.contentView.bounds.width, y: 0))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        XCTAssertEqual(scrollView.contentView.bounds.maxX, document.frame.maxX, accuracy: 1)
    }

    private func findHorizontalScrollView(in view: NSView) -> NSScrollView? {
        if let scrollView = view as? NSScrollView,
           scrollView.documentView is NSTableView, scrollView.hasHorizontalScroller { return scrollView }
        return view.subviews.compactMap { findHorizontalScrollView(in: $0) }.first
    }

    private func importView(_ controller: TransactionsController) -> BulkImportView {
        BulkImportView(preview: controller.importPreview, summary: controller.bulkImportSummary,
                       errorMessage: controller.bulkImportError,
                       activity: controller.importActivity, previewCSV: controller.previewCSV,
                       removedRowCount: controller.removedImportRowCount, removeRows: controller.requestImportRowRemoval,
                       undoRowRemovals: controller.undoImportRowRemovals,
                       commitAll: controller.commitBulkImport, undo: controller.undoBulkImport,
                       cancel: controller.cancelBulkImport,
                       editingCandidate: Binding(get: { controller.importEditorCandidate }, set: { controller.importEditorCandidate = $0 }),
                       categories: controller.categories, editorError: controller.importEditorError,
                       editCandidate: controller.editImportCandidate, saveCandidate: controller.saveImportCandidate,
                       removalIDs: Binding(get: { controller.importRowRemovalIDs }, set: { controller.importRowRemovalIDs = $0 }),
                       confirmRemoval: controller.confirmImportRowRemoval)
    }

    private func waitForImport(_ controller: TransactionsController) async throws {
        let deadline = Date().addingTimeInterval(3)
        while controller.isImporting && Date() < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertFalse(controller.isImporting)
        XCTAssertNil(controller.bulkImportError)
    }

    private func settleLayout(_ view: NSView) async throws {
        view.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(50))
        view.layoutSubtreeIfNeeded()
    }
}
