enum DashboardPage: String, CaseIterable, Identifiable {
    case spending = "Spending"
    case categories = "Categories"
    case distribution = "Spending distribution"
    case cashFlow = "Cash flow"
    case balance = "Net balance"
    case transactions = "Transactions"

    var id: String { rawValue }

}
