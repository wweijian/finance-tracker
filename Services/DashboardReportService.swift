import Foundation

actor DashboardReportService {
    private let repository: any TransactionRepository

    init(repository: any TransactionRepository) {
        self.repository = repository
    }

    func dashboard(for year: Int) throws -> DashboardSnapshot {
        try repository.dashboard(year: year)
    }
}
