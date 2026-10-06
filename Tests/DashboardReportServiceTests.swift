import Foundation
import XCTest
@testable import LedgerlyApp

final class DashboardReportServiceTests: XCTestCase {
    func testKnownMonthlyAnnualAndCategoryTotalsAndComparisons() async throws {
        let store = try SQLiteTestStore()
        let fixtures: [FinanceTransaction] = [
            TransactionFixture.make(id: "dec-income", date: "2025-12-31", type: .income, cents: 80000),
            TransactionFixture.make(id: "dec-food", date: "2025-12-15", cents: 10000),
            TransactionFixture.make(id: "prior-income", date: "2025-01-15", type: .income, cents: 50000),
            TransactionFixture.make(id: "prior-food", date: "2025-01-15", cents: 10000),
            TransactionFixture.make(id: "jan-income", date: "2026-01-15", type: .income, cents: 100000),
            TransactionFixture.make(id: "jan-food", date: "2026-01-15", cents: 20000),
            TransactionFixture.make(id: "feb-income", date: "2026-02-15", type: .income, cents: 150000),
            TransactionFixture.make(id: "feb-food", date: "2026-02-15", cents: 10000),
            TransactionFixture.make(id: "feb-transport", date: "2026-02-15", cents: 5000, category: "Transport"),
            TransactionFixture.make(id: "deleted", date: "2026-02-15", cents: 999999, deletedAt: "2026-03-01T00:00:00Z")
        ]
        for transaction in fixtures { try store.repository.save(transaction) }
        let service = DashboardReportService(repository: store.repository)
        let report = try await service.dashboard(for: DashboardPeriod(year: 2026))
        XCTAssertEqual(report.totals, ReportTotals(incomeCents: 250000, expenseCents: 35000, transactionCount: 5))
        XCTAssertEqual(report.netCents, 215000)
        XCTAssertEqual(report.yearOverYear.income.previousCents, 130000)
        XCTAssertEqual(report.yearOverYear.expenses.previousCents, 20000)
        XCTAssertEqual(report.yearOverYear.net.differenceCents, 105000)
        XCTAssertEqual(report.months.count, 12)
        XCTAssertEqual(report.availableYears, [2026, 2025])
        XCTAssertEqual(report.categoryTotals.first?.amountCents, 30000)
        XCTAssertEqual(report.categoryTotals.first?.yearOverYear.percentage, 50)
        let january = try XCTUnwrap(report.months.first)
        XCTAssertEqual(january.monthOverMonth.income.percentage, 25)
        XCTAssertEqual(january.monthOverMonth.expenses.percentage, 100)
        XCTAssertEqual(january.yearOverYear.income.percentage, 100)
        XCTAssertEqual(january.yearOverYear.net.percentage, 100)
        let february = report.months[1]
        XCTAssertEqual(february.monthOverMonth.income.percentage, 50)
        XCTAssertEqual(february.monthOverMonth.expenses.percentage, -25)
        XCTAssertEqual(february.monthOverMonth.net.percentage, Decimal(string: "68.75"))
        XCTAssertEqual(february.categories.first { $0.category == "Food & Dining" }?.monthOverMonth.percentage, -50)
        XCTAssertNil(february.categories.first { $0.category == "Transport" }?.monthOverMonth.percentage)
        XCTAssertEqual(february.categories.first { $0.category == "Transport" }?.monthOverMonth.description, "From zero")
        XCTAssertEqual(report.months[2].totals, .empty)
    }

    func testPartialRangeUsesMatchingDaysAndInclusiveBounds() async throws {
        let store = try SQLiteTestStore()
        for (id, date, cents) in [
            ("start", "2026-03-10", 100), ("end", "2026-03-20", 200),
            ("outside", "2026-03-21", 10000), ("before", "2026-03-09", 10000),
            ("previous", "2026-02-10", 100), ("prev-outside", "2026-02-21", 10000),
            ("prior-year", "2025-03-20", 150), ("prior-outside", "2025-03-21", 10000)
        ] { try store.repository.save(TransactionFixture.make(id: id, date: date, cents: cents)) }
        let report = try await DashboardReportService(repository: store.repository).dashboard(
            for: DashboardPeriod(year: 2026, startDate: "2026-03-10", endDate: "2026-03-20")
        )
        XCTAssertEqual(report.transactionCount, 2)
        XCTAssertEqual(report.expenseCents, 300)
        XCTAssertEqual(report.yearOverYear.expenses.percentage, 100)
        XCTAssertEqual(report.months.count, 1)
        XCTAssertEqual(report.months[0].monthOverMonth.expenses.percentage, 200)
    }

