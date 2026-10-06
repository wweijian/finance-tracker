import SwiftUI

struct LocalFileStatusView: View {
    let statusMessage: String?
    let errorMessage: String?

    var body: some View {
        if errorMessage != nil || statusMessage != nil {
            Divider()
            HStack {
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                } else if let statusMessage {
                    Label(statusMessage, systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .font(.caption)
            .textSelection(.enabled)
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
}
