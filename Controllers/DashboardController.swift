import Combine
import Foundation

@MainActor
final class DashboardController: ObservableObject {
    @Published private(set) var snapshot = DashboardSnapshot.empty
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedYear: Int
    @Published private(set) var periodLabel: String
    @Published var filtersDateRange = false
    @Published var startDateText: String
    @Published var endDateText: String
    @Published var comparisonMonth: Int
    @Published private(set) var scope: DashboardScope = .monthly
    @Published var selectedPage: DashboardPage? = .spending
    @Published private(set) var reportingPeriod: DashboardPeriod?
    private(set) var intervals: [ReportInterval] = []
    private(set) var peakMonths: [ReportInterval] = []
    private(set) var categoryComparisons: [CategorySpendingComparison] = []
    private(set) var highestCategoryTransactions: [String: TransactionListItem] = [:]

    private let reportService: any DashboardReporting
    private var requestID = UUID()
    private let currentDate: () -> Date

    init(reportService: any DashboardReporting, selectedYear: Int? = nil, currentDate: @escaping () -> Date = Date.init) {
        self.reportService = reportService
        self.currentDate = currentDate
        let now = currentDate()
        let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        let currentYear = Calendar.current.component(.year, from: now)
        let year = max(2, min(selectedYear ?? Calendar.current.component(.year, from: previousMonth), currentYear, 9998))
        self.selectedYear = year
        periodLabel = String(year)
        startDateText = String(format: "%04d-01-01", year)
        endDateText = String(format: "%04d-12-31", year)
        let month = Calendar.current.component(.month, from: previousMonth)
        comparisonMonth = year == currentYear ? min(month, Calendar.current.component(.month, from: now)) : month
    }

    var currentYear: Int { Calendar.current.component(.year, from: currentDate()) }

    var availableYears: [Int] {
        Set(snapshot.availableYears).union([selectedYear, currentYear]).filter { $0 <= currentYear }.sorted(by: >)
    }

    var comparisonReport: MonthlyReport? {
        snapshot.months.first { $0.month == comparisonMonth } ?? snapshot.months.last
    }

    func transactionIntervals(for transactions: [TransactionListItem]) -> [ReportInterval] {
        let grouped = Dictionary(grouping: transactions) {
            scope == .monthly ? $0.transactionDate : String($0.transactionDate.prefix(7))
        }
        return intervals.map { interval in
            let key = scope == .monthly ? interval.startDate : String(interval.startDate.prefix(7))
            return ReportInterval(startDate: interval.startDate, label: interval.label, totals: interval.totals,
                                  categories: interval.categories, transactions: grouped[key, default: []])
        }
    }

    var canShowPreviousPeriod: Bool { selectedYear > 2 || (scope == .monthly && comparisonMonth > 1) }

    var canShowNextPeriod: Bool {
        if scope == .yearly { return selectedYear < currentYear }
        return selectedYear < currentYear || comparisonMonth < Calendar.current.component(.month, from: currentDate())
    }

    func toggleScope() {
        selectScope(scope == .monthly ? .yearly : .monthly)
    }

    func selectScope(_ selection: DashboardScope) {
        guard selection != scope else { return }
        scope = selection
        filtersDateRange = false
        if selectedYear == currentYear {
            comparisonMonth = min(comparisonMonth, Calendar.current.component(.month, from: currentDate()))
        }
        load()
    }

    func navigatePreviousPeriod() {
        guard canShowPreviousPeriod else { return }
        shiftPeriod(by: -1)
    }

    func navigateNextPeriod() {
        guard canShowNextPeriod else { return }
        shiftPeriod(by: 1)
    }

    private func shiftPeriod(by offset: Int) {
        filtersDateRange = false
        if scope == .yearly {
            selectYear(selectedYear + offset)
        } else {
            let month = comparisonMonth + offset
            comparisonMonth = month < 1 ? 12 : month > 12 ? 1 : month
            selectYear(selectedYear + (month < 1 ? -1 : month > 12 ? 1 : 0))
        }
    }

