import Foundation

public struct InstanceUpdate {

    public let model: ModelKey

    public let instance: InstanceKey

    public let properties: [PropertyChange]

    public init(model: ModelKey, instance: InstanceKey, properties: [PropertyChange]) {
        self.model = model
        self.instance = instance
        self.properties = properties
    }
}

extension InstanceUpdate: Equatable {

}

extension InstanceUpdate: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ClientDataType.instance)
        try container.encode(model)
        try container.encode(instance)
        try container.encode(properties)
    }
}

extension InstanceUpdate: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        guard try container.decode(ClientDataType.self) == .instance else {
            throw StateError.invalidDataSupplied
        }
        self.model = try container.decode()
        self.instance = try container.decode()
        self.properties = try container.decode()
    }
}
