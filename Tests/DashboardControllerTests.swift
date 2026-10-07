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
}
