import Foundation

enum ImportRowFilter: String, CaseIterable, Identifiable {
    case all = "All rows"
    case ready = "Ready"
    case needsAttention = "Needs attention"

    var id: String { rawValue }
}
