import Foundation

protocol DatabaseFileRepository: Sendable {
    func checkFileLocation(_ url: URL) throws
    func backUp(to url: URL) throws
    func validateBackup(at url: URL) throws -> Int
    func restoreDatabase(from url: URL) throws
}
