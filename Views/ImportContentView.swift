import SwiftUI

struct ImportContentView: View {
    @Binding var candidates: [ImportCandidate]
    let filename: String?
    let activity: ImportActivity?
    let errorMessage: String?
    let chooseFile: () -> Void
    let removedRowCount: Int
    let remove: (Set<String>) -> Void
    let undoRemovals: () -> Void
    let categories: [String]

    var body: some View {
        VStack(spacing: 0) {
            if candidates.isEmpty && removedRowCount == 0 {
                if let activity {
                    ProgressView(activity.description)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ImportFileSelectionView(filename: filename, errorMessage: errorMessage, chooseFile: chooseFile)
                }
            } else {
                ImportPreviewView(
                    candidates: $candidates, isWorking: activity != nil && activity != .validatingRows,
                    removedRowCount: removedRowCount, remove: remove,
                    undoRemovals: undoRemovals, categories: categories
                )
                if let errorMessage {
                    Divider()
                    ImportErrorBannerView(message: errorMessage)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}
