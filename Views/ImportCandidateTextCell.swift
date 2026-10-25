import SwiftUI

struct ImportCandidateTextCell: View {
    let title: String
    @Binding var text: String
    var editingChanged: (Bool) -> Void = { _ in }
    var alignment: TextAlignment = .leading
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(title, text: $text, axis: .vertical)
            .lineLimit(1...2)
            .textFieldStyle(.plain)
            .multilineTextAlignment(alignment)
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .background(isFocused ? Color.accentColor.opacity(0.07) : .clear, in: RoundedRectangle(cornerRadius: 5))
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(isFocused ? Color.accentColor.opacity(0.5) : .clear)
                    .allowsHitTesting(false)
            }
            .focused($isFocused)
            .onChange(of: isFocused) { editingChanged(isFocused) }
            .accessibilityLabel(title)
            .accessibilityIdentifier("import-\(title.lowercased())")
    }
}
