import Foundation
import XCTest
@testable import LedgerlyApp

@MainActor
final class DashboardControllerTests: XCTestCase {
    func testDefaultMonthIsPreviousCalendarMonthIncludingJanuaryRollover() throws {
        let store = try SQLiteTestStore()
        let service = DashboardReportService(repository: store.repository)
        let january = TransactionDateFormatter().date(from: "2026-01-15")!
        let controller = DashboardController(reportService: service, currentDate: { january })
        XCTAssertEqual(controller.selectedYear, 2025)
        XCTAssertEqual(controller.comparisonMonth, 12)
        let october = TransactionDateFormatter().date(from: "2026-10-07")!
        let autumn = DashboardController(reportService: service, currentDate: { october })
        XCTAssertEqual(autumn.selectedYear, 2026)
        XCTAssertEqual(autumn.comparisonMonth, 9)
    }

    func testFutureYearNavigationIsBlockedEvenWithFutureTransactions() async throws {
        let store = try SQLiteTestStore()
        try store.repository.save(TransactionFixture.make(date: "2027-01-01"))
        let now = TransactionDateFormatter().date(from: "2026-10-07")!
        let controller = DashboardController(reportService: DashboardReportService(repository: store.repository), currentDate: { now })
        controller.load()
        try await waitForLoad(controller)
        XCTAssertFalse(controller.availableYears.contains(2027))
        controller.showNextYear()
        XCTAssertEqual(controller.selectedYear, 2026)
        controller.selectYear(2028)
        XCTAssertEqual(controller.selectedYear, 2026)
    }

    func testReopeningMonthlySpendingResetsMonthYearAndDateFilter() async throws {
        let store = try SQLiteTestStore()
        let now = TransactionDateFormatter().date(from: "2026-01-15")!
        let controller = DashboardController(reportService: DashboardReportService(repository: store.repository), selectedYear: 2026, currentDate: { now })
        controller.comparisonMonth = 5
        controller.filtersDateRange = true
        controller.showPreviousMonth()
        try await waitForLoad(controller)
        XCTAssertEqual(controller.selectedYear, 2025)
        XCTAssertEqual(controller.comparisonMonth, 12)
        XCTAssertEqual(controller.comparisonReport?.startDate, "2025-12-01")
        XCTAssertFalse(controller.filtersDateRange)
    }

    func testTypedReportingRangeAppliesInclusiveDatesAndRejectsInvalidInput() async throws {
        let store = try SQLiteTestStore()
        for (id, date) in [("before", "2026-05-09"), ("start", "2026-05-10"), ("end", "2026-05-20"), ("after", "2026-05-21")] {
            try store.repository.save(TransactionFixture.make(id: id, date: date, cents: 100))
        }
        let now = TransactionDateFormatter().date(from: "2026-06-15")!
        let controller = DashboardController(reportService: DashboardReportService(repository: store.repository), currentDate: { now })
        controller.startDateText = "2026-05-10"
        controller.endDateText = "2026-05-20"
        controller.applyDateRange()
        try await waitForLoad(controller)
        XCTAssertEqual(controller.snapshot.transactionCount, 2)
        XCTAssertEqual(controller.snapshot.expenseCents, 200)
        XCTAssertTrue(controller.filtersDateRange)
        XCTAssertEqual(controller.periodLabel, "2026-05-10 – 2026-05-20")
        controller.startDateText = "2026-02-30"
        XCTAssertEqual(controller.periodLabel, "2026-05-10 – 2026-05-20")
        controller.applyDateRange()
        XCTAssertNotNil(controller.errorMessage)
        XCTAssertFalse(controller.isLoading)
        controller.startDateText = "2026-05-20"
        controller.endDateText = "2026-05-10"
        controller.applyDateRange()
        XCTAssertNotNil(controller.errorMessage)
    }

    private func waitForLoad(_ controller: DashboardController) async throws {
        let deadline = Date().addingTimeInterval(3)
        while controller.isLoading && Date() < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertFalse(controller.isLoading)
        XCTAssertNil(controller.errorMessage)
    }

