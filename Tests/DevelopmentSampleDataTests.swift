#if DEBUG
import Foundation
import Testing
@testable import FinanceApp

struct DevelopmentSampleDataTests {
    @Test(arguments: [
        ("2026-10-25", "2026-07-25"),
        ("2027-01-10", "2026-10-10"),
        ("2028-05-31", "2028-02-29")
    ])
    func sampleDatesFollowTheRunDate(end: String, start: String) throws {
        let date = try #require(TransactionDateFormatter().date(from: end))
        let samples = DevelopmentSampleData().transactions(asOf: date, timeZone: TimeZone(secondsFromGMT: 0)!)
        let categories = try CategoryStore().categories()

        #expect(samples.first?.transactionDate == start)
        #expect(samples.last?.transactionDate == end)
        #expect(samples.allSatisfy { $0.transactionDate >= start && $0.transactionDate <= end })
        #expect(samples.allSatisfy { $0.transactionYear == Int($0.transactionDate.prefix(4)) })
        #expect(samples.allSatisfy { categories.contains($0.category) && $0.amountCents > 0 && $0.currency == "SGD" })
        #expect(Set(samples.map(\.id)).count == samples.count)
        #expect(samples.contains { $0.transactionType == .income })
        #expect(samples.contains { $0.transactionType == .expense })
    }

    @Test func samplesUseTheLocalRunDayRatherThanTheUTCDate() throws {
        let now = try #require(ISO8601DateFormatter().date(from: "2026-10-25T18:00:00Z"))
        let samples = DevelopmentSampleData().transactions(asOf: now, timeZone: TimeZone(secondsFromGMT: 8 * 3_600)!)
        #expect(samples.first?.transactionDate == "2026-07-26")
        #expect(samples.last?.transactionDate == "2026-10-26")
        #expect(samples.allSatisfy { $0.dateCreated == "2026-10-25T18:00:00Z" })
    }

    @Test func repeatedSetupPreservesExistingTransactions() throws {
        let store = try SQLiteTestStore()
        let now = try #require(TransactionDateFormatter().date(from: "2026-10-25"))
        let samples = DevelopmentSampleData().transactions(asOf: now, timeZone: TimeZone(secondsFromGMT: 0)!)
        #expect(try store.repository.insertIfNew(samples).count == samples.count)

        var edited = try #require(samples.first)
        edited.notes = "Keep my development edits"
        try store.repository.save(edited)
        #expect(try store.repository.insertIfNew(samples).isEmpty)
        #expect(try store.repository.transactions(includeDeleted: true).count == samples.count)
        #expect(try store.repository.transaction(id: edited.id)?.notes == edited.notes)
    }

    @Test func ordinaryLaunchDoesNotSetUpSampleData() throws {
        #expect(try !DevelopmentDataCommand.run(arguments: ["Finance"]))
    }
}
#endif
