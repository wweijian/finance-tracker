import SwiftUI

struct ImportContentView: View {
    let preview: ImportPreview
    let filename: String?
    let activity: ImportActivity?
    let errorMessage: String?
    let chooseFile: () -> Void
    let removedRowCount: Int
    let remove: (Set<String>) -> Void
    let undoRemovals: () -> Void
    let edit: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if preview.candidates.isEmpty && removedRowCount == 0 {
                if let activity {
                    ProgressView(activity.description)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ImportFileSelectionView(filename: filename, errorMessage: errorMessage, chooseFile: chooseFile)
                }
            } else {
                ImportPreviewView(preview: preview, isWorking: activity != nil, removedRowCount: removedRowCount, remove: remove, undoRemovals: undoRemovals, edit: edit)
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
