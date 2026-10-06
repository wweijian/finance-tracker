import Foundation

struct DashboardPeriod: Sendable, Equatable {
    let year: Int
    let startDate: String
    let endDate: String

    init(year: Int, startDate: String? = nil, endDate: String? = nil) throws {
        guard (2...9998).contains(year) else { throw DashboardPeriodError.invalidYear }
        let start = startDate ?? String(format: "%04d-01-01", year)
        let end = endDate ?? String(format: "%04d-12-31", year)
        let formatter = TransactionDateFormatter()
        guard let startValue = formatter.date(from: start), let endValue = formatter.date(from: end),
              formatter.string(from: startValue) == start, formatter.string(from: endValue) == end,
              start.hasPrefix(String(format: "%04d-", year)), end.hasPrefix(String(format: "%04d-", year)),
              start <= end else { throw DashboardPeriodError.invalidRange }
        self.year = year
        self.startDate = start
        self.endDate = end
    }
}
