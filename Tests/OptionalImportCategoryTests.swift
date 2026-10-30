import Foundation
import Testing
@testable import FinanceApp

struct OptionalImportCategoryTests {
    @Test(arguments: [CSVImportKind.debit, .credit, .finance])
    func omittedAndBlankCategoriesNeedAttentionUntilAssigned(kind: CSVImportKind) async throws {
        let store = try SQLiteTestStore()
        let service = BulkImportService(repository: store.repository)
        let categories = try CategoryStore().categories()
        for missing in [true, false] {
            let url = store.directory.appendingPathComponent("\(kind.rawValue)-\(missing).csv")
            let csv = fixture(kind: kind, category: missing ? nil : "   ")
            try csv.write(to: url, atomically: true, encoding: .utf8)
            let preview = try await service.previewFile(at: url, kind: kind, categories: categories)
            #expect(preview.count == 1)
            #expect(preview.first?.category == "")
            #expect(preview.first?.rejectionReason == "Choose a category before importing.")
            #expect(ImportPreview(candidates: preview).rows(matching: .needsAttention).count == 1)
            #expect(ImportPreview(candidates: preview).readyCount == 0)
            let skipped = try await service.commit(preview, categories: categories)
            #expect(skipped.acceptedCount == 0)
            #expect(skipped.rejectedCount == 1)
            #expect(try store.repository.transactions(includeDeleted: false).isEmpty)

            var edited = preview
            edited[0].category = "food"
            let corrected = try await service.validate(edited, categories: categories)
            #expect(corrected.first?.category == "Food")
            #expect(ImportPreview(candidates: corrected).rows(matching: .needsAttention).isEmpty)
            #expect(ImportPreview(candidates: corrected).readyCount == 1)
            let summary = try await service.commit(corrected, categories: categories)
            #expect(summary.acceptedCount == 1)
            let id = try #require(summary.importedTransactionIDs.first)
            #expect(try store.repository.transaction(id: id)?.category == "Food")
            #expect(try String(contentsOf: url, encoding: .utf8) == csv)
            try await service.undo(summary)
        }
    }

    @Test(arguments: [CSVImportKind.debit, .credit, .finance])
    func clearingACategoryAfterPreviewCannotWriteAnUncategorizedTransaction(kind: CSVImportKind) async throws {
        let store = try SQLiteTestStore()
        let service = BulkImportService(repository: store.repository)
        let categories = try CategoryStore().categories()
        let url = store.directory.appendingPathComponent("cleared-category.csv")
        try fixture(kind: kind, category: "Other").write(to: url, atomically: true, encoding: .utf8)
        var preview = try await service.previewFile(at: url, kind: kind, categories: categories)
        #expect(preview.first?.isReady == true)
        #expect(preview.first?.category == "Other")
        preview[0].category = " \t "
        let summary = try await service.commit(preview, categories: categories)
        #expect(summary.acceptedCount == 0)
        #expect(summary.rejectedCount == 1)
        #expect(try store.repository.transactions(includeDeleted: true).isEmpty)
    }

    @Test(arguments: [CSVImportKind.debit, .credit, .finance])
    func explicitCategoriesStillValidateAndDuplicateCategoryHeadersAreRejected(kind: CSVImportKind) async throws {
        let store = try SQLiteTestStore()
        let url = store.directory.appendingPathComponent("categories.csv")
        let service = BulkImportService(repository: store.repository)
        let categories = try CategoryStore().categories()
        try fixture(kind: kind, category: "food").write(to: url, atomically: true, encoding: .utf8)
        let valid = try await service.previewFile(at: url, kind: kind, categories: categories)
        #expect(valid.first?.category == "Food")
        try fixture(kind: kind, category: "Unknown").write(to: url, atomically: true, encoding: .utf8)
        let invalid = try await service.previewFile(at: url, kind: kind, categories: categories)
        #expect(invalid.first?.rejectionReason == "Category is not recognised.")

        let duplicate = fixture(kind: kind, category: "Food").replacingOccurrences(of: "Category", with: "Category,category")
        try duplicate.write(to: url, atomically: true, encoding: .utf8)
        #expect(throws: CSVTransactionParserError.self) { try CSVTransactionParser().parse(url: url, kind: kind) }
    }

    private func fixture(kind: CSVImportKind, category: String?) -> String {
        let headers: [String]
        let row: [String]
        switch kind {
        case .debit:
            headers = ["Transaction Date", "Transaction Code", "Description", "Transaction Ref1", "Transaction Ref2",
                       "Transaction Ref3", "Status", "Debit Amount", "Credit Amount", "Remarks"]
            row = ["08 May 2026", "ICT", "Coffee", "", "", "", "Settled", "4.50", "", "Receipt saved"]
        case .credit:
            headers = ["Transaction Date", "Transaction Posting Date", "Transaction Description", "Transaction Type",
                       "Payment Type", "Transaction Status", "Debit Amount", "Credit Amount", "Notes"]
            row = ["08 May 2026", "09 May 2026", "Coffee", "PURCHASE", "Contactless", "Settled", "4.50", "", "Receipt saved"]
        case .finance:
            headers = ["id", "transaction_date", "transaction_type", "amount", "currency", "description", "notes", "deleted_at"]
            row = ["exported-id", "2026-05-08", "expense", "4.50", "SGD", "Coffee", "Receipt saved", ""]
        }
        let categoryHeader = category == nil ? [] : ["Category"]
        let categoryValue = category.map { [$0] } ?? []
        return (headers + categoryHeader).joined(separator: ",") + "\n" + (row + categoryValue).joined(separator: ",")
    }
}
