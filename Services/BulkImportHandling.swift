import Foundation

protocol BulkImportHandling: Sendable {
    func previewFile(at url: URL, kind: CSVImportKind, categories: [String]) async throws -> [ImportCandidate]
    func validate(_ candidates: [ImportCandidate], categories: [String]) async throws -> [ImportCandidate]
    func commit(_ candidates: [ImportCandidate], categories: [String]) async throws -> BulkImportSummary
    func undo(_ summary: BulkImportSummary) async throws
}
