import Foundation

/// A value with a timestamp
public struct Timestamped<Value> {

    public let value: Value

    public let date: Date

    public init(value: Value, date: Date) {
        self.value = value
        self.date = date
    }
}

extension Timestamped: Codable where Value: Codable {

}

extension Timestamped: Equatable where Value: Equatable {

}

extension Timestamped: Hashable where Value: Hashable {

}

extension Timestamped: CustomStringConvertible where Value: CustomStringConvertible {

    public var description: String {
        "Timestamped(value: \(value), date: \(date))"
    }
}
