import SwiftUI

struct RemarksEditorView: View {
    @Binding var text: String

    var body: some View {
        GroupBox("Remarks (optional)") {
            TextEditor(text: $text)
                .font(.body)
                .frame(height: 80)
                .accessibilityLabel("Remarks")
        }
    }
}