    func testMonthArrowsCrossYearsAndStopAtCurrentMonth() async throws {
        let store = try SQLiteTestStore()
        let now = TransactionDateFormatter().date(from: "2026-01-15")!
        let controller = DashboardController(reportService: DashboardReportService(repository: store.repository), currentDate: { now })
        controller.navigateNextPeriod()
        try await waitForLoad(controller)
        XCTAssertEqual(controller.selectedYear, 2026)
        XCTAssertEqual(controller.comparisonMonth, 1)
        XCTAssertEqual(controller.periodLabel, "\(Calendar.current.monthSymbols[0]) 2026")
        XCTAssertEqual(controller.intervals.count, 31)
        XCTAssertFalse(controller.canShowNextPeriod)
        controller.navigateNextPeriod()
        XCTAssertEqual(controller.comparisonMonth, 1)
        controller.navigatePreviousPeriod()
        try await waitForLoad(controller)
        XCTAssertEqual(controller.selectedYear, 2025)
        XCTAssertEqual(controller.comparisonMonth, 12)
        XCTAssertEqual(controller.intervals.last?.startDate, "2025-12-31")
    }

    func testScopeToggleChangesTotalsAndGroupingWithoutResettingSelectedMonth() async throws {
        let store = try SQLiteTestStore()
        try store.repository.save(TransactionFixture.make(date: "2026-04-15", cents: 100))
        try store.repository.save(TransactionFixture.make(date: "2026-05-15", cents: 200))
        let now = TransactionDateFormatter().date(from: "2026-06-15")!
        let controller = DashboardController(reportService: DashboardReportService(repository: store.repository), currentDate: { now })
        controller.load()
        try await waitForLoad(controller)
        XCTAssertEqual(controller.snapshot.expenseCents, 200)
        XCTAssertEqual(controller.intervals.count, 31)
        XCTAssertEqual(controller.intervals.flatMap(\.transactions).count, 1)
        controller.toggleScope()
        try await waitForLoad(controller)
        XCTAssertEqual(controller.scope, .yearly)
        XCTAssertEqual(controller.snapshot.expenseCents, 300)
        XCTAssertEqual(controller.intervals.count, 12)
        XCTAssertEqual(controller.intervals[3].transactions.count, 1)
        XCTAssertEqual(controller.intervals[4].transactions.count, 1)
        controller.toggleScope()
        try await waitForLoad(controller)
        XCTAssertEqual(controller.comparisonMonth, 5)
        XCTAssertEqual(controller.snapshot.expenseCents, 200)
    }

    func testCategoryBreakdownIncludesPreviousMonthOnlyCategories() async throws {
        let store = try SQLiteTestStore()
        for transaction in [
            TransactionFixture.make(id: "prior-food", date: "2026-04-15", cents: 100, category: "Food"),
            TransactionFixture.make(id: "prior-groceries", date: "2026-04-15", cents: 300, category: "Groceries"),
            TransactionFixture.make(id: "food", date: "2026-05-15", cents: 200, category: "Food"),
            TransactionFixture.make(id: "investment", date: "2026-05-15", cents: 900, category: "Investment"),
            TransactionFixture.make(id: "salary", date: "2026-05-15", type: .income, cents: 1000, category: "Income"),
            TransactionFixture.make(id: "deleted", date: "2026-05-15", cents: 999, deletedAt: "2026-05-16T00:00:00Z")
        ] { try store.repository.save(transaction) }
        let now = TransactionDateFormatter().date(from: "2026-06-15")!
        let controller = DashboardController(reportService: DashboardReportService(repository: store.repository), currentDate: { now })
        controller.load()
        try await waitForLoad(controller)
        XCTAssertEqual(controller.selectedPage, .spending)
        XCTAssertEqual(DashboardPage.allCases.first, .spending)
        XCTAssertEqual(controller.categoryComparisons.map(\.category), ["Groceries", "Food"])
        XCTAssertEqual(controller.categoryComparisons[0].amountCents, 0)
        XCTAssertEqual(controller.categoryComparisons[0].change.percentage, -100)
        XCTAssertEqual(controller.categoryComparisons[1].amountCents, 200)
        XCTAssertEqual(controller.categoryComparisons[1].change.percentage, 100)
    }

