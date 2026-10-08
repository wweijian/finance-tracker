enum DashboardScope: String, Sendable {
    case monthly
    case yearly

    var intervalLabel: String { self == .monthly ? "Day" : "Month" }
}
