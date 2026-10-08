import SwiftUI

struct DashboardView: View {
    @ObservedObject var controller: DashboardController
    let transactionsController: TransactionsController
    @Binding var screen: AppScreen

    var body: some View {
        VStack(spacing: 12) {
            DashboardPeriodControlsView(scope: controller.scope, periodLabel: controller.periodLabel,
                                        canGoBack: controller.canShowPreviousPeriod,
                                        canGoForward: controller.canShowNextPeriod,
                                        goBack: controller.navigatePreviousPeriod,
                                        goForward: controller.navigateNextPeriod,
                                        selectScope: controller.selectScope)
                .padding(.horizontal)
                .padding(.top)
            reportPages
        }
        .task {
            controller.load()
            transactionsController.load()
        }
        .onChange(of: screen) {
            if screen == .transactions && controller.selectedPage != .transactions {
                controller.selectedPage = .transactions
            } else if screen == .dashboard && controller.selectedPage == .transactions {
                controller.selectedPage = .spending
            }
        }
        .onChange(of: controller.selectedPage) {
            let destination: AppScreen = controller.selectedPage == .transactions ? .transactions : .dashboard
            if screen != destination { screen = destination }
        }
    }

    private var reportPages: some View {
        Group {
            if controller.isLoading {
                ProgressView("Loading reports…")
            } else if let error = controller.errorMessage {
                DashboardErrorView(message: error, retry: controller.load)
            } else {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(DashboardPage.allCases) { reportPage in
                            DashboardReportPageView(page: reportPage, snapshot: controller.snapshot,
                                                    intervals: controller.intervals, peakMonths: controller.peakMonths,
                                                    scope: controller.scope, categoryComparisons: controller.categoryComparisons,
                                                    dashboardController: controller,
                                                    transactionsController: transactionsController)
                                .containerRelativeFrame(.vertical)
                                .id(reportPage)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $controller.selectedPage, anchor: .top)
                .overlay(alignment: .trailing) {
                    DashboardPageIndicatorView(selection: controller.selectedPage) { page in
                        withAnimation { controller.selectedPage = page }
                    }
                    .padding(.trailing, 12)
                }
                .accessibilityLabel("Reports and transactions")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
