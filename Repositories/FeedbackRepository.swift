protocol FeedbackRepository: Sendable {
    func load() async throws -> String
    func save(_ notes: String) async throws
}
