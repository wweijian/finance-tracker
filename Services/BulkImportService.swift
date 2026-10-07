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
        let importedIDs = try repository.insertIfNew(transactions)

        return BulkImportSummary(
            importedTransactionIDs: importedIDs,
            rejectedCount: candidates.count - importedIDs.count
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
        if let reason = try ledgerlyRejectionReason(for: candidate, amountCents: amountCents) {
            candidate.rejectionReason = reason
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

    private func ledgerlyRejectionReason(for candidate: ImportCandidate, amountCents: Int) throws -> String? {
        guard let details = candidate.ledgerlyDetails else { return nil }
        guard !details.transactionID.isEmpty else { return "Transaction ID is required." }
        guard TransactionType(rawValue: details.transactionType) == candidate.transactionType else {
            return "Transaction type must be income or expense."
        }
        guard details.currency.range(of: "^[A-Z]{3}$", options: .regularExpression) != nil else {
            return "Currency must be a three-letter uppercase code."
        }
        if let deletedAt = details.deletedAt, !isUTCTimestamp(deletedAt) {
            return "Deleted status must be blank or a valid UTC timestamp."
        }
        if let existing = try repository.transaction(id: details.transactionID) {
            guard existing.transactionDate == candidate.transactionDate,
                  existing.amountCents == amountCents,
                  existing.description == candidate.description else {
                return "Transaction ID belongs to a different existing transaction."
            }
            if existing.deletedAt != nil && details.deletedAt != nil {
                return "An identical deleted transaction already exists."
            }
        }
        return nil
    }

    private func isUTCTimestamp(_ value: String) -> Bool {
        guard value.hasSuffix("Z") || value.hasSuffix("+00:00") else { return false }
        let formatter = ISO8601DateFormatter()
        if formatter.date(from: value) != nil { return true }
        formatter.formatOptions.insert(.withFractionalSeconds)
        return formatter.date(from: value) != nil
    }

    private func markFileDuplicates(in candidates: [ImportCandidate]) -> [ImportCandidate] {
        var firstRows: [String: Int] = [:]
        var firstIDRows: [String: Int] = [:]

        return candidates.map { candidate in
            guard candidate.isReady else { return candidate }
            let key = duplicateKey(for: candidate)
            if let transactionID = candidate.ledgerlyDetails?.transactionID,
               let firstRow = firstIDRows[transactionID] {
                var duplicate = candidate
                duplicate.rejectionReason = "Transaction ID is repeated from row \(firstRow) in this import."
                return duplicate
            }
            guard let firstRow = firstRows[key] else {
                firstRows[key] = candidate.sourceRow
                if let transactionID = candidate.ledgerlyDetails?.transactionID {
                    firstIDRows[transactionID] = candidate.sourceRow
                }
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
        let remarks = candidate.ledgerlyDetails == nil
            ? candidate.remarks.trimmingCharacters(in: .whitespacesAndNewlines)
            : candidate.remarks
        return FinanceTransaction(
            id: candidate.ledgerlyDetails?.transactionID ?? UUID().uuidString,
            transactionDate: candidate.transactionDate,
            transactionYear: Int(candidate.transactionDate.prefix(4)) ?? 0,
            transactionType: candidate.transactionType,
            amountCents: amountCents,
            currency: candidate.currency,
            description: candidate.description,
            category: candidate.category,
            notes: remarks.isEmpty ? nil : remarks,
            dateCreated: now,
            updatedAt: now,
            deletedAt: candidate.ledgerlyDetails?.deletedAt
        )
    }
}
