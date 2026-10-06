import SwiftUI

struct DateTextField: View {
    let title: String
    @Binding var text: String
    @State private var showsCalendar = false

    var body: some View {
        HStack(spacing: 4) {
            TextField(title, text: $text, prompt: Text("YYYY-MM-DD"))
                .textFieldStyle(.roundedBorder)
                .monospacedDigit()
                .frame(width: 112)
                .accessibilityLabel(title)
                .help("Type a date as YYYY-MM-DD. Leave blank for no limit.")
            Button("Choose \(title.lowercased())", systemImage: "calendar") { showsCalendar.toggle() }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help("Choose \(title.lowercased()) from a calendar")
                .popover(isPresented: $showsCalendar) {
                    DateCalendarView(
                        title: title,
                        date: TransactionDateFormatter().date(from: text) ?? Date(),
                        choose: { date in
                            text = TransactionDateFormatter().string(from: date)
                            showsCalendar = false
                        }
                    )
                }
        }
    }
}
