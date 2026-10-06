import Foundation
import XCTest
@testable import LedgerlyApp

final class CSVTransactionParserTests: XCTestCase {
    func testParsesDebitFileWithExactHeader() throws {
        let csv = """
        Transaction Date,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount,Category
        08 May 2026,ICT,Coffee shop,,,,Settled,4.50,,Food & Dining
        """
        let result = try parse(csv, kind: .debit)

        XCTAssertEqual(result.candidates.count, 1)
        XCTAssertEqual(result.candidates[0].transactionDate, "2026-05-08")
        XCTAssertEqual(result.candidates[0].transactionType, .expense)
        XCTAssertEqual(result.candidates[0].amount, "4.50")
        XCTAssertEqual(result.candidates[0].category, "Food & Dining")
        XCTAssertEqual(result.candidates[0].remarks, "")
    }

    func testOptionalRemarksColumnCanAppearAnywhereAndPreservesQuotedContent() throws {
        let csv = #"""
        Transaction Date,Remarks,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount,Category
        08 May 2026,"Receipt, ""saved""",ICT,Coffee shop,,,,Settled,4.50,,Food & Dining
        """#
        let result = try parse(csv, kind: .debit)
        XCTAssertEqual(result.candidates.first?.remarks, "Receipt, \"saved\"")
        XCTAssertEqual(result.candidates.first?.description, "Coffee shop")
        XCTAssertEqual(result.candidates.first?.amount, "4.50")
    }

    func testOptionalNotesColumnAlsoWorksForCreditFiles() throws {
        let csv = """
        Transaction Date,Transaction Posting Date,Transaction Description,Transaction Type,Payment Type,Transaction Status,Debit Amount,Credit Amount,Category,Notes
        08 May 2026,09 May 2026,Coffee shop,PURCHASE,Contactless,Settled,4.50,,Food & Dining,Work expense
        """
        XCTAssertEqual(try parse(csv, kind: .credit).candidates.first?.remarks, "Work expense")
    }

    func testDuplicateOptionalRemarksHeadersAreRejectedWithoutCrashing() throws {
        let csv = """
        Transaction Date,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount,Category,Remarks,Remarks
        08 May 2026,ICT,Coffee shop,,,,Settled,4.50,,Food & Dining,First,Second
        """
        XCTAssertThrowsError(try parse(csv, kind: .debit))
    }

    func testRejectsHeaderThatDoesNotMatchSelectedKind() throws {
        let csv = """
        Transaction Date,Transaction Posting Date,Transaction Description,Transaction Type,Payment Type,Transaction Status,Debit Amount,Credit Amount,Category
        08 May 2026,09 May 2026,Coffee shop,PURCHASE,Contactless,Settled,4.50,,Food & Dining
        """

        XCTAssertThrowsError(try parse(csv, kind: .debit))
    }

    func testParsesCreditIncomeWithBOMIntroRowsCRLFAndQuotedDescription() throws {
        let csv = [
            "Bank statement",
            "\u{FEFF}Transaction Date,Transaction Posting Date,Transaction Description,Transaction Type,Payment Type,Transaction Status,Debit Amount,Credit Amount,Category",
            "08 May 2026,09 May 2026,\"Refund, \"\"coffee\"\"\",REFUND,Contactless,Settled,,10.25,Food & Dining"
        ].joined(separator: "\r\n")
        let result = try parse(csv, kind: .credit)
        XCTAssertEqual(result.candidates.count, 1)
        XCTAssertEqual(result.candidates[0].sourceRow, 3)
        XCTAssertEqual(result.candidates[0].description, "Refund, \"coffee\"")
        XCTAssertEqual(result.candidates[0].transactionType, .income)
        XCTAssertEqual(result.candidates[0].amount, "10.25")
    }

    func testParsesUnicodeLineSeparatedFile() throws {
        let separator = "\u{2028}"
        let csv = [
            "Transaction Date,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount,Category",
            "08 May 2026,ICT,Coffee shop,,,,Settled,4.50,,Food & Dining"
        ].joined(separator: separator)

        let result = try parse(csv, kind: .debit)

        XCTAssertEqual(result.candidates.count, 1)
    }

    func testMarksDuplicateRowsInSameFile() async throws {
        let csv = """
        Transaction Date,Transaction Code,Description,Transaction Ref1,Transaction Ref2,Transaction Ref3,Status,Debit Amount,Credit Amount,Category
        08 May 2026,ICT,Coffee shop,,,,Settled,4.50,,Food & Dining
        08 May 2026,ICT,Coffee shop,,,,Settled,4.50,,Food & Dining
        """
        let url = try writeTemporaryCSV(csv)
        defer { try? FileManager.default.removeItem(at: url) }

        let service = BulkImportService(repository: ImportTestRepository())
        let candidates = try await service.previewFile(
            at: url,
            kind: .debit,
            categories: ["Food & Dining"]
        )

        XCTAssertNil(candidates[0].rejectionReason)
        XCTAssertEqual(candidates[1].rejectionReason, "Duplicate of row 2 in this import.")
    }

    private func parse(_ csv: String, kind: CSVImportKind) throws -> CSVImportParseResult {
        let url = try writeTemporaryCSV(csv)
        defer { try? FileManager.default.removeItem(at: url) }

        return try CSVTransactionParser().parse(
            url: url,
            kind: kind
        )
    }

    private func writeTemporaryCSV(_ csv: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
