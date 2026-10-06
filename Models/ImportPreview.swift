import Foundation

struct ImportPreview: Sendable {
    let candidates: [ImportCandidate]

    var readyCount: Int { candidates.filter(\.isReady).count }
    var rejectedCount: Int { candidates.count - readyCount }

    func rows(matching filter: ImportRowFilter) -> [ImportCandidate] {
        switch filter {
        case .all: candidates
        case .ready: candidates.filter(\.isReady)
        case .needsAttention: candidates.filter { !$0.isReady }
        }
    }

    func count(for filter: ImportRowFilter) -> Int {
        switch filter {
        case .all: candidates.count
        case .ready: readyCount
        case .needsAttention: rejectedCount
        }
    }
}
