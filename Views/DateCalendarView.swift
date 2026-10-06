import SwiftUI

struct DateCalendarView: View {
    let title: String
    @State private var date: Date
    let choose: (Date) -> Void

    init(title: String, date: Date, choose: @escaping (Date) -> Void) {
        self.title = title
        _date = State(initialValue: date)
        self.choose = choose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            DatePicker(title, selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .environment(\.calendar, Calendar(identifier: .gregorian))
                .environment(\.timeZone, TimeZone(secondsFromGMT: 0)!)
            HStack {
                Spacer()
                Button("Use date") { choose(date) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
    }
}
