import Foundation

enum ImportActivity: Equatable, Sendable {
    case readingFile
    case validatingRows
    case importingRows
    case undoingImport

    var description: String {
        switch self {
        case .readingFile: "Reading CSV…"
        case .validatingRows: "Checking changes…"
        case .importingRows: "Importing transactions…"
        case .undoingImport: "Undoing import…"
        }
    }
}
