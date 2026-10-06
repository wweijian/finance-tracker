import AppKit
import Combine
import UniformTypeIdentifiers

@MainActor
final class LocalFilesController: ObservableObject {
    @Published private(set) var isWorking = false
    @Published private(set) var statusMessage: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var restoreRevision = 0
    @Published var pendingRestore: PendingDatabaseRestore?

    private let service: any LocalFileHandling

    init(service: any LocalFileHandling) {
        self.service = service
    }

    func chooseExport(_ transactions: [TransactionListItem]) {
        guard !isWorking, pendingRestore == nil, !transactions.isEmpty,
              let url = saveLocation(title: "Export filtered transactions as CSV", filename: "ledgerly-transactions.csv", type: .commaSeparatedText) else { return }
        perform { [service] in
            try await service.export(transactions, to: url)
            return "Exported \(transactions.count) transactions to \(url.lastPathComponent)."
        }
    }

    func chooseBackup() {
        guard !isWorking, pendingRestore == nil,
              let url = saveLocation(title: "Back up database", filename: "ledgerly-backup.sqlite", type: UTType(filenameExtension: "sqlite") ?? .data) else { return }
        perform { [service] in
            try await service.backUp(to: url)
            return "Database backed up to \(url.lastPathComponent)."
        }
    }

    func chooseRestore() {
        guard !isWorking, pendingRestore == nil else { return }
        let panel = NSOpenPanel()
        panel.title = "Choose a Ledgerly database backup"
        panel.allowedContentTypes = [UTType(filenameExtension: "sqlite") ?? .data, .data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        isWorking = true
        statusMessage = nil
        errorMessage = nil
        Task { [service] in
            do {
                let count = try await service.validateBackup(at: url)
                pendingRestore = PendingDatabaseRestore(url: url, transactionCount: count)
            } catch {
                errorMessage = "Restore unavailable: \(error.localizedDescription)"
            }
            isWorking = false
        }
    }

    func confirmRestore(_ restore: PendingDatabaseRestore) {
        guard !isWorking else { return }
        pendingRestore = nil
        isWorking = true
        errorMessage = nil
        Task { [service] in
            do {
                try await service.restore(from: restore.url)
                restoreRevision += 1
                statusMessage = "Restored database from \(restore.url.lastPathComponent)."
            } catch {
                errorMessage = "Restore failed: \(error.localizedDescription)"
            }
            isWorking = false
        }
    }

    private func saveLocation(title: String, filename: String, type: UTType) -> URL? {
        let panel = NSSavePanel()
        panel.title = title
        panel.nameFieldStringValue = filename
        panel.allowedContentTypes = [type]
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func perform(_ operation: @escaping @Sendable () async throws -> String) {
        isWorking = true
        errorMessage = nil
        statusMessage = nil
        Task {
            do { statusMessage = try await operation() }
            catch { errorMessage = "File operation failed: \(error.localizedDescription)" }
            isWorking = false
        }
    }
}
