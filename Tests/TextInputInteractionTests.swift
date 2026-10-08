import AppKit
import SwiftUI
import XCTest
@testable import LedgerlyApp

@MainActor
final class TextInputInteractionTests: XCTestCase {
    func testImportFieldsPreserveInvalidDateDraftAndAcceptCorrectedDateAndMultilineRemarks() async throws {
        var candidate = ImportCandidate(
            id: "draft", sourceRow: 2, transactionDate: "2026-02-30", transactionType: .expense,
            amount: "4.50", description: "Coffee", category: "Food", rejectionReason: "Date must use YYYY-MM-DD."
        )
        let window = host(ImportCandidateFieldsView(
            candidate: Binding(get: { candidate }, set: { candidate = $0 }), categories: ["Food"]
        ), width: 560, height: 400)
        defer { window.close() }
        try await settle(window)
        let content = try XCTUnwrap(window.contentView)
        let date = try XCTUnwrap(descendants(NSDatePicker.self, in: content).first)
        XCTAssertEqual(candidate.transactionDate, "2026-02-30", "Showing a picker must preserve an invalid imported date until the user corrects it.")
        try await choose("2026-02-28", using: date, window: window)
        XCTAssertEqual(candidate.transactionDate, "2026-02-28")
        let remarks = try XCTUnwrap(descendants(NSTextView.self, in: content).first { !$0.isFieldEditor })
        try click(remarks, in: window)
        remarks.insertText("Receipt saved\nReimbursable", replacementRange: remarks.selectedRange())
        try await settle(window)
        XCTAssertEqual(candidate.remarks, "Receipt saved\nReimbursable")
    }

    func testNativeRemarksInFullTransactionEditorAcceptKeyboardInput() async throws {
        for notes in ["", "Original remarks"] {
            try await typeRemarksInTransactionEditor(initialNotes: notes)
        }
    }

