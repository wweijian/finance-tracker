import AppKit
import SwiftUI
import XCTest
@testable import FinanceApp

@MainActor
final class ImportInlineEditingTests: XCTestCase {
    func testFieldsAreEditableImmediatelyAndChangesApplyAutomatically() async throws {
        let store = try SQLiteTestStore()
        let controller = TransactionsController(service: TransactionService(repository: store.repository),
                                                bulkImportService: BulkImportService(repository: store.repository))
        let url = store.directory.appendingPathComponent("direct.csv")
        let csv = "Transaction Date,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount\n2026-02-30,ICT,Coffee,,,,Settled,4.50,\n2026-02-28,ICT,Dinner,,,,Settled,8.00,"
        try csv.write(to: url, atomically: true, encoding: .utf8)
        controller.previewCSV(at: url, kind: .debit)
        try await waitForValidation(controller)
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1500, height: 620),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ImportPreviewTestView(controller: controller))
        defer { window.close() }
        try await settle(window)
        let content = try XCTUnwrap(window.contentView)
        let table = try XCTUnwrap(descendants(NSTableView.self, in: content).first)
        let fields = descendants(NSTextField.self, in: table).filter(\.isEditable)
        let date = try XCTUnwrap(fields.first { $0.stringValue == "2026-02-30" },
                                "Editable fields: \(fields.map(\.stringValue)); preview dates: \(controller.importCandidates.map(\.transactionDate))")
        XCTAssertEqual(controller.importCandidates.first?.transactionDate, "2026-02-30")
        XCTAssertNotNil(fields.first { $0.stringValue == "Dinner" }, "Every row is editable without selecting it.")
        try await replaceText(in: date, with: "2026-02-28", window: window)
        let description = try XCTUnwrap(fields.first { $0.stringValue == "Coffee" })
        try await replaceText(in: description, with: "L", window: window)
        try await replaceText(in: description, with: "Lu", window: window)
        try await replaceText(in: description, with: "Lunch", window: window)
        let remarks = try XCTUnwrap(fields.first { $0.stringValue.isEmpty })
        try await replaceText(in: remarks, with: "Receipt saved\nReimbursable", window: window)
        try await waitForValidation(controller)
        try await settle(window)
        XCTAssertTrue(remarks.isEnabled)
        XCTAssertTrue(remarks.currentEditor() === window.firstResponder)
        XCTAssertEqual(controller.importCandidates.first?.transactionDate, "2026-02-28")
        XCTAssertEqual(controller.importCandidates.first?.description, "Lunch")
        XCTAssertEqual(controller.importCandidates.first?.remarks, "Receipt saved\nReimbursable")
        XCTAssertEqual(controller.importCandidates.first?.category, "Other")
        XCTAssertTrue(controller.importCandidates.allSatisfy(\.isReady))
        XCTAssertNil(window.attachedSheet)
        XCTAssertTrue(try store.repository.transactions(includeDeleted: true).isEmpty)
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), csv)

        controller.commitBulkImport()
        try await waitForValidation(controller)
        XCTAssertEqual(controller.bulkImportSummary?.acceptedCount, 2)
        let saved = try XCTUnwrap(store.repository.transactions(includeDeleted: false).first { $0.description == "Lunch" })
        XCTAssertEqual(saved.remarks, "Receipt saved\nReimbursable")
    }

    private func waitForValidation(_ controller: TransactionsController) async throws {
        let deadline = Date().addingTimeInterval(3)
        while controller.isImporting && Date() < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertFalse(controller.isImporting)
        XCTAssertNil(controller.bulkImportError)
    }

    private func replaceText(in field: NSTextField, with value: String, window: NSWindow) async throws {
        field.scrollToVisible(field.bounds)
        XCTAssertGreaterThan(field.visibleRect.height, 10)
        XCTAssertTrue(window.makeFirstResponder(field))
        let editor = try XCTUnwrap(field.currentEditor() as? NSTextView)
        editor.setSelectedRange(NSRange(location: 0, length: editor.string.utf16.count))
        editor.insertText(value, replacementRange: editor.selectedRange())
        try await settle(window)
    }

    private func settle(_ window: NSWindow) async throws {
        window.contentView?.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(50))
        window.contentView?.layoutSubtreeIfNeeded()
    }

    private func descendants<T: NSView>(_ type: T.Type, in view: NSView) -> [T] {
        (view as? T).map { [$0] } ?? view.subviews.flatMap { descendants(type, in: $0) }
    }
}
