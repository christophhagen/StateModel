import Foundation

public struct InstanceUpdate {

    public let model: ModelKey

    public let instance: InstanceKey

    public let properties: [PropertyUpdate]

    public let failedProperties: [PropertyKey]

    public init(
        model: ModelKey,
        instance: InstanceKey,
        properties: [PropertyUpdate] = [],
        failedProperties: [PropertyKey] = []
    ) {
        self.model = model
        self.instance = instance
        self.properties = properties
        self.failedProperties = failedProperties
    }
}

extension InstanceUpdate: Equatable {

}

extension InstanceUpdate: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(TransmissionDataType.instance)
        try container.encode(model)
        try container.encode(instance)
        try container.encode(properties)
        try container.encode(failedProperties)
    }
}

extension InstanceUpdate: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        guard try container.decode(TransmissionDataType.self) == .instance else {
            throw StateError.invalidDataSupplied
        }
        model = try container.decode()
        instance = try container.decode()
        properties = try container.decode()
        failedProperties = try container.decode()
    }
}
