import AppKit
import SwiftUI
import XCTest
@testable import LedgerlyApp

@MainActor
final class ImportTableInteractionTests: XCTestCase {
    func testNativeMultipleSelectionAndSelectAllUpdateBinding() async throws {
        var selection: Set<String> = []
        var checked: Set<String> = ["row-2"]
        let window = host(ImportCandidateTableView(
            candidates: candidates,
            selection: Binding(get: { selection }, set: { selection = $0 }),
            checkedRowIDs: Binding(get: { checked }, set: { checked = $0 }),
            edit: { _ in }, remove: { _ in }
        ))
        defer { window.close() }
        try await settle(window)
        let table = try XCTUnwrap(findTable(in: try XCTUnwrap(window.contentView)))
        XCTAssertTrue(table.allowsMultipleSelection)
        table.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
        try await settle(window)
        XCTAssertEqual(selection, ["row-1"])
        table.selectRowIndexes(IndexSet(integersIn: 1...3), byExtendingSelection: false)
        try await settle(window)
        XCTAssertEqual(selection, ["row-1", "row-2", "row-3"])
        table.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: true)
        try await settle(window)
        XCTAssertEqual(selection, Set(candidates.map(\.id)))
        table.deselectAll(nil)
        try await settle(window)
        XCTAssertTrue(selection.isEmpty)
        table.selectAll(nil)
        try await settle(window)
        XCTAssertEqual(selection, Set(candidates.map(\.id)))
        XCTAssertEqual(checked, ["row-2"])
    }

    func testNativeActionsKeepHighlightAndChecksSeparate() async throws {
        var selection: Set<String> = ["row-1"]
        var checked: Set<String> = ["row-3"]
        var editedIDs: [String] = []
        var imported = false
        let window = host(VStack {
            ImportCandidateTableView(
                candidates: candidates,
                selection: Binding(get: { selection }, set: { selection = $0 }),
                checkedRowIDs: Binding(get: { checked }, set: { checked = $0 }),
                edit: { editedIDs.append($0) }, remove: { _ in }
            )
            Button("Import") { imported = true }.keyboardShortcut("i", modifiers: [.command])
        })
        defer { window.close() }
        try await settle(window)
        let table = try XCTUnwrap(findTable(in: try XCTUnwrap(window.contentView)))
        table.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
        try await settle(window)
        XCTAssertTrue(window.makeFirstResponder(table))
        try key("\u{F701}", code: 125, in: window)
        try await settle(window)
        XCTAssertEqual(selection, ["row-2"])
        try key("\u{F700}", code: 126, in: window)
        try await settle(window)
        XCTAssertEqual(selection, ["row-1"])
        XCTAssertEqual(checked, ["row-3"])
        try performTableAction("highlighted rows", in: window)
        try await settle(window)
        XCTAssertTrue(editedIDs.isEmpty)
        XCTAssertEqual(checked, ["row-1", "row-3"])
        XCTAssertEqual(selection, ["row-1"])
        try performTableAction("Edit transaction", in: window)
        try await settle(window)
        XCTAssertEqual(editedIDs, ["row-1"])
        XCTAssertFalse(imported)
        try key("\u{F701}", code: 125, in: window, modifiers: .shift)
        try await settle(window)
        XCTAssertEqual(selection, ["row-1", "row-2"])
        XCTAssertFalse(try tableMenu(in: window).items.contains { $0.title.hasPrefix("Edit transaction") })
        try await settle(window)
        XCTAssertEqual(editedIDs.count, 1)
        XCTAssertFalse(imported)
        try performTableAction("highlighted rows", in: window)
        try await settle(window)
        XCTAssertEqual(checked, ["row-1", "row-2", "row-3"])
        try performTableAction("highlighted rows", in: window)
        try await settle(window)
        XCTAssertEqual(checked, ["row-3"])
        XCTAssertEqual(selection, ["row-1", "row-2"])
    }

    func testDeleteUsesCheckedRowsRatherThanHighlightedRows() async throws {
        var selection: Set<String> = []
        var checked: Set<String> = ["row-0", "row-3"]
        var removedIDs: Set<String> = []
        let window = host(ImportCandidateTableView(
            candidates: candidates,
            selection: Binding(get: { selection }, set: { selection = $0 }),
            checkedRowIDs: Binding(get: { checked }, set: { checked = $0 }),
            edit: { _ in }, remove: { removedIDs = $0 }
        ))
        defer { window.close() }
        try await settle(window)
        let table = try XCTUnwrap(findTable(in: try XCTUnwrap(window.contentView)))
        table.selectRowIndexes(IndexSet(integersIn: 1...2), byExtendingSelection: false)
        try await settle(window)
        XCTAssertTrue(window.makeFirstResponder(table))
        try performTableAction("Delete checked", in: window)
        try await settle(window)
        XCTAssertEqual(removedIDs, ["row-0", "row-3"])
        XCTAssertEqual(selection, ["row-1", "row-2"])
    }

    func testDeleteDoesNothingForHighlightedUncheckedRows() async throws {
        var selection: Set<String> = []
        var removed = false
        let window = host(ImportCandidateTableView(
            candidates: candidates,
            selection: Binding(get: { selection }, set: { selection = $0 }),
            checkedRowIDs: .constant([]), edit: { _ in }, remove: { _ in removed = true }
        ))
        defer { window.close() }
        try await settle(window)
        let table = try XCTUnwrap(findTable(in: try XCTUnwrap(window.contentView)))
        table.selectRowIndexes(IndexSet(integersIn: 1...2), byExtendingSelection: false)
        try await settle(window)
        XCTAssertTrue(window.makeFirstResponder(table))
        XCTAssertFalse(try tableMenu(in: window).items.contains { $0.title.hasPrefix("Delete checked") })
        try await settle(window)
        XCTAssertFalse(removed)
        XCTAssertEqual(selection, ["row-1", "row-2"])
    }

    func testTableShortcutsLeaveTextEntryOutsideTableAlone() async throws {
        var selection: Set<String> = []
        var text = "abc"
        var edited = false
        var removed = false
        let window = host(VStack {
            ImportCandidateTableView(
                candidates: candidates,
                selection: Binding(get: { selection }, set: { selection = $0 }),
                checkedRowIDs: .constant([]),
                edit: { _ in edited = true }, remove: { _ in removed = true }
            )
            TextField("Outside table", text: Binding(get: { text }, set: { text = $0 }))
        })
        defer { window.close() }
        try await settle(window)
        let content = try XCTUnwrap(window.contentView)
        let table = try XCTUnwrap(findTable(in: content))
        table.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
        let field = try XCTUnwrap(findTextField(in: content))
        XCTAssertTrue(window.makeFirstResponder(field))
        let editor = try XCTUnwrap(field.currentEditor() as? NSTextView)
        editor.setSelectedRange(NSRange(location: 3, length: 0))
        try key(" ", code: 49, in: window)
        try await settle(window)
        XCTAssertEqual(text, "abc ")
        try key("\u{7F}", code: 51, in: window)
        try await settle(window)
        XCTAssertEqual(text, "abc")
        XCTAssertFalse(edited)
        XCTAssertFalse(removed)
    }

    private var candidates: [ImportCandidate] {
        (0..<4).map { row in
            ImportCandidate(id: "row-\(row)", sourceRow: row + 2, transactionDate: "2026-05-08",
                            transactionType: .expense, amount: "4.50", description: "Transaction \(row)",
                            category: "Food", rejectionReason: nil)
        }
    }

    private func host<V: View>(_ view: V) -> NSWindow {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 420),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: view)
        return window
    }

    private func performTableAction(_ title: String, in window: NSWindow) throws {
        let menu = try tableMenu(in: window)
        let index = try XCTUnwrap(menu.items.firstIndex { $0.title.contains(title) })
        menu.performActionForItem(at: index)
    }

    private func tableMenu(in window: NSWindow) throws -> NSMenu {
        let table = try XCTUnwrap(findTable(in: try XCTUnwrap(window.contentView)))
        let row = table.selectedRow >= 0 ? table.selectedRow : 0
        let rect = table.rect(ofRow: row)
        let location = table.convert(NSPoint(x: 200, y: rect.midY), to: nil)
        let event = try XCTUnwrap(NSEvent.mouseEvent(with: .rightMouseDown, location: location, modifierFlags: [], timestamp: 0,
                                                   windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
        return try XCTUnwrap(table.menu(for: event))
    }

    private func findTable(in view: NSView) -> NSTableView? {
        if let table = view as? NSTableView { return table }
        return view.subviews.compactMap { findTable(in: $0) }.first
    }

    private func findTextField(in view: NSView) -> NSTextField? {
        if let field = view as? NSTextField, field.placeholderString == "Outside table" { return field }
        return view.subviews.compactMap { findTextField(in: $0) }.first
    }

    private func key(_ characters: String, code: UInt16, in window: NSWindow,
                     modifiers: NSEvent.ModifierFlags = []) throws {
        let event = try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber, context: nil, characters: characters,
            charactersIgnoringModifiers: characters, isARepeat: false, keyCode: code
        ))
        window.sendEvent(event)
    }

    private func settle(_ window: NSWindow) async throws {
        window.contentView?.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(40))
        window.contentView?.layoutSubtreeIfNeeded()
    }
}
