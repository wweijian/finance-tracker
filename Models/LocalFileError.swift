import Foundation

enum LocalFileError: LocalizedError {
    case liveDatabase
    case invalidBackup
    case localLocationRequired
    case destinationInUse

    var errorDescription: String? {
        switch self {
        case .liveDatabase: "Choose a different file. The active Ledgerly database and its journal files cannot be used here."
        case .invalidBackup: "This file is not a valid Ledgerly backup. Choose a SQLite backup created by Ledgerly. Your current database has not changed."
        case .localLocationRequired: "Choose a folder on this Mac outside iCloud Drive or a network volume."
        case .destinationInUse: "The destination has SQLite journal files and may be open in another app. Choose a new backup filename."
        }
    }
}
