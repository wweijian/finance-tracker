import XCTest
@testable import LedgerlyApp

final class TransactionReportIndexTests: XCTestCase {
    func testIndexedRowsMatchInclusiveScanForSingleMonthAndCrossYearRanges() {
        let transactions = ["2024-02-29", "2025-12-30", "2025-12-31", "2026-01-01", "2026-01-02", "2026-02-28"].map(makeRow)
        let index = TransactionReportIndex(transactions: transactions)
        for (start, end) in [("2025-12-31", "2026-01-01"), ("2026-01-01", "2026-01-02"), ("2024-02-01", "2024-02-29"), ("2023-01-01", "2023-12-31")] {
            let expected = transactions.filter { $0.transactionDate >= start && $0.transactionDate <= end }
            XCTAssertEqual(index.rows(from: start, through: end), expected)
        }
    }

    func testQueriesKeepEveryRowInTheMonthWithoutIncludingOtherYears() {
        let transactions = (2000...2026).flatMap { year in
            (1...12).flatMap { month in
                (1...28).map { day in makeRow(String(format: "%04d-%02d-%02d", year, month, day)) }
            }
        }
        let index = TransactionReportIndex(transactions: transactions)
        let rows = index.rows(from: "2026-05-10", through: "2026-05-20")
        XCTAssertEqual(rows.count, 11)
        XCTAssertEqual(rows.first?.transactionDate, "2026-05-10")
        XCTAssertEqual(rows.last?.transactionDate, "2026-05-20")
    }

    private func makeRow(_ date: String) -> TransactionListItem {
        TransactionListItem(id: date, transactionDate: date, transactionType: .expense, amountCents: 100,
                            currency: "SGD", description: "Fixture", category: "Food", notes: nil, deletedAt: nil)
    }
}
