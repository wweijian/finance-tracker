import SwiftUI

struct DateTextField: View {
    let title: String
    @Binding var text: String
    @State private var date: Date
    private let formatter = TransactionDateFormatter()

    init(title: String, text: Binding<String>) {
        self.title = title
        _text = text
        _date = State(initialValue: TransactionDateFormatter().date(from: text.wrappedValue) ?? Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                DatePicker(title, selection: $date, displayedComponents: .date)
                    .datePickerStyle(.field)
                    .labelsHidden()
                    .environment(\.calendar, Calendar(identifier: .gregorian))
                    .environment(\.timeZone, TimeZone(secondsFromGMT: 0)!)
                    .accessibilityLabel(title)
                if formatter.date(from: text) == nil {
                    Button("Use date") { text = formatter.string(from: date) }
                        .help("Use the selected date")
                } else {
                    Button("Clear date", systemImage: "xmark.circle") { text = "" }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .help("Clear this date")
                }
            }
            if text.isEmpty {
                Text("No date selected").font(.caption).foregroundStyle(.secondary)
            } else if formatter.date(from: text) == nil {
                Text("Invalid date: \(text)")
                    .font(.caption).foregroundStyle(.red)
                    .textSelection(.enabled)
            }
        }
        .onChange(of: date) { text = formatter.string(from: date) }
        .onChange(of: text) {
            if let parsed = formatter.date(from: text), parsed != date { date = parsed }
        }
    }
}
