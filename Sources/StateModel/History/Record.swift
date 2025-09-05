import Foundation

/**
 A value of a property at a point in time.

 A record consists of the path identifying the property that was changed,
 the value of the property, and a timestamp of when the change occured.

 Records are generic over the components of the path.
 */
public struct Record<ModelKey: ModelKeyType, InstanceKey: InstanceKeyType, PropertyKey: PropertyKeyType> {

    /// The type of the key path using within the record.
    public typealias KeyPath = Path<ModelKey, InstanceKey, PropertyKey>

    /// The path to the property that was modified
    public let path: KeyPath

    /// The sample containing the information about the modified property
    public let sample: EncodedSample

    /**
     Create a new record.
     - Parameter path: The path to the property that was modified
     - Parameter sample: The sample containing the information about the modified property
     */
    public init(path: KeyPath, sample: EncodedSample) {
        self.path = path
        self.sample = sample
    }

    /**
     Create a new record.
     - Parameter path: The path to the property that was modified
     - Parameter data: The encoded data of the modified property.
     - Parameter timestamp: The time when the property was modified.
     */
    public init(path: KeyPath, data: Data, timestamp: Date = Date()) {
        self.path = path
        self.sample = .init(data: data, timestamp: timestamp)
    }
}

extension Record {

    /// The time when the value was set
    public var timestamp: Date { sample.timestamp }

    /// The encoded value of the record
    public var data: Data { sample.data }
}

extension Record: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(path)
        try container.encode(sample.timestamp.timeIntervalSince1970)
        try container.encode(sample.data)
    }
}

extension Record: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.path = try container.decode()
        let timestamp = try container.decode(Double.self).asTimeIntervalSince1970
        let data = try container.decode(Data.self)
        self.sample = .init(data: data, timestamp: timestamp)
    }
}

extension Record: Comparable {

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.sample, lhs.path) < (rhs.sample, rhs.path)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        (lhs.path, lhs.sample) == (rhs.path, rhs.sample)
    }
}
