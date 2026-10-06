import Foundation

actor BulkImportService: BulkImportHandling {
    private let amountFormatter = CurrencyAmountFormatter()
    private let dateFormatter = TransactionDateFormatter()
    private let parser = CSVTransactionParser()
    private let repository: any TransactionRepository

    init(repository: any TransactionRepository) {
        self.repository = repository
    }

    func previewFile(at url: URL, kind: CSVImportKind, categories: [String]) throws -> [ImportCandidate] {
        let parsed = try parser.parse(url: url, kind: kind)
        return try validate(parsed.candidates, categories: categories)
    }

    func validate(_ candidates: [ImportCandidate], categories: [String]) throws -> [ImportCandidate] {
        let validated = try candidates.map { try validateCandidate($0, categories: categories) }
        return markFileDuplicates(in: validated)
    }

    func commit(_ candidates: [ImportCandidate], categories: [String]) throws -> BulkImportSummary {
        let approved = try validate(candidates.filter(\.isReady), categories: categories)
        let transactions = try approved.filter(\.isReady).map(makeTransaction)
        let insertedIDs = try repository.insertIfNew(transactions)

        return BulkImportSummary(
            importedTransactionIDs: insertedIDs,
            rejectedCount: candidates.count - insertedIDs.count
        )
    }

    func undo(_ summary: BulkImportSummary) throws {
        try repository.softDelete(ids: summary.importedTransactionIDs)
    }

    private func validateCandidate(_ candidate: ImportCandidate, categories: [String]) throws -> ImportCandidate {
        var candidate = candidate
        guard dateFormatter.date(from: candidate.transactionDate) != nil else {
            candidate.rejectionReason = "Date must use YYYY-MM-DD."
            return candidate
        }
        guard !candidate.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            candidate.rejectionReason = "Description is required."
            return candidate
        }
        guard let amountCents = amountFormatter.cents(from: candidate.amount) else {
            candidate.rejectionReason = "Amount is invalid."
            return candidate
        }
        guard let category = canonicalCategory(candidate.category, categories: categories) else {
            candidate.rejectionReason = "Category is not recognised."
            return candidate
        }
        if try repository.isDuplicate(
            date: candidate.transactionDate,
            amountCents: amountCents,
            description: candidate.description
        ) {
            candidate.rejectionReason = "An identical transaction already exists."
            return candidate
        }
        candidate.category = category
        candidate.rejectionReason = nil
        return candidate
    }

    private func markFileDuplicates(in candidates: [ImportCandidate]) -> [ImportCandidate] {
        var firstRows: [String: Int] = [:]

        return candidates.map { candidate in
            guard candidate.isReady else { return candidate }
            let key = duplicateKey(for: candidate)
            guard let firstRow = firstRows[key] else {
                firstRows[key] = candidate.sourceRow
                return candidate
            }

            var duplicate = candidate
            duplicate.rejectionReason = "Duplicate of row \(firstRow) in this import."
            return duplicate
        }
    }

    private func duplicateKey(for candidate: ImportCandidate) -> String {
        let amountCents = amountFormatter.cents(from: candidate.amount) ?? 0
        return "\(candidate.transactionDate)\u{1F}\(amountCents)\u{1F}\(candidate.description)"
    }

    private func canonicalCategory(_ value: String, categories: [String]) -> String? {
        categories.first { $0.caseInsensitiveCompare(value) == .orderedSame }
    }

    private func makeTransaction(from candidate: ImportCandidate) throws -> FinanceTransaction {
        guard let amountCents = amountFormatter.cents(from: candidate.amount) else { throw BulkImportError.invalidCandidate }
        let now = ISO8601DateFormatter().string(from: Date())
        let remarks = candidate.remarks.trimmingCharacters(in: .whitespacesAndNewlines)
        return FinanceTransaction(
            id: UUID().uuidString,
            transactionDate: candidate.transactionDate,
            transactionYear: Int(candidate.transactionDate.prefix(4)) ?? 0,
            transactionType: candidate.transactionType,
            amountCents: amountCents,
            currency: "SGD",
            description: candidate.description,
            category: candidate.category,
            notes: remarks.isEmpty ? nil : remarks,
            dateCreated: now,
            updatedAt: now,
            deletedAt: nil
        )
    }
}
