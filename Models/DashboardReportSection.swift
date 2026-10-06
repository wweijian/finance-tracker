import Foundation

enum DashboardReportSection: String, CaseIterable, Identifiable {
    case cashFlow = "Cash flow"
    case categories = "Categories"
    case monthly = "Monthly detail"

    var id: String { rawValue }
}
