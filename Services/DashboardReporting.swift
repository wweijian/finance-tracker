protocol DashboardReporting: Sendable {
    func dashboard(for period: DashboardPeriod) async throws -> DashboardSnapshot
}
