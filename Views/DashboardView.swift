import SwiftUI

struct DashboardView: View {
    @ObservedObject var controller: DashboardController

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    DashboardHeaderView(
                        year: controller.selectedYear,
                        showPreviousYear: controller.showPreviousYear,
                        showNextYear: controller.showNextYear
                    )
                    DashboardSummaryView(snapshot: controller.snapshot)
                    DashboardContentView(
                        snapshot: controller.snapshot,
                        isLoading: controller.isLoading,
                        errorMessage: controller.errorMessage
                    )
                }
                .padding(28)
                .frame(maxWidth: 1_200, alignment: .leading)
            }
            .navigationTitle("Ledgerly")
        }
        .task {
            controller.load()
        }
    }
}
