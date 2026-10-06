import Foundation

struct ReportComparison: Sendable {
    let income: FinancialChange
    let expenses: FinancialChange
    let net: FinancialChange

    init(current: ReportTotals, previous: ReportTotals) {
        let hasBaseline = previous.transactionCount > 0
        income = FinancialChange(currentCents: current.incomeCents, previousCents: hasBaseline ? previous.incomeCents : nil)
        expenses = FinancialChange(currentCents: current.expenseCents, previousCents: hasBaseline ? previous.expenseCents : nil)
        net = FinancialChange(currentCents: current.netCents, previousCents: hasBaseline ? previous.netCents : nil)
    }

    static let empty = ReportComparison(current: .empty, previous: .empty)
}
