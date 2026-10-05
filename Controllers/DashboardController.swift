import Combine
import Foundation

@MainActor
final class DashboardController: ObservableObject {
    @Published private(set) var snapshot = DashboardSnapshot.empty
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedYear: Int

    private let reportService: DashboardReportService

    init(reportService: DashboardReportService, selectedYear: Int = Calendar.current.component(.year, from: Date())) {
        self.reportService = reportService
        self.selectedYear = selectedYear
    }

    func load() {
        let year = selectedYear
        isLoading = true
        errorMessage = nil

        Task { [reportService] in
            do {
                let snapshot = try await reportService.dashboard(for: year)
                apply(snapshot: snapshot, for: year)
            } catch {
                apply(error: error, for: year)
            }
        }
    }

    func showPreviousYear() {
        selectedYear -= 1
        load()
    }

    func showNextYear() {
        selectedYear += 1
        load()
    }

    private func apply(snapshot: DashboardSnapshot, for year: Int) {
        guard selectedYear == year else { return }
        self.snapshot = snapshot
        isLoading = false
    }

    private func apply(error: Error, for year: Int) {
        guard selectedYear == year else { return }
        errorMessage = error.localizedDescription
        isLoading = false
    }
}
