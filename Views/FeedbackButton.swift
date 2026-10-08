import SwiftUI

struct FeedbackButton: View {
    let open: () -> Void

    var body: some View {
        Button("Feedback", systemImage: "square.and.pencil", action: open)
        .help("Write and revisit your private feedback notes")
        .accessibilityIdentifier("feedbackButton")
    }
}
