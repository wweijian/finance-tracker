import SwiftUI

struct RemarksEditorView: View {
    @Binding var text: String

    var body: some View {
        LabeledContent("Remarks (optional)") {
            EditableRemarksTextView(text: $text)
                .frame(height: 80)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.secondary.opacity(0.35))
                        .allowsHitTesting(false)
                }
                .accessibilityLabel("Remarks")
        }
    }
}
