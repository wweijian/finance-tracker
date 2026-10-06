import Combine
import Foundation

@MainActor
final class DashboardController: ObservableObject {
    @Published private(set) var snapshot = DashboardSnapshot.empty
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedYear: Int
    @Published var filtersDateRange = false
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var comparisonMonth: Int

    private let reportService: any DashboardReporting
    private var requestID = UUID()
    private let dateFormatter = TransactionDateFormatter()

    init(reportService: any DashboardReporting, selectedYear: Int = Calendar.current.component(.year, from: Date())) {
        self.reportService = reportService
        self.selectedYear = selectedYear
        startDate = TransactionDateFormatter().date(from: String(format: "%04d-01-01", selectedYear))!
        endDate = TransactionDateFormatter().date(from: String(format: "%04d-12-31", selectedYear))!
        comparisonMonth = Calendar.current.component(.month, from: Date())
    }

    var availableYears: [Int] {
        Set(snapshot.availableYears).union([selectedYear, Calendar.current.component(.year, from: Date())]).sorted(by: >)
    }

    var comparisonReport: MonthlyReport? {
        snapshot.months.first { $0.month == comparisonMonth } ?? snapshot.months.last
    }

    var periodLabel: String {
        filtersDateRange ? "\(dateFormatter.string(from: startDate)) – \(dateFormatter.string(from: endDate))" : String(selectedYear)
    }

    func load() {
        let id = UUID()
        requestID = id
        errorMessage = nil
        do {
            let period = try DashboardPeriod(
                year: selectedYear,
                startDate: filtersDateRange ? dateFormatter.string(from: startDate) : nil,
                endDate: filtersDateRange ? dateFormatter.string(from: endDate) : nil
            )
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
        guard (2...9998).contains(year) else { return }
        selectedYear = year
        startDate = dateFormatter.date(from: String(format: "%04d-01-01", year))!
        endDate = dateFormatter.date(from: String(format: "%04d-12-31", year))!
        load()
    }

    func showPreviousYear() { selectYear(selectedYear - 1) }
    func showNextYear() { selectYear(selectedYear + 1) }

    private func fail(_ error: Error) {
        snapshot = .empty
        errorMessage = error.localizedDescription
        isLoading = false
    }
}
