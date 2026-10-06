import Foundation

final class CurrencyAmountFormatter {
    func cents(from value: String) -> Int? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.range(of: #"^(?:[0-9]+(?:\.[0-9]{0,2})?|\.[0-9]{1,2})$"#, options: .regularExpression) != nil,
              let amount = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")),
              amount * 100 <= Decimal(Int.max) else { return nil }
        return NSDecimalNumber(decimal: amount * 100).intValue
    }

    func inputString(for cents: Int) -> String {
        "\(cents / 100).\(String(format: "%02d", cents % 100))"
    }
}
