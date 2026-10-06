import Foundation
import GRDB

enum TransactionType: String, Codable, CaseIterable, DatabaseValueConvertible, Sendable {
    case income
    case expense
}