    func load() {
        let id = UUID()
        requestID = id
        errorMessage = nil
        do {
            let period = try makePeriod()
            reportingPeriod = period
            periodLabel = label(for: period)
            isLoading = true
            Task { [reportService] in
                do {
                    let result = try await reportService.dashboard(for: period)
                    guard requestID == id else { return }
                    apply(result)
                    isLoading = false
                } catch {
                    guard requestID == id else { return }
                    fail(error)
                }
            }
        } catch {
            fail(error)
        }
    }

    func selectYear(_ year: Int) {
        guard (2...min(currentYear, 9998)).contains(year) else { return }
        selectedYear = year
        if scope == .monthly && year == currentYear {
            comparisonMonth = min(comparisonMonth, Calendar.current.component(.month, from: currentDate()))
        }
        startDateText = String(format: "%04d-01-01", year)
        endDateText = String(format: "%04d-12-31", year)
        load()
    }

    func showPreviousYear() { selectYear(selectedYear - 1) }
    func showNextYear() { selectYear(selectedYear + 1) }

    func applyDateRange() {
        filtersDateRange = true
        load()
    }

    func showPreviousMonth() {
        let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentDate())!
        comparisonMonth = Calendar.current.component(.month, from: previousMonth)
        filtersDateRange = false
        selectYear(Calendar.current.component(.year, from: previousMonth))
    }

    private func fail(_ error: Error) {
        intervals = []
        peakMonths = []
        categoryComparisons = []
        highestCategoryTransactions = [:]
        snapshot = .empty
        errorMessage = error.localizedDescription
        isLoading = false
    }

    private func apply(_ result: DashboardSnapshot) {
        highestCategoryTransactions = SpendingTransactionSelector.highestByCategory(in: result.transactions)
        intervals = result.intervals(for: scope)
        peakMonths = result.spendingHistoryMonths.filter { $0.startDate.hasPrefix(String(selectedYear)) }.map {
            ReportInterval(startDate: $0.startDate, label: $0.label, totals: $0.totals,
                           categories: $0.spendingDistribution, transactions: [])
        }
        let month = result.months.first { $0.month == comparisonMonth } ?? result.months.last
        if scope == .monthly {
            categoryComparisons = (month?.categories ?? []).map {
                CategorySpendingComparison(category: $0.category, change: $0.monthOverMonth)
            }
        } else {
            categoryComparisons = result.categoryTotals.map {
                CategorySpendingComparison(category: $0.category, change: $0.yearOverYear)
            }
        }
        categoryComparisons.sort {
            let left = max($0.amountCents, $0.change.previousCents ?? 0)
            let right = max($1.amountCents, $1.change.previousCents ?? 0)
            return left == right ? $0.category < $1.category : left > right
        }
        comparisonMonth = month?.month ?? comparisonMonth
        snapshot = result
    }

    private func makePeriod() throws -> DashboardPeriod {
        if filtersDateRange {
            return try DashboardPeriod(year: selectedYear, startDate: startDateText, endDate: endDateText)
        }
        if scope == .yearly { return try DashboardPeriod(year: selectedYear) }
        let dates = try monthRange()
        return try DashboardPeriod(year: selectedYear, startDate: dates.start, endDate: dates.end)
    }

    private func label(for period: DashboardPeriod) -> String {
        if filtersDateRange { return "\(period.startDate) – \(period.endDate)" }
        if scope == .yearly { return String(period.year) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        return "\(calendar.monthSymbols[comparisonMonth - 1]) \(selectedYear)"
    }

    private func monthRange() throws -> (start: String, end: String) {
        guard (1...12).contains(comparisonMonth) else { throw DashboardPeriodError.invalidRange }
        let start = String(format: "%04d-%02d-01", selectedYear, comparisonMonth)
        guard let date = TransactionDateFormatter().date(from: start) else { throw DashboardPeriodError.invalidRange }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let days = calendar.range(of: .day, in: .month, for: date)!.count
        return (start, String(format: "%04d-%02d-%02d", selectedYear, comparisonMonth, days))
    }
}
