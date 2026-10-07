import Foundation

enum DashboardReportSection: String, CaseIterable, Identifiable {
    case cashFlow = "Cash flow"
    case categories = "Categories"
    case monthly = "Monthly spending"

    var id: String { rawValue }
}
