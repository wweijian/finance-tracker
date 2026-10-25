import AppKit
import SwiftUI
import XCTest
@testable import FinanceApp

@MainActor
final class ImportPreviewLayoutTests: XCTestCase {
    func testPreviewLayoutKeepsTableAndScrollbarVisible() async throws {
        _ = NSApplication.shared
        let store = try SQLiteTestStore()
        let controller = TransactionsController(service: TransactionService(repository: store.repository),
                                                bulkImportService: BulkImportService(repository: store.repository))
        let url = store.directory.appendingPathComponent("sample-transactions.csv")
        try sampleCSV().write(to: url, atomically: true, encoding: .utf8)
        controller.previewCSV(at: url, kind: .debit)
        let deadline = Date().addingTimeInterval(3)
        while controller.isImporting && Date() < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertNil(controller.bulkImportError)

        let hosting = NSHostingView(rootView: ImportPreviewTestView(controller: controller).preferredColorScheme(.light))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1280, height: 740),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .aqua)
        window.contentView = hosting
        defer { window.close() }
        try await settle(hosting)
        let scroll = try XCTUnwrap(findTableScroll(in: hosting))
        let table = try XCTUnwrap(scroll.documentView as? NSTableView)
        XCTAssertGreaterThan(scroll.contentView.bounds.height, 350)
        XCTAssertEqual(scroll.scrollerStyle, .legacy)
        XCTAssertFalse(try XCTUnwrap(scroll.horizontalScroller).isHidden)
        try capture(hosting, name: "import-review-light")

        window.appearance = NSAppearance(named: .darkAqua)
        hosting.rootView = ImportPreviewTestView(controller: controller).preferredColorScheme(.dark)
        try await settle(hosting)
        try capture(hosting, name: "import-review-dark")

        window.setContentSize(NSSize(width: 1040, height: 620))
        try await settle(hosting)
        XCTAssertGreaterThan(scroll.contentView.bounds.height, 250)
        let controls = ImportTableScrollController()
        controls.attach(to: scroll)
        controls.scrollRight()
        try await settle(hosting)
        XCTAssertGreaterThan(scroll.contentView.bounds.minX, 0)
        XCTAssertEqual(try XCTUnwrap(table.headerView?.superview).bounds.minX, scroll.contentView.bounds.minX, accuracy: 1)
        try capture(hosting, name: "import-review-narrow")
    }

    private func sampleCSV() -> String {
        let header = "Transaction Date,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount,Category,Remarks"
        let entries = [
            ("Morning coffee and breakfast", "Food"), ("MRT commute", "Transport"),
            ("Weekly grocery shopping", "Groceries"), ("Needs a category correction", "Unknown"),
            ("Monthly salary", "Income"), ("Electricity bill", "Bills & Utilities"),
            ("New running shoes", "Shopping"), ("Amount needs correction", "Food")
        ]
        let rows = (0..<24).map { index in
            let entry = entries[index % entries.count]
            let cents = entry.1 == "Income" ? 580_000 : entry.1 == "Bills & Utilities" ? 16_850 : 800 + index * 137
            let amount = index == 7 ? "12.999" : String(format: "%d.%02d", cents / 100, cents % 100)
            let debit = entry.1 == "Income" ? "" : amount
            let credit = entry.1 == "Income" ? amount : ""
            let remarks = index.isMultiple(of: 3) ? "Receipt saved for review" : ""
            return String(format: "2026-10-%02d", index + 1) + ",ICT,\(entry.0),,,,Settled,\(debit),\(credit),\(entry.1),\(remarks)"
        }
        return ([header] + rows).joined(separator: "\n")
    }

    private func findTableScroll(in view: NSView) -> NSScrollView? {
        if let scroll = view as? NSScrollView, scroll.documentView is NSTableView { return scroll }
        return view.subviews.compactMap { findTableScroll(in: $0) }.first
    }

    private func settle(_ view: NSView) async throws {
        view.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(150))
        view.layoutSubtreeIfNeeded()
    }

    private func capture(_ view: NSView, name: String) throws {
        let directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent(".build/import-previews", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        let data = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        try data.write(to: directory.appendingPathComponent("\(name).png"))
    }
}
