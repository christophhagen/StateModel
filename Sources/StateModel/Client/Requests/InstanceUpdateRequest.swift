import Foundation

public struct InstanceUpdateRequest {

    public let instance: InstanceKey

    public let model: ModelKey

    public let timestamp: Date?

    public init(instance: InstanceKey, model: ModelKey, timestamp: Date?) {
        self.instance = instance
        self.model = model
        self.timestamp = timestamp
    }
}

extension InstanceUpdateRequest: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        guard try container.decode(RequestType.self) == .instanceStatus else {
            throw StateError.invalidDataSupplied
        }
        model = try container.decode()
        instance = try container.decode()
        timestamp = try container.decode(Double?.self).map { Date(timeIntervalSince1970: $0) }
    }
}

extension InstanceUpdateRequest: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(RequestType.instanceStatus)
        try container.encode(model)
        try container.encode(instance)
        try container.encode(timestamp?.timeIntervalSince1970)
    }
}
