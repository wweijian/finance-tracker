import Combine
import Foundation

@MainActor
final class TransactionsController: ObservableObject {
    @Published private(set) var transactions: [TransactionListItem] = []
    @Published private(set) var categories: [String]
    @Published var searchText = ""
    @Published var selectedType: TransactionType?
    @Published var selectedCategory: String?
    @Published var dateFilterMode: TransactionDateFilterMode = .all
    @Published var selectedYear = Calendar.current.component(.year, from: Date())
    @Published var startDate = Calendar.current.date(
        from: DateComponents(year: Calendar.current.component(.year, from: Date()), month: 1, day: 1)
    ) ?? Date()
    @Published var endDate = Date()
    @Published var sortField: TransactionSortField = .date
    @Published var sortsAscending = false
    @Published var includesDeleted = false
    @Published var form: TransactionForm?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let categoryStore: CategoryStore
    private let service: TransactionService
    private let dateFormatter = TransactionDateFormatter()
    private let amountFormatter = CurrencyAmountFormatter()

    init(service: TransactionService, categoryStore: CategoryStore = CategoryStore()) {
        self.service = service
        self.categoryStore = categoryStore
        categories = []
        loadCategories()
    }

    var filteredTransactions: [TransactionListItem] {
        transactions.filter(matchesFilters).sorted(by: compare)
    }

    var availableYears: [Int] {
        let years = transactions.compactMap { Int($0.transactionDate.prefix(4)) }
        return Array(Set(years).union([Calendar.current.component(.year, from: Date())])).sorted(by: >)
    }

    func load() {
        isLoading = true
        errorMessage = nil
        let includesDeleted = includesDeleted

        Task { [service] in
            do {
                let transactions = try await service.transactions(includeDeleted: includesDeleted)
                apply(transactions: transactions)
            } catch {
                apply(error: error)
            }
        }
    }

    func presentNewTransaction() {
        form = TransactionForm(categories: categories)
    }

    func edit(id: String?) {
        guard let id else { return }

        Task { [service] in
            do {
                guard let transaction = try await service.transaction(id: id),
                      let date = dateFormatter.date(from: transaction.transactionDate) else {
                    return
                }
                form = TransactionForm(transaction: transaction, date: date)
            } catch {
                apply(error: error)
            }
        }
    }

    func save(_ form: TransactionForm) {
        guard let amountCents = amountFormatter.cents(from: form.amount) else {
            errorMessage = "Enter a valid non-negative amount."
            return
        }

        guard !form.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "A description is required."
            return
        }

        Task { [service] in
            do {
                let original = try await existingTransaction(for: form, service: service)
                let transaction = makeTransaction(
                    from: form,
                    amountCents: amountCents,
                    original: original
                )
                try await service.save(transaction)
                self.form = nil
                load()
            } catch {
                apply(error: error)
            }
        }
    }

    func softDelete(id: String?) {
        guard let id else { return }

        Task { [service] in
            do {
                try await service.softDelete(id: id)
                load()
            } catch {
                apply(error: error)
            }
        }
    }

    func restore(id: String?) {
        guard let id else { return }

        Task { [service] in
            do {
                try await service.restore(id: id)
                load()
            } catch {
                apply(error: error)
            }
        }
    }

    private func loadCategories() {
        do {
            categories = try categoryStore.categories()
        } catch {
            errorMessage = "Categories could not be loaded: \(error.localizedDescription)"
        }
    }

    private func matchesFilters(_ transaction: TransactionListItem) -> Bool {
        matchesSearch(transaction) && matchesType(transaction) && matchesCategory(transaction) && matchesDate(transaction)
    }

    private func matchesSearch(_ transaction: TransactionListItem) -> Bool {
        guard !searchText.isEmpty else { return true }
        return transaction.description.range(of: searchText, options: .caseInsensitive) != nil ||
            transaction.category.range(of: searchText, options: .caseInsensitive) != nil ||
            transaction.transactionDate.range(of: searchText, options: .caseInsensitive) != nil
    }

    private func matchesType(_ transaction: TransactionListItem) -> Bool {
        selectedType == nil || transaction.transactionType == selectedType
    }

    private func matchesCategory(_ transaction: TransactionListItem) -> Bool {
        selectedCategory == nil || transaction.category == selectedCategory
    }

    private func matchesDate(_ transaction: TransactionListItem) -> Bool {
        switch dateFilterMode {
        case .all:
            return true
        case .year:
            return transaction.transactionDate.hasPrefix(String(selectedYear))
        case .range:
            let start = dateFormatter.string(from: min(startDate, endDate))
            let end = dateFormatter.string(from: max(startDate, endDate))
            return transaction.transactionDate >= start && transaction.transactionDate <= end
        }
    }

    private func compare(_ left: TransactionListItem, _ right: TransactionListItem) -> Bool {
        let order: ComparisonResult
        switch sortField {
        case .date:
            order = left.transactionDate.compare(right.transactionDate)
        case .amount:
            order = left.amountCents == right.amountCents ? .orderedSame : (left.amountCents < right.amountCents ? .orderedAscending : .orderedDescending)
        case .description:
            order = left.description.localizedCompare(right.description)
        case .category:
            order = left.category.localizedCompare(right.category)
        }
        return sortsAscending ? order == .orderedAscending : order == .orderedDescending
    }

    private func apply(transactions: [TransactionListItem]) {
        self.transactions = transactions
        isLoading = false
    }

    private func apply(error: Error) {
        errorMessage = error.localizedDescription
        isLoading = false
    }

    private func existingTransaction(
        for form: TransactionForm,
        service: TransactionService
    ) async throws -> FinanceTransaction? {
        guard let id = form.transactionID else { return nil }
        return try await service.transaction(id: id)
    }

    private func makeTransaction(
        from form: TransactionForm,
        amountCents: Int,
        original: FinanceTransaction?
    ) -> FinanceTransaction {
        let now = ISO8601DateFormatter().string(from: Date())
        return FinanceTransaction(
            id: original?.id ?? UUID().uuidString,
            transactionDate: dateFormatter.string(from: form.date),
            transactionTime: optionalText(form.time),
            transactionYear: Calendar(identifier: .gregorian).component(.year, from: form.date),
            transactionType: form.transactionType,
            amountCents: amountCents,
            currency: original?.currency ?? "SGD",
            description: form.description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: form.category,
            notes: optionalText(form.notes),
            dateCreated: original?.dateCreated ?? now,
            updatedAt: now,
            deletedAt: original?.deletedAt
        )
    }

    private func optionalText(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
