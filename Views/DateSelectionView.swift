import SwiftUI

struct DateSelectionView: View {
    let title: String
    @Binding var date: Date
    @State private var showsCalendar = false

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 6) {
                DatePicker(title, selection: $date, displayedComponents: .date)
                    .datePickerStyle(.field)
                    .labelsHidden()
                    .environment(\.calendar, Calendar(identifier: .gregorian))
                    .environment(\.timeZone, TimeZone(secondsFromGMT: 0)!)
                Button("Choose \(title.lowercased())", systemImage: "calendar") { showsCalendar.toggle() }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Choose a date from a calendar")
                    .popover(isPresented: $showsCalendar) {
                        DateCalendarView(title: title, date: date) { selected in
                            date = selected
                            showsCalendar = false
                        }
                    }
            }
        }
    }
}
