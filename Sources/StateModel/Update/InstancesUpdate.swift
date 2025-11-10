import Foundation

public struct InstancesUpdate {

    public let model: ModelKey

    public let updates: [InstanceStatusUpdate]

    init(model: ModelKey, updates: [InstanceStatusUpdate]) {
        self.model = model
        self.updates = updates
    }
}

extension InstancesUpdate: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ClientDataType.instances)
        try container.encode(model)
        try container.encode(updates)
    }
}

extension InstancesUpdate: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        guard try container.decode(ClientDataType.self) == .instances else {
            throw StateError.invalidDataSupplied
        }
        self.model = try container.decode()
        self.updates = try container.decode()
    }
}
