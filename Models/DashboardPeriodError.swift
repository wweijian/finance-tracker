import Foundation

enum DashboardPeriodError: LocalizedError {
    case invalidYear
    case invalidRange

    var errorDescription: String? {
        switch self {
        case .invalidYear: "Choose a year between 2 and 9998."
        case .invalidRange: "Choose a start date on or before the end date, both within the selected year."
        }
    }
}
