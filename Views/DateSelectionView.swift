import SwiftUI

struct DateSelectionView: View {
    let title: String
    @Binding var date: Date

    var body: some View {
        DatePicker(title, selection: $date, displayedComponents: .date)
            .datePickerStyle(.field)
            .environment(\.calendar, Calendar(identifier: .gregorian))
            .environment(\.timeZone, TimeZone(secondsFromGMT: 0)!)
    }
}
