import Foundation

actor LocalFeedbackRepository: FeedbackRepository {
    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func load() throws -> String {
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return ""
        }
    }

    func save(_ notes: String) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try notes.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
