import Foundation

public struct ModelInstanceUpdate {

    public let instance: InstanceKey

    public let properties: [PropertyUpdate]

    public init(instance: InstanceKey, properties: [PropertyUpdate]) {
        self.instance = instance
        self.properties = properties
    }
}

extension ModelInstanceUpdate: Equatable {

}

extension ModelInstanceUpdate: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(instance)
        try container.encode(properties)
    }
}

extension ModelInstanceUpdate: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.instance = try container.decode()
        self.properties = try container.decode()
    }
}
