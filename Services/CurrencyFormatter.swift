import Foundation

final class CurrencyFormatter {
    private let code: String

    init(code: String = "SGD") {
        self.code = code
    }

    func string(for cents: Int) -> String {
        let amount = Decimal(cents) / 100
        return amount.formatted(.currency(code: code))
    }
}
