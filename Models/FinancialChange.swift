import Foundation

struct FinancialChange: Sendable, Equatable {
    let currentCents: Int
    let previousCents: Int?

    var differenceCents: Int? { previousCents.map { currentCents - $0 } }

    // Use the magnitude of a negative net baseline so improvements are positive.
    var percentage: Decimal? {
        guard let previousCents, previousCents != 0 else { return nil }
        return Decimal(currentCents - previousCents) / Decimal(previousCents).magnitude * 100
    }

    var description: String {
        guard previousCents != nil else { return "No prior data" }
        guard let percentage else { return currentCents == 0 ? "No change" : "From zero" }
        let number = percentage.formatted(.number.precision(.fractionLength(1)))
        return "\(percentage > 0 ? "+" : "")\(number)%"
    }
}