    private func typeRemarksInTransactionEditor(initialNotes: String) async throws {
        let transaction = TransactionFixture.make(notes: initialNotes)
        let form = TransactionForm(transaction: transaction, date: TransactionDateFormatter().date(from: transaction.transactionDate)!)
        let window = host(TransactionEditorView(form: form, categories: [transaction.category], errorMessage: nil,
                                               isMutating: false, save: { _ in }, delete: {}, restore: {}),
                          width: 560, height: 540)
        defer { window.close() }
        try await settle(window)
        let content = try XCTUnwrap(window.contentView)
        let remarks = try XCTUnwrap(descendants(NSTextView.self, in: content).first { !$0.isFieldEditor && $0.string == initialNotes })
        XCTAssertGreaterThan(remarks.visibleRect.height, 40)
        XCTAssertTrue(window.makeFirstResponder(remarks))
        let event = try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
                                                 windowNumber: window.windowNumber, context: nil, characters: "x",
                                                 charactersIgnoringModifiers: "x", isARepeat: false, keyCode: 7))
        window.sendEvent(event)
        try await settle(window)
        XCTAssertTrue(remarks.string.contains("x"))
    }

    private func click(_ remarks: NSTextView, in window: NSWindow) throws {
        let content = try XCTUnwrap(window.contentView)
        let point = remarks.convert(NSPoint(x: remarks.visibleRect.midX, y: remarks.visibleRect.midY), to: content.superview)
        let clickedView = try XCTUnwrap(content.hitTest(point))
        XCTAssertTrue(clickedView === remarks, "Remarks clicks reach \(Swift.type(of: clickedView)) instead of the text editor")
        let location = remarks.convert(NSPoint(x: remarks.visibleRect.midX, y: remarks.visibleRect.midY), to: nil)
        let mouseDown = try XCTUnwrap(NSEvent.mouseEvent(with: .leftMouseDown, location: location, modifierFlags: [], timestamp: 0,
                                                       windowNumber: window.windowNumber, context: nil, eventNumber: 1,
                                                       clickCount: 1, pressure: 1))
        let mouseUp = try XCTUnwrap(NSEvent.mouseEvent(with: .leftMouseUp, location: location, modifierFlags: [], timestamp: 0.01,
                                                     windowNumber: window.windowNumber, context: nil, eventNumber: 2,
                                                     clickCount: 1, pressure: 0))
        NSApplication.shared.postEvent(mouseUp, atStart: true)
        clickedView.mouseDown(with: mouseDown)
    }

    func testNativeDateRangePickerUpdatesFiltersWithoutReplacingTheControl() async throws {
        let store = try SQLiteTestStore()
        try store.repository.save(TransactionFixture.make(id: "before", date: "2026-05-08"))
        try store.repository.save(TransactionFixture.make(id: "after", date: "2026-05-15"))
        let controller = TransactionsController(service: TransactionService(repository: store.repository),
                                                bulkImportService: BulkImportService(repository: store.repository))
        controller.dateFilterMode = .range
        let localFiles = LocalFilesController(service: LocalFileService(repository: store.repository))
        let window = host(TransactionsView(controller: controller, localFilesController: localFiles), width: 1100, height: 680)
        defer { window.close() }
        try await settle(window)
        let content = try XCTUnwrap(window.contentView)
        let picker = try XCTUnwrap(descendants(NSDatePicker.self, in: content).first)
        XCTAssertTrue(controller.startDateText.isEmpty, "An open date bound should stay unset until a date is selected.")
        try await choose("2026-05-10", using: picker, window: window)
        XCTAssertEqual(controller.startDateText, "2026-05-10")
        XCTAssertNil(controller.filterErrorMessage)
        XCTAssertEqual(controller.filteredTransactions.map(\.id), ["after"])
        XCTAssertTrue(descendants(NSDatePicker.self, in: content).first === picker)
    }

    func testRemarksEditorAcceptsMultilineTypingAndUpdatesBinding() async throws {
        var text = "Original remarks"
        let window = host(RemarksEditorView(text: Binding(get: { text }, set: { text = $0 })), width: 500, height: 120)
        defer { window.close() }
        try await settle(window)
        let content = try XCTUnwrap(window.contentView)
        let remarks = try XCTUnwrap(descendants(NSTextView.self, in: content).first { !$0.isFieldEditor && $0.string == "Original remarks" })
        XCTAssertGreaterThan(remarks.visibleRect.height, 40)
        XCTAssertTrue(window.makeFirstResponder(remarks))
        remarks.setSelectedRange(NSRange(location: remarks.string.utf16.count, length: 0))
        remarks.insertText("\nReceipt saved", replacementRange: remarks.selectedRange())
        try await settle(window)
        XCTAssertEqual(text, "Original remarks\nReceipt saved")
    }

    func testNativeReportingDatePickersSetInclusiveRangeBeforeApplyingIt() async throws {
        let store = try SQLiteTestStore()
        for date in ["2026-05-08", "2026-05-15", "2026-05-25"] {
            try store.repository.save(TransactionFixture.make(date: date, cents: 100))
        }
        let now = TransactionDateFormatter().date(from: "2026-06-15")!
        let controller = DashboardController(reportService: DashboardReportService(repository: store.repository), currentDate: { now })
        let window = host(DashboardFilterView(controller: controller), width: 310, height: 320)
        defer { window.close() }
        try await settle(window)
        let content = try XCTUnwrap(window.contentView)
        let pickers = descendants(NSDatePicker.self, in: content)
        XCTAssertEqual(pickers.count, 2)
        try await choose("2026-05-10", using: pickers[0], window: window)
        try await choose("2026-05-20", using: pickers[1], window: window)
        XCTAssertEqual(controller.startDateText, "2026-05-10")
        XCTAssertEqual(controller.endDateText, "2026-05-20")
        XCTAssertFalse(controller.filtersDateRange)
        controller.applyDateRange()
        let deadline = Date().addingTimeInterval(3)
        while controller.isLoading && Date() < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertTrue(controller.filtersDateRange)
        XCTAssertNil(controller.errorMessage)
        XCTAssertEqual(controller.snapshot.expenseCents, 100)
    }

    func testNativeDateSelectionUpdatesBoundDateWithoutChangingItsDay() async throws {
        var date = TransactionDateFormatter().date(from: "2026-05-08")!
        let window = host(DateSelectionView(title: "Date", date: Binding(get: { date }, set: { date = $0 })), width: 500, height: 120)
        defer { window.close() }
        try await settle(window)
        let picker = try XCTUnwrap(descendants(NSDatePicker.self, in: try XCTUnwrap(window.contentView)).first)
        try await choose("2024-02-29", using: picker, window: window)
        XCTAssertEqual(TransactionDateFormatter().string(from: date), "2024-02-29")
    }

    private func choose(_ value: String, using picker: NSDatePicker, window: NSWindow) async throws {
        XCTAssertTrue(picker.isEnabled)
        picker.dateValue = try XCTUnwrap(TransactionDateFormatter().date(from: value))
        XCTAssertTrue(picker.sendAction(picker.action, to: picker.target))
        try await settle(window)
    }

    private func host<V: View>(_ view: V, width: CGFloat, height: CGFloat) -> NSWindow {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: height), styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: view)
        return window
    }

    private func settle(_ window: NSWindow) async throws {
        window.contentView?.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(30))
        window.contentView?.layoutSubtreeIfNeeded()
    }

    private func descendants<T: NSView>(_ type: T.Type, in view: NSView) -> [T] {
        (view as? T).map { [$0] } ?? view.subviews.flatMap { descendants(type, in: $0) }
    }

}
