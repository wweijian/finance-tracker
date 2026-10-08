import SwiftUI

struct FeedbackView: View {
    @ObservedObject var controller: FeedbackController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Feedback")
                .font(.title2.weight(.semibold))
            Text("Keep ideas, bugs, and improvements here. Saved notes stay on this Mac between app sessions.")
                .foregroundStyle(.secondary)

            GroupBox("Notes") {
                TextEditor(text: $controller.notes)
                    .font(.body)
                    .disabled(!controller.canSave)
                    .accessibilityLabel("Feedback notes")
                    .accessibilityIdentifier("feedbackNotes")
            }

            if let errorMessage = controller.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            HStack {
                if controller.isLoading || controller.isSaving {
                    ProgressView().controlSize(.small)
                    Text(controller.isLoading ? "Loading notes…" : "Saving notes…")
                        .foregroundStyle(.secondary)
                } else if !controller.hasLoaded {
                    Button("Retry") { Task { await controller.load() } }
                }
                Spacer()
                Button("Cancel", action: controller.cancel)
                    .keyboardShortcut(.cancelAction)
                    .disabled(controller.isLoading || controller.isSaving)
                Button("Save & Close") { Task { await controller.save() } }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!controller.canSave)
            }
        }
        .padding(24)
        .frame(width: 560, height: 440)
        .interactiveDismissDisabled()
    }
}
