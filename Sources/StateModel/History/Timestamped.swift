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
