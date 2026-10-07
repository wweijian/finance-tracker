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
    @Published var startDateText = ""
    @Published var endDateText = ""
    @Published var minimumAmount = ""
    @Published var maximumAmount = ""
    @Published var remarksFilter: TransactionRemarksFilter = .all
    @Published private(set) var statusFilter: TransactionStatusFilter = .included
    @Published var sortOrder = [KeyPathComparator(\TransactionListItem.transactionDate, order: .reverse)]
    @Published var form: TransactionForm?
    @Published var isShowingBulkImport = false
    @Published private(set) var importCandidates: [ImportCandidate] = []
    @Published var importEditorCandidate: ImportCandidate?
    @Published private(set) var importEditorError: String?
    @Published var importRowRemovalIDs: Set<String> = []
    @Published private var removedImportCandidates: [ImportCandidate] = []
    @Published private(set) var bulkImportSummary: BulkImportSummary?
    @Published private(set) var bulkImportError: String?
    @Published private(set) var importActivity: ImportActivity?
    @Published private(set) var isLoading = false
    @Published private(set) var isMutating = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var dataRevision = 0

    private let categoryStore: CategoryStore
    private let bulkImportService: any BulkImportHandling
    private let service: any TransactionServing
    private var loadRequestID = UUID()
    private let dateFormatter = TransactionDateFormatter()
    private let amountFormatter = CurrencyAmountFormatter()

    init(
        service: any TransactionServing,
        bulkImportService: any BulkImportHandling,
        categoryStore: CategoryStore = CategoryStore()
    ) {
        self.service = service
        self.bulkImportService = bulkImportService
        self.categoryStore = categoryStore
        categories = []
        loadCategories()
    }

    var filteredTransactions: [TransactionListItem] {
        guard filterErrorMessage == nil else { return [] }
        return transactions.filter(matchesFilters).sorted(using: sortOrder + [KeyPathComparator(\TransactionListItem.id)])
    }

    var includesExcluded: Bool { statusFilter != .included }

    var additionalFilterCount: Int {
        [!minimumAmount.isEmpty, !maximumAmount.isEmpty, remarksFilter != .all, statusFilter != .included]
            .filter { $0 }.count
    }

    var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedType != nil || selectedCategory != nil || dateFilterMode != .all || additionalFilterCount > 0
    }

    var filterErrorMessage: String? {
        dateFilterError ?? amountFilterError
    }

    func selectStatus(_ status: TransactionStatusFilter) {
        guard status != statusFilter else { return }
        let previouslyIncludedExcluded = includesExcluded
        statusFilter = status
        if previouslyIncludedExcluded != includesExcluded { load() }
    }

    func clearFilters() {
        searchText = ""
        selectedType = nil
        selectedCategory = nil
        dateFilterMode = .all
        startDateText = ""
        endDateText = ""
        minimumAmount = ""
        maximumAmount = ""
        remarksFilter = .all
        selectStatus(.included)
    }

    var isImporting: Bool { importActivity != nil }
    var importPreview: ImportPreview { ImportPreview(candidates: importCandidates) }
    var removedImportRowCount: Int { removedImportCandidates.count }

    var availableYears: [Int] {
        let years = transactions.compactMap { Int($0.transactionDate.prefix(4)) }
        return Array(Set(years).union([Calendar.current.component(.year, from: Date())])).sorted(by: >)
    }

    func load() {
        let id = UUID()
        loadRequestID = id
        isLoading = true
        errorMessage = nil
        let includesDeleted = includesExcluded

        Task { [service] in
            do {
                let transactions = try await service.transactions(includeDeleted: includesDeleted)
                guard loadRequestID == id else { return }
                apply(transactions: transactions)
            } catch {
                guard loadRequestID == id else { return }
                apply(error: error)
            }
        }
    }

    func presentNewTransaction() {
        errorMessage = nil
        form = TransactionForm(categories: categories)
    }

    func resetAfterDatabaseRestore() {
        form = nil
        isShowingBulkImport = false
        cancelBulkImport()
        transactions = []
        load()
    }

    func presentBulkImport() {
        guard !isImporting else { return }
        cancelBulkImport()
        isShowingBulkImport = true
    }

    func cancelBulkImport() {
        guard !isImporting else { return }
        importRowRemovalIDs = []
        importEditorCandidate = nil
        importEditorError = nil
        bulkImportSummary = nil
        bulkImportError = nil
        importCandidates = []
        removedImportCandidates = []
    }

    func previewCSV(at url: URL, kind: CSVImportKind) {
        guard !isImporting else { return }
        importRowRemovalIDs = []
        importEditorCandidate = nil
        importEditorError = nil
        importActivity = .readingFile
        importCandidates = []
        removedImportCandidates = []
        bulkImportSummary = nil
        errorMessage = nil
        bulkImportError = nil
        let categories = categories

        Task { [bulkImportService] in
            do {
                importCandidates = try await bulkImportService.previewFile(
                    at: url,
                    kind: kind,
                    categories: categories
                )
                importActivity = nil
            } catch {
                importActivity = nil
                bulkImportError = error.localizedDescription
            }
        }
    }

    func revalidate(_ candidate: ImportCandidate) {
        guard !isImporting, bulkImportSummary == nil else { return }
        var candidates = importCandidates
        guard let index = candidates.firstIndex(where: { $0.id == candidate.id }) else { return }
        candidates[index] = candidate
        validateImportCandidates(candidates)
    }

    func editImportCandidate(id: String) {
        guard !isImporting, bulkImportSummary == nil, importRowRemovalIDs.isEmpty,
              let candidate = importCandidates.first(where: { $0.id == id }) else { return }
        importEditorError = nil
        importEditorCandidate = candidate
    }

    func saveImportCandidate(_ candidate: ImportCandidate) {
        guard !isImporting, bulkImportSummary == nil, importRowRemovalIDs.isEmpty, importEditorCandidate?.id == candidate.id,
              let index = importCandidates.firstIndex(where: { $0.id == candidate.id }) else { return }
        var candidates = importCandidates
        candidates[index] = candidate
        importActivity = .validatingRows
        importEditorError = nil

        Task { [bulkImportService] in
            defer { importActivity = nil }
            do {
                let validated = try await bulkImportService.validate(candidates, categories: categories)
                guard let edited = validated.first(where: { $0.id == candidate.id }) else { return }
                guard edited.isReady else {
                    importEditorError = edited.rejectionReason
                    return
                }
                importCandidates = validated
                importEditorCandidate = nil
            } catch {
                importEditorError = error.localizedDescription
            }
        }
    }

    func requestImportRowRemoval(_ ids: Set<String>) {
        guard !isImporting, bulkImportSummary == nil, importRowRemovalIDs.isEmpty else { return }
        importRowRemovalIDs = ids.intersection(importCandidates.map(\.id))
    }

    func confirmImportRowRemoval(_ ids: Set<String>) {
        guard !isImporting, bulkImportSummary == nil else { return }
        importRowRemovalIDs = []
        removeImportRows(ids)
    }

    func removeImportRows(_ ids: Set<String>) {
        guard !isImporting, bulkImportSummary == nil else { return }
        let removed = importCandidates.filter { ids.contains($0.id) }
        guard !removed.isEmpty else { return }
        if let candidate = importEditorCandidate, ids.contains(candidate.id) {
            importEditorCandidate = nil
            importEditorError = nil
        }
        removedImportCandidates.append(contentsOf: removed)
        let remaining = importCandidates.filter { !ids.contains($0.id) }
        importCandidates = remaining
        validateImportCandidates(remaining)
    }

    func undoImportRowRemovals() {
        guard !isImporting, bulkImportSummary == nil, importRowRemovalIDs.isEmpty, !removedImportCandidates.isEmpty else { return }
        let candidates = (importCandidates + removedImportCandidates).sorted { $0.sourceRow < $1.sourceRow }
        removedImportCandidates = []
        importCandidates = candidates
        validateImportCandidates(candidates)
    }

    private func validateImportCandidates(_ candidates: [ImportCandidate]) {
        importActivity = .validatingRows
        bulkImportError = nil

        Task { [bulkImportService] in
            do {
                importCandidates = try await bulkImportService.validate(candidates, categories: categories)
                importActivity = nil
            } catch {
                importActivity = nil
                bulkImportError = error.localizedDescription
            }
        }
    }

    func commitBulkImport() {
        guard !isImporting, bulkImportSummary == nil, importRowRemovalIDs.isEmpty,
              importEditorCandidate == nil, importPreview.readyCount > 0 else { return }
        commit(candidates: importCandidates)
    }

    func undoBulkImport() {
        guard !isImporting, let summary = bulkImportSummary,
              summary.acceptedCount > 0 else { return }
        importActivity = .undoingImport
        bulkImportError = nil

        Task { [bulkImportService] in
            do {
                try await bulkImportService.undo(summary)
                importActivity = nil
                cancelBulkImport()
                isShowingBulkImport = false
                didChangeTransactions()
            } catch {
                importActivity = nil
                bulkImportError = error.localizedDescription
            }
        }
    }

    private func commit(candidates: [ImportCandidate]) {
        importActivity = .importingRows
        bulkImportError = nil
        Task { [bulkImportService] in
            do {
                bulkImportSummary = try await bulkImportService.commit(candidates, categories: categories)
                importCandidates = []
                removedImportCandidates = []
                importActivity = nil
                didChangeTransactions()
            } catch {
                importActivity = nil
                bulkImportError = error.localizedDescription
            }
        }
    }

    func edit(id: String?) {
        guard let id else { return }
        errorMessage = nil

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
        guard !isMutating else { return }
        errorMessage = nil
        guard let amountCents = amountFormatter.cents(from: form.amount) else {
            errorMessage = "Enter a valid non-negative amount."
            return
        }

        guard !form.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "A description is required."
            return
        }

        isMutating = true
        Task { [service] in
            defer { isMutating = false }
            do {
                let original = try await existingTransaction(for: form, service: service)
                let transaction = makeTransaction(
                    from: form,
                    amountCents: amountCents,
                    original: original
                )
                try await service.save(transaction)
                self.form = nil
                didChangeTransactions()
            } catch {
                apply(error: error)
            }
        }
    }

    func exclude(id: String?) {
        guard let id, !isMutating else { return }
        isMutating = true

        Task { [service] in
            defer { isMutating = false }
            do {
                try await service.softDelete(id: id)
                if form?.transactionID == id { form = nil }
                didChangeTransactions()
            } catch {
                apply(error: error)
            }
        }
    }

    func include(id: String?) {
        guard let id, !isMutating else { return }
        isMutating = true

        Task { [service] in
            defer { isMutating = false }
            do {
                try await service.restore(id: id)
                if form?.transactionID == id { form = nil }
                didChangeTransactions()
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
        matchesSearch(transaction) && matchesType(transaction) && matchesCategory(transaction) &&
            matchesDate(transaction) && matchesAmount(transaction) && matchesRemarks(transaction) && matchesStatus(transaction)
    }

    private func matchesSearch(_ transaction: TransactionListItem) -> Bool {
        guard !searchText.isEmpty else { return true }
        return [transaction.description, transaction.category, transaction.transactionDate, transaction.remarks]
            .contains { $0.localizedCaseInsensitiveContains(searchText) }
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
            return (startDateText.isEmpty || transaction.transactionDate >= startDateText) &&
                (endDateText.isEmpty || transaction.transactionDate <= endDateText)
        }
    }

    private func matchesAmount(_ transaction: TransactionListItem) -> Bool {
        let minimum = amountFormatter.cents(from: minimumAmount)
        let maximum = amountFormatter.cents(from: maximumAmount)
        return (minimum.map { transaction.amountCents >= $0 } ?? true) &&
            (maximum.map { transaction.amountCents <= $0 } ?? true)
    }

    private func matchesRemarks(_ transaction: TransactionListItem) -> Bool {
        let hasRemarks = !transaction.remarks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch remarksFilter {
        case .all: return true
        case .withRemarks: return hasRemarks
        case .withoutRemarks: return !hasRemarks
        }
    }

    private func matchesStatus(_ transaction: TransactionListItem) -> Bool {
        switch statusFilter {
        case .included: return !transaction.isExcluded
        case .excluded: return transaction.isExcluded
        case .all: return true
        }
    }

    private var dateFilterError: String? {
        guard dateFilterMode == .range else { return nil }
        if !startDateText.isEmpty && dateFormatter.date(from: startDateText) == nil {
            return "Enter the From date as YYYY-MM-DD, for example 2026-05-01."
        }
        if !endDateText.isEmpty && dateFormatter.date(from: endDateText) == nil {
            return "Enter the Through date as YYYY-MM-DD, for example 2026-05-31."
        }
        if !startDateText.isEmpty && !endDateText.isEmpty && startDateText > endDateText {
            return "The From date must be on or before the Through date."
        }
        return nil
    }

    private var amountFilterError: String? {
        let minimum = amountFormatter.cents(from: minimumAmount)
        let maximum = amountFormatter.cents(from: maximumAmount)
        if !minimumAmount.isEmpty && minimum == nil { return "Enter a valid non-negative minimum amount with at most two decimal places." }
        if !maximumAmount.isEmpty && maximum == nil { return "Enter a valid non-negative maximum amount with at most two decimal places." }
        if let minimum, let maximum, minimum > maximum { return "The minimum amount must not exceed the maximum amount." }
        return nil
    }

    private func apply(transactions: [TransactionListItem]) {
        self.transactions = transactions
        isLoading = false
    }

    private func didChangeTransactions() {
        dataRevision += 1
        load()
    }

    private func apply(error: Error) {
        errorMessage = error.localizedDescription
        isLoading = false
    }

    private func existingTransaction(
        for form: TransactionForm,
        service: any TransactionServing
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
