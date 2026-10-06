import SwiftUI

struct ImportErrorBannerView: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
            Text(message).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
            CopyImportErrorButton(message: message)
        }
        .font(.callout)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
