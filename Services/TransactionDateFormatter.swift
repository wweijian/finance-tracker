import Foundation

final class TransactionDateFormatter {
    private let formatter: DateFormatter

    init() {
        formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
    }

    func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    func date(from string: String) -> Date? {
        formatter.date(from: string)
    }
}
