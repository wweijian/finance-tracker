import XCTest
@testable import LedgerlyApp

final class SpendingTransactionSelectorTests: XCTestCase {
    func testHighestExpenseKeepsFullTransactionAndExcludesIncomeInvestmentsAndDeletedRows() {
        let highest = row("highest", cents: 500, description: "Dinner with family", notes: "Receipt saved\nShared meal")
        let transactions = [row("small", cents: 100), highest,
                            row("salary", cents: 9000, type: .income),
                            row("investment", cents: 8000, category: "Investment"),
                            row("deleted", cents: 7000, deletedAt: "2026-05-12T00:00:00Z"),
                            row("transport", cents: 200, category: "Transport")]
        let result = SpendingTransactionSelector.highestByCategory(in: transactions)
        XCTAssertEqual(result["Food"], highest)
        XCTAssertEqual(result["Food"]?.description, "Dinner with family")
        XCTAssertEqual(result["Food"]?.remarks, "Receipt saved\nShared meal")
        XCTAssertEqual(result["Food"]?.currency, "USD")
        XCTAssertEqual(result["Transport"]?.id, "transport")
        XCTAssertNil(result["Investment"])
    }

    func testTiedAmountsChooseEarliestDateThenStableIDRegardlessOfInputOrder() {
        let earliest = row("a", cents: 500, date: "2026-05-10")
        let transactions = [row("later", cents: 500, date: "2026-05-11"), row("b", cents: 500, date: "2026-05-10"), earliest]
        XCTAssertEqual(SpendingTransactionSelector.highestByCategory(in: transactions)["Food"], earliest)
        XCTAssertEqual(SpendingTransactionSelector.highestByCategory(in: transactions.reversed())["Food"], earliest)
    }

    func testIntervalHighlightUsesOnlyItsOwnTransactions() {
        let transaction = row("meal", cents: 500)
        let interval = ReportInterval(startDate: "2026-05-10", label: "10", totals: .empty, categories: [], transactions: [transaction])
        XCTAssertEqual(interval.highestSpendingTransaction(for: "Food"), transaction)
        XCTAssertNil(interval.highestSpendingTransaction(for: "Transport"))
    }

    private func row(_ id: String, cents: Int, date: String = "2026-05-10", type: TransactionType = .expense,
                     category: String = "Food", description: String = "Meal", notes: String? = nil, deletedAt: String? = nil) -> TransactionListItem {
        TransactionListItem(id: id, transactionDate: date, transactionType: type, amountCents: cents, currency: "USD",
                            description: description, category: category, notes: notes, deletedAt: deletedAt)
    }
}
