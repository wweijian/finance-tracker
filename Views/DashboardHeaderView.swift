import SwiftUI

struct DashboardHeaderView: View {
    let year: Int
    let showPreviousYear: () -> Void
    let showNextYear: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                heading
                Spacer()
                yearControls
            }
            VStack(alignment: .leading, spacing: 16) {
                heading
                yearControls
            }
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Financial overview")
                .font(.largeTitle.weight(.bold))
            Text("Your spending and income for \(year)")
                .foregroundStyle(.secondary)
        }
    }

    private var yearControls: some View {
        HStack(spacing: 12) {
            Button(action: showPreviousYear) {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("Show previous year")

            Text(String(year))
                .font(.headline.monospacedDigit())
                .frame(minWidth: 48)

            Button(action: showNextYear) {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel("Show next year")
        }
        .buttonStyle(.bordered)
    }
}
