import Foundation

final class CurrencyAmountFormatter {
    func cents(from value: String) -> Int? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Decimal(string: normalized), amount >= 0 else { return nil }
        return NSDecimalNumber(decimal: amount * 100).rounding(
            accordingToBehavior: NSDecimalNumberHandler(
                roundingMode: .plain,
                scale: 0,
                raiseOnExactness: false,
                raiseOnOverflow: true,
                raiseOnUnderflow: true,
                raiseOnDivideByZero: true
            )
        ).intValue
    }

    func inputString(for cents: Int) -> String {
        (Decimal(cents) / 100).formatted(.number.precision(.fractionLength(2)))
    }
}
