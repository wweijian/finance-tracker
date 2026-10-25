#if DEBUG
import Foundation

struct DevelopmentSampleData {
    func transactions(asOf date: Date, timeZone: TimeZone = .current) -> [FinanceTransaction] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let end = calendar.startOfDay(for: date)
        guard let start = calendar.date(byAdding: .month, value: -3, to: end) else {
            preconditionFailure("The development sample date must support calendar arithmetic.")
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        let timestamp = ISO8601DateFormatter().string(from: date)

        var result: [FinanceTransaction] = []
        var day = start
        var index = 0
        while day <= end {
            let dateText = formatter.string(from: day)
            result.append(transaction(
                date: dateText, category: "Food", description: "Lunch at the hawker centre",
                cents: 480 + index % 8 * 70, timestamp: timestamp
            ))
            if index.isMultiple(of: 3) {
                result.append(transaction(
                    date: dateText, category: "Transport", description: "MRT and bus fares",
                    cents: 240 + index % 5 * 35, timestamp: timestamp
                ))
            }
            if index.isMultiple(of: 7) {
                result.append(transaction(
                    date: dateText, category: "Groceries", description: "Weekly groceries",
                    cents: 6_200 + index % 6 * 410, timestamp: timestamp
                ))
            }
            result.append(contentsOf: monthlyTransactions(
                day: calendar.component(.day, from: day), date: dateText, timestamp: timestamp
            ))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else {
                preconditionFailure("The development sample date must support calendar arithmetic.")
            }
            day = next
            index += 1
        }
        return result
    }

    private func monthlyTransactions(day: Int, date: String, timestamp: String) -> [FinanceTransaction] {
        let entries: [(day: Int, category: String, description: String, cents: Int)] = [
            (1, "Bills & Utilities", "Home utilities", 16_800),
            (4, "Subscription", "Music subscription", 1_098),
            (8, "Shopping", "Home essentials", 8_490),
            (12, "Health", "Pharmacy supplies", 2_680),
            (16, "Entertainment", "Cinema tickets", 3_200),
            (20, "Insurance", "Monthly insurance premium", 18_000),
            (25, "Income", "Monthly salary", 580_000),
            (26, "Investment", "Monthly investment contribution", 70_000),
            (28, "Interest", "Savings account interest", 2_450)
        ]
        return entries.filter { $0.day == day }.map {
            transaction(date: date, category: $0.category, description: $0.description,
                        cents: $0.cents, timestamp: timestamp)
        }
    }

    private func transaction(
        date: String, category: String, description: String, cents: Int, timestamp: String
    ) -> FinanceTransaction {
        let type: TransactionType = ["Income", "Interest"].contains(category) ? .income : .expense
        return FinanceTransaction(
            id: "sample-\(date)-\(category)", transactionDate: date, transactionYear: Int(date.prefix(4))!,
            transactionType: type, amountCents: cents, currency: "SGD", description: "Sample: \(description)",
            category: category, notes: "Fictional development data", dateCreated: timestamp,
            updatedAt: timestamp, deletedAt: nil
        )
    }
}
#endif
