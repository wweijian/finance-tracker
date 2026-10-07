import Foundation

actor DashboardReportService: DashboardReporting {
    private let repository: any TransactionRepository
    private let dateFormatter = TransactionDateFormatter()
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    init(repository: any TransactionRepository) {
        self.repository = repository
    }

    func dashboard(for period: DashboardPeriod) throws -> DashboardSnapshot {
        let transactions = try repository.transactions(includeDeleted: false)
        let current = rows(transactions, from: period.startDate, through: period.endDate)
        let priorDates = comparisonDates(from: period.startDate, through: period.endDate, component: .year)
        let priorYear = rows(transactions, from: priorDates.start, through: priorDates.end)
        let totals = totals(current)
        let years = Set(transactions.compactMap { Int($0.transactionDate.prefix(4)) })
        let previousYearMonths = period.year > 2
            ? monthlyReports(transactions, period: try DashboardPeriod(year: period.year - 1)) : []
        let months = monthlyReports(transactions, period: period)
        let fullYear = try DashboardPeriod(year: period.year)
        let historyMonths = period == fullYear ? months : monthlyReports(transactions, period: fullYear)
        return DashboardSnapshot(
            totals: totals,
            yearOverYear: ReportComparison(current: totals, previous: self.totals(priorYear)),
            months: months,
            categoryTotals: categoryTotals(current, previous: priorYear),
            availableYears: years.union([period.year, calendar.component(.year, from: Date())]).sorted(by: >),
            spendingHistoryMonths: previousYearMonths + historyMonths
        )
    }

    private func monthlyReports(_ transactions: [TransactionListItem], period: DashboardPeriod) -> [MonthlyReport] {
        (1...12).compactMap { month in
            let start = String(format: "%04d-%02d-01", period.year, month)
            let date = dateFormatter.date(from: start)!
            let lastDay = calendar.range(of: .day, in: .month, for: date)!.count
            let end = String(format: "%04d-%02d-%02d", period.year, month, lastDay)
            let from = max(start, period.startDate)
            let through = min(end, period.endDate)
            guard from <= through else { return nil }
            return monthlyReport(transactions, month: month, from: from, through: through)
        }
    }

    private func monthlyReport(_ transactions: [TransactionListItem], month: Int, from: String, through: String) -> MonthlyReport {
        let current = rows(transactions, from: from, through: through)
        let previousDates = comparisonDates(from: from, through: through, component: .month)
        let previous = rows(transactions, from: previousDates.start, through: previousDates.end)
        let priorDates = comparisonDates(from: from, through: through, component: .year)
        let priorYear = rows(transactions, from: priorDates.start, through: priorDates.end)
        let totals = totals(current)
        return MonthlyReport(
            month: month, startDate: from, endDate: through, totals: totals,
            monthOverMonth: ReportComparison(current: totals, previous: self.totals(previous)),
            yearOverYear: ReportComparison(current: totals, previous: self.totals(priorYear)),
            categories: monthlyCategories(current, previous: previous, priorYear: priorYear),
            categoryAmounts: current.reduce(into: [:]) { $0[$1.category, default: 0] += $1.amountCents }
        )
    }

    private func rows(_ transactions: [TransactionListItem], from: String, through: String) -> [TransactionListItem] {
        transactions.filter { $0.transactionDate >= from && $0.transactionDate <= through }
    }

    private func totals(_ transactions: [TransactionListItem]) -> ReportTotals {
        transactions.reduce(into: ReportTotals()) { result, transaction in
            result.transactionCount += 1
            switch transaction.transactionType {
            case .income: result.incomeCents += transaction.amountCents
            case .expense:
                if transaction.category == "Investment" {
                    result.investmentCents += transaction.amountCents
                } else {
                    result.expenseCents += transaction.amountCents
                }
            }
        }
    }

    private func spending(_ transactions: [TransactionListItem]) -> [String: Int] {
        transactions.filter { $0.transactionType == .expense && $0.category != "Investment" }.reduce(into: [:]) { totals, transaction in
            totals[transaction.category, default: 0] += transaction.amountCents
        }
    }

    private func categoryTotals(_ current: [TransactionListItem], previous: [TransactionListItem]) -> [CategoryTotal] {
        let amounts = spending(current)
        let prior = spending(previous)
        return Set(amounts.keys).union(prior.keys).map { category in
            CategoryTotal(category: category, amountCents: amounts[category, default: 0],
                          previousYearCents: previous.isEmpty ? nil : prior[category, default: 0])
        }.sorted { $0.amountCents == $1.amountCents ? $0.category < $1.category : $0.amountCents > $1.amountCents }
    }

    private func monthlyCategories(_ current: [TransactionListItem], previous: [TransactionListItem], priorYear: [TransactionListItem]) -> [CategoryMonthlyReport] {
        let amounts = spending(current)
        let prior = spending(previous)
        let lastYear = spending(priorYear)
        return Set(amounts.keys).union(prior.keys).sorted().map { category in
            let amount = amounts[category, default: 0]
            return CategoryMonthlyReport(
                category: category, amountCents: amount,
                monthOverMonth: FinancialChange(currentCents: amount, previousCents: previous.isEmpty ? nil : prior[category, default: 0]),
                yearOverYear: FinancialChange(currentCents: amount, previousCents: priorYear.isEmpty ? nil : lastYear[category, default: 0])
            )
        }
    }

    private func comparisonDates(from: String, through: String, component: Calendar.Component) -> (start: String, end: String) {
        let start = dateFormatter.date(from: from)!
        let end = dateFormatter.date(from: through)!
        let coversWholeMonths = calendar.component(.day, from: start) == 1 &&
            calendar.component(.day, from: end) == calendar.range(of: .day, in: .month, for: end)!.count
        let previousStart = shifted(from, component: component)
        let previousEnd = shifted(through, component: component)
        guard coversWholeMonths else { return (previousStart, previousEnd) }
        let previousDate = dateFormatter.date(from: previousEnd)!
        let lastDay = calendar.range(of: .day, in: .month, for: previousDate)!.count
        return (previousStart, String(previousEnd.prefix(8)) + String(format: "%02d", lastDay))
    }

    private func shifted(_ value: String, component: Calendar.Component) -> String {
        let date = dateFormatter.date(from: value)!
        return dateFormatter.string(from: calendar.date(byAdding: component, value: -1, to: date)!)
    }
}
