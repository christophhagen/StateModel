import Foundation

/**
 An encoded value of a property at a point in time.

 A sample can be used to record changes to properties over time,
 and to store the current state of a key path.
 */
public struct EncodedSample {

    /// The encoded value of the sample
    public let data: Data

    /// The time when the value was set
    public let timestamp: Date

    /**
     Create a new sample.
     - Parameter data: The encoded data of the modified property.
     - Parameter timestamp: The time when the property was modified. Defaults to the current time.
     */
    public init(data: Data, timestamp: Date? = nil) {
        self.data = data
        self.timestamp = timestamp ?? Date()
    }
}

extension EncodedSample: Sendable {
    
}

extension EncodedSample: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(timestamp.timeIntervalSince1970)
        try container.encode(data)
    }
}

extension EncodedSample: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.timestamp = try container.decode(Double.self).asTimeIntervalSince1970
        self.data = try container.decode(Data.self)
    }
}

extension EncodedSample: CustomStringConvertible {

    public var description: String {
        if #available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
            return "[\(timestamp.formatted())] \(data)"
        }
        return "[\(timestamp)] \(data)"
    }
}

extension EncodedSample: Comparable {

    public static func < (lhs: EncodedSample, rhs: EncodedSample) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
}

extension EncodedSample: Equatable {

    public static func == (lhs: EncodedSample, rhs: EncodedSample) -> Bool {
        lhs.timestamp == rhs.timestamp &&
        lhs.data == rhs.data
    }
}
