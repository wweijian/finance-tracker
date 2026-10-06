import XCTest
@testable import LedgerlyApp

final class TransactionValidationTests: XCTestCase {
    func testAmountsRejectTrailingTextExcessPrecisionNegativeAndOverflow() {
        let formatter = CurrencyAmountFormatter()
        for value in ["1.00oops", "1.001", "-1", "NaN", "", "9999999999999999999999999999"] {
            XCTAssertNil(formatter.cents(from: value), value)
        }
        XCTAssertEqual(formatter.cents(from: "1234.56"), 123456)
        XCTAssertEqual(formatter.cents(from: ".50"), 50)
        XCTAssertEqual(formatter.cents(from: "0"), 0)
        XCTAssertEqual(formatter.inputString(for: 123456), "1234.56")
        XCTAssertEqual(formatter.cents(from: formatter.inputString(for: 123456)), 123456)
    }

    func testDatesRejectImpossibleAndNonCanonicalDates() {
        let formatter = TransactionDateFormatter()
        for value in ["2026-02-30", "2025-02-29", "2026-5-8", "2026-05-08oops"] {
            XCTAssertNil(formatter.date(from: value), value)
        }
        XCTAssertNotNil(formatter.date(from: "2024-02-29"))
    }
}