    func testFullFebruaryIncludesJanuary31AndLeapYearComparison() async throws {
        let store = try SQLiteTestStore()
        for (date, cents) in [("2025-01-31", 200), ("2025-02-28", 400), ("2024-02-29", 100)] {
            try store.repository.save(TransactionFixture.make(date: date, cents: cents))
        }
        let report = try await DashboardReportService(repository: store.repository).dashboard(for: DashboardPeriod(year: 2025))
        XCTAssertEqual(report.months[1].monthOverMonth.expenses.percentage, 100)
        XCTAssertEqual(report.months[1].yearOverYear.expenses.percentage, 300)
    }

    func testPartialLeapDayClampsToPriorYearFebruary28() async throws {
        let store = try SQLiteTestStore()
        try store.repository.save(TransactionFixture.make(date: "2024-02-29", cents: 200))
        try store.repository.save(TransactionFixture.make(date: "2023-02-28", cents: 100))
        let report = try await DashboardReportService(repository: store.repository).dashboard(
            for: DashboardPeriod(year: 2024, startDate: "2024-02-29", endDate: "2024-02-29")
        )
        XCTAssertEqual(report.yearOverYear.expenses.percentage, 100)
    }

    func testWholeMonthRangeUsesLeapDayInBothSummaryAndMonthlyComparison() async throws {
        let store = try SQLiteTestStore()
        for (date, cents) in [("2025-02-28", 400), ("2024-02-29", 100), ("2024-03-01", 9999)] {
            try store.repository.save(TransactionFixture.make(date: date, cents: cents))
        }
        let report = try await DashboardReportService(repository: store.repository).dashboard(
            for: DashboardPeriod(year: 2025, startDate: "2025-02-01", endDate: "2025-02-28")
        )
        XCTAssertEqual(report.yearOverYear.expenses.percentage, 300)
        XCTAssertEqual(report.months[0].yearOverYear.expenses.percentage, 300)
    }

    func testMissingZeroAndNegativeBaselines() {
        XCTAssertEqual(FinancialChange(currentCents: 100, previousCents: nil).description, "No prior data")
        XCTAssertNil(FinancialChange(currentCents: 100, previousCents: 0).percentage)
        XCTAssertEqual(FinancialChange(currentCents: 0, previousCents: 0).description, "No change")
        XCTAssertEqual(FinancialChange(currentCents: -50, previousCents: -100).percentage, 50)
        XCTAssertEqual(FinancialChange(currentCents: 100, previousCents: -100).percentage, 200)
        XCTAssertEqual(FinancialChange(currentCents: 0, previousCents: 100).percentage, -100)
    }

    func testEmptyAndIncomeOnlyPeriods() async throws {
        let store = try SQLiteTestStore()
        let service = DashboardReportService(repository: store.repository)
        let empty = try await service.dashboard(for: DashboardPeriod(year: 2026))
        XCTAssertEqual(empty.totals, .empty)
        XCTAssertTrue(empty.categoryTotals.isEmpty)
        XCTAssertEqual(empty.months.count, 12)
        try store.repository.save(TransactionFixture.make(type: .income, cents: 12345))
        let income = try await service.dashboard(for: DashboardPeriod(year: 2026))
        XCTAssertEqual(income.netCents, 12345)
        XCTAssertTrue(income.categoryTotals.isEmpty)
        XCTAssertNil(income.yearOverYear.income.percentage)
    }

    func testInvalidRangesAreRejected() throws {
        XCTAssertThrowsError(try DashboardPeriod(year: 2026, startDate: "2026-05-20", endDate: "2026-05-10"))
        XCTAssertThrowsError(try DashboardPeriod(year: 2026, startDate: "2025-12-31"))
        XCTAssertThrowsError(try DashboardPeriod(year: 2026, endDate: "2026-02-30"))
        XCTAssertThrowsError(try DashboardPeriod(year: 0))
    }
}