    func testCategoryComparisonAcrossJanuaryAndYearScopeUsesCorrectBaseline() async throws {
        let store = try SQLiteTestStore()
        try store.repository.save(TransactionFixture.make(date: "2025-12-15", cents: 100, category: "Food"))
        try store.repository.save(TransactionFixture.make(date: "2026-01-15", cents: 200, category: "Food"))
        let now = TransactionDateFormatter().date(from: "2026-02-15")!
        let controller = DashboardController(reportService: DashboardReportService(repository: store.repository), currentDate: { now })
        controller.load()
        try await waitForLoad(controller)
        XCTAssertEqual(controller.categoryComparisons.first?.change.previousCents, 100)
        controller.selectScope(.yearly)
        try await waitForLoad(controller)
        XCTAssertEqual(controller.categoryComparisons.first?.change.percentage, 100)
        controller.selectScope(.yearly)
        XCTAssertFalse(controller.isLoading, "Selecting the active segment should not reload reports.")
    }

    func testNavigationReusesPreparedChartArrays() async throws {
        let store = try SQLiteTestStore()
        try store.repository.save(TransactionFixture.make(date: "2026-05-15", category: "Food"))
        let now = TransactionDateFormatter().date(from: "2026-06-15")!
        let controller = DashboardController(reportService: DashboardReportService(repository: store.repository), currentDate: { now })
        controller.selectScope(.yearly)
        try await waitForLoad(controller)
        let initialIntervals = controller.intervals
        let initialPeaks = controller.peakMonths
        for page in DashboardPage.allCases {
            controller.selectedPage = page
            initialIntervals.withUnsafeBufferPointer { initial in
                controller.intervals.withUnsafeBufferPointer { current in
                    XCTAssertEqual(initial.baseAddress, current.baseAddress)
                }
            }
            initialPeaks.withUnsafeBufferPointer { initial in
                controller.peakMonths.withUnsafeBufferPointer { current in
                    XCTAssertEqual(initial.baseAddress, current.baseAddress)
                }
            }
        }
        XCTAssertFalse(controller.isLoading)
    }

    func testHoverHighlightsRespectMonthAndYearSelectionAndKeepFullDetails() async throws {
        let store = try SQLiteTestStore()
        let dinner = TransactionFixture.make(id: "dinner", date: "2026-05-11", cents: 500, category: "Food", description: "Dinner with friends", notes: "Receipt saved")
        for transaction in [dinner,
                            TransactionFixture.make(id: "coffee", date: "2026-05-11", cents: 100, category: "Food"),
                            TransactionFixture.make(id: "holiday", date: "2026-06-01", cents: 9999, category: "Food")] {
            try store.repository.save(transaction)
        }
        let now = TransactionDateFormatter().date(from: "2026-06-15")!
        let controller = DashboardController(reportService: DashboardReportService(repository: store.repository), currentDate: { now })
        controller.load()
        try await waitForLoad(controller)
        let day = try XCTUnwrap(controller.intervals.first { $0.startDate == "2026-05-11" })
        XCTAssertEqual(day.highestSpendingTransaction(for: "Food")?.id, "dinner")
        XCTAssertEqual(day.highestSpendingTransaction(for: "Food")?.description, "Dinner with friends")
        XCTAssertEqual(day.highestSpendingTransaction(for: "Food")?.remarks, "Receipt saved")
        XCTAssertEqual(controller.highestCategoryTransactions["Food"]?.id, "dinner")
        controller.selectScope(.yearly)
        try await waitForLoad(controller)
        XCTAssertEqual(controller.intervals[4].highestSpendingTransaction(for: "Food")?.id, "dinner")
        XCTAssertEqual(controller.intervals[5].highestSpendingTransaction(for: "Food")?.id, "holiday")
        XCTAssertEqual(controller.highestCategoryTransactions["Food"]?.id, "holiday")
    }
}
