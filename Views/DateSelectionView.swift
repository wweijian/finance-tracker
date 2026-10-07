import SwiftUI

struct DateSelectionView: View {
    let title: String
    @Binding var date: Date
    @State private var text: String
    let validationChanged: (Bool) -> Void

    init(title: String, date: Binding<Date>, validationChanged: @escaping (Bool) -> Void = { _ in }) {
        self.title = title
        _date = date
        _text = State(initialValue: TransactionDateFormatter().string(from: date.wrappedValue))
        self.validationChanged = validationChanged
    }

    var body: some View {
        LabeledContent(title) {
            VStack(alignment: .leading, spacing: 4) {
                DateTextField(title: title, text: $text)
                if TransactionDateFormatter().date(from: text) == nil {
                    Text("Enter a valid date as YYYY-MM-DD.")
                        .font(.caption).foregroundStyle(.red)
                }
            }
        }
        .onChange(of: text) {
            let parsed = TransactionDateFormatter().date(from: text)
            validationChanged(parsed != nil)
            if let parsed { date = parsed }
        }
        .onChange(of: date) { text = TransactionDateFormatter().string(from: date) }
    }
}
