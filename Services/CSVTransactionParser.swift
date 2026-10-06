import Foundation

struct CSVTransactionParser: Sendable {
    func parse(url: URL, kind: CSVImportKind) throws -> CSVImportParseResult {
        let hasSecurityScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let text = try String(contentsOf: url, encoding: .utf8)
        let rows = parseRows(text)
        guard let headerIndex = rows.firstIndex(where: { isHeader($0, for: kind) }) else {
            throw CSVTransactionParserError.unsupportedHeader(
                kind,
                foundHeader: candidateHeader(in: rows)
            )
        }

        let headers = headerMap(for: rows[headerIndex])
        return parseTransactions(
            rows: rows.dropFirst(headerIndex + 1),
            kind: kind,
            headers: headers,
            firstSourceRow: headerIndex + 2
        )
    }

    private func isHeader(_ row: [String], for kind: CSVImportKind) -> Bool {
        let headers = row.map(normalize)
        let optionalHeaders = headers.filter { $0 == "remarks" || $0 == "notes" }
        let requiredHeaders = headers.filter { $0 != "remarks" && $0 != "notes" }
        return optionalHeaders.count <= 1 && requiredHeaders == expectedHeaders(for: kind).map(normalize)
    }

    private func expectedHeaders(for kind: CSVImportKind) -> [String] {
        switch kind {
        case .debit:
            return [
                "Transaction Date",
                "Transaction Code",
                "Description",
                "Transaction Ref1",
                "Transaction Ref2",
                "Transaction Ref3",
                "Status",
                "Debit Amount",
                "Credit Amount",
                "Category"
            ]
        case .credit:
            return [
                "Transaction Date",
                "Transaction Posting Date",
                "Transaction Description",
                "Transaction Type",
                "Payment Type",
                "Transaction Status",
                "Debit Amount",
                "Credit Amount",
                "Category"
            ]
        }
    }

    private func headerMap(for row: [String]) -> [String: Int] {
        Dictionary(uniqueKeysWithValues: row.enumerated().map { (normalize($0.element), $0.offset) })
    }

    private func candidateHeader(in rows: [[String]]) -> String? {
        guard let row = rows.first(where: { row in
            row.contains { normalize($0) == "transaction date" }
        }) else {
            return nil
        }

        let preview = row.prefix(12).joined(separator: " | ")
        return row.count > 12 ? "\(preview) | … (\(row.count) columns found)" : preview
    }

    private func parseTransactions(
        rows: ArraySlice<[String]>,
        kind: CSVImportKind,
        headers: [String: Int],
        firstSourceRow: Int
    ) -> CSVImportParseResult {
        var candidates: [ImportCandidate] = []

        for (offset, row) in rows.enumerated() {
            guard !row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
                continue
            }

            candidates.append(parseCandidate(
                row,
                sourceRow: firstSourceRow + offset,
                kind: kind,
                headers: headers
            ))
        }

        return CSVImportParseResult(candidates: candidates)
    }

    private func parseCandidate(
        _ row: [String],
        sourceRow: Int,
        kind: CSVImportKind,
        headers: [String: Int]
    ) -> ImportCandidate {
        let dateText = value(named: ["transaction date", "date"], in: row, headers: headers)
        let description = value(named: [descriptionColumn(for: kind)], in: row, headers: headers)
        let debit = value(named: ["debit amount"], in: row, headers: headers)
        let credit = value(named: ["credit amount"], in: row, headers: headers)
        let categoryText = value(named: ["category"], in: row, headers: headers)
        let amountDetails = importAmount(debit: debit, credit: credit)

        return ImportCandidate(
            id: UUID().uuidString,
            sourceRow: sourceRow,
            transactionDate: normalizedDate(dateText),
            transactionType: amountDetails.type,
            amount: amountDetails.value,
            description: description,
            category: categoryText,
            rejectionReason: nil,
            remarks: value(named: ["remarks", "notes"], in: row, headers: headers)
        )
    }

    private func value(named names: [String], in row: [String], headers: [String: Int]) -> String {
        for name in names {
            if let index = headers[name], row.indices.contains(index) {
                return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ""
    }

    private func descriptionColumn(for kind: CSVImportKind) -> String {
        switch kind {
        case .debit:
            return "description"
        case .credit:
            return "transaction description"
        }
    }

    private func importAmount(debit: String, credit: String) -> (type: TransactionType, value: String) {
        if !debit.isEmpty { return (.expense, debit) }
        if !credit.isEmpty { return (.income, credit) }
        return (.expense, "")
    }

    private func parseDate(_ value: String) -> Date? {
        let formats = ["dd MMM yyyy", "d MMM yyyy", "yyyy-MM-dd", "dd/MM/yyyy"]
        for format in formats {
            if let date = dateFormatter(for: format).date(from: value) {
                return date
            }
        }
        return nil
    }

    private func normalizedDate(_ value: String) -> String {
        guard let date = parseDate(value) else { return value }
        return TransactionDateFormatter().string(from: date)
    }

    private func dateFormatter(for format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter
    }

    private func normalize(_ header: String) -> String {
        header.replacingOccurrences(of: "\u{FEFF}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func parseRows(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isQuoted = false
        let characters = Array(text)
        var index = 0

        while index < characters.count {
            let character = characters[index]
            if character == "\"" {
                if isQuoted && index + 1 < characters.count && characters[index + 1] == "\"" {
                    field.append(character)
                    index += 1
                } else {
                    isQuoted.toggle()
                }
            } else if character == "," && !isQuoted {
                row.append(field)
                field = ""
            } else if character.isNewline && !isQuoted {
                if character == "\r" && index + 1 < characters.count && characters[index + 1] == "\n" {
                    index += 1
                }
                row.append(field)
                rows.append(row)
                row = []
                field = ""
            } else {
                field.append(character)
            }
            index += 1
        }

        if !row.isEmpty || !field.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows
    }
}
