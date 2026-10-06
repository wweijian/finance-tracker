import SwiftUI

struct LocalFileActionsView: View {
    @ObservedObject var controller: LocalFilesController

    var body: some View {
        HStack {
            if controller.isWorking { ProgressView().controlSize(.small) }
            Menu("Database", systemImage: "externaldrive") {
                Button("Back up database…", action: controller.chooseBackup)
                Button("Restore database…", action: controller.chooseRestore)
            }
            .labelStyle(.iconOnly)
            .help("Database backup and restore")
            .disabled(controller.isWorking)
            .accessibilityLabel("Local database backup and restore")
        }
    }
}
