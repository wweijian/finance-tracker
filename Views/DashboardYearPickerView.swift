import SwiftUI

struct DashboardYearPickerView: View {
    let year: Int
    let availableYears: [Int]
    let selectYear: (Int) -> Void
    let showPreviousYear: () -> Void
    let showNextYear: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button("Previous year", systemImage: "chevron.left", action: showPreviousYear)
                .disabled(year <= 2)
                .help("Previous year")
            Picker("Reporting year", selection: Binding(get: { year }, set: { selectYear($0) })) {
                ForEach(availableYears, id: \.self) { Text(String($0)).tag($0) }
            }
            .labelsHidden()
            .frame(width: 82)
            Button("Next year", systemImage: "chevron.right", action: showNextYear)
                .disabled(year >= 9998)
                .help("Next year")
        }
        .labelStyle(.iconOnly)
    }
}
