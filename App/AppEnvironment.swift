enum AppEnvironment {
    case development
    case production

    static var current: AppEnvironment {
        #if DEBUG
        .development
        #else
        .production
        #endif
    }

    var supportDirectoryName: String {
        // Preserve existing personal and development data across the app rename.
        switch self {
        case .development: "Ledgerly Development"
        case .production: "Ledgerly"
        }
    }
}
