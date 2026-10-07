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

    private let reportService: any DashboardReporting
    private var requestID = UUID()
    private let currentDate: () -> Date

    init(reportService: any DashboardReporting, selectedYear: Int? = nil, currentDate: @escaping () -> Date = Date.init) {
        self.reportService = reportService
        self.currentDate = currentDate
        let now = currentDate()
        let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        let year = min(selectedYear ?? Calendar.current.component(.year, from: previousMonth), Calendar.current.component(.year, from: now))
        self.selectedYear = year
        periodLabel = String(year)
        startDateText = String(format: "%04d-01-01", year)
        endDateText = String(format: "%04d-12-31", year)
        comparisonMonth = Calendar.current.component(.month, from: previousMonth)
    }

    var currentYear: Int { Calendar.current.component(.year, from: currentDate()) }

    var availableYears: [Int] {
        Set(snapshot.availableYears).union([selectedYear, currentYear]).filter { $0 <= currentYear }.sorted(by: >)
    }

    var comparisonReport: MonthlyReport? {
        snapshot.months.first { $0.month == comparisonMonth } ?? snapshot.months.last
    }

    func load() {
        let id = UUID()
        requestID = id
        errorMessage = nil
        do {
            let period = try DashboardPeriod(
                year: selectedYear,
                startDate: filtersDateRange ? startDateText : nil,
                endDate: filtersDateRange ? endDateText : nil
            )
            periodLabel = filtersDateRange ? "\(period.startDate) – \(period.endDate)" : String(period.year)
            isLoading = true
            Task { [reportService] in
                do {
                    let result = try await reportService.dashboard(for: period)
                    guard requestID == id else { return }
                    snapshot = result
                    comparisonMonth = comparisonReport?.month ?? comparisonMonth
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
        snapshot = .empty
        errorMessage = error.localizedDescription
        isLoading = false
    }
}
