import Foundation

public struct ModelUpdateRequest {

    public let model: ModelKey

    public let timestamp: Date?

    public let limit: Int

    public let instance: InstanceKey?

    public init(model: ModelKey, timestamp: Date?, limit: Int, instance: InstanceKey?) {
        self.model = model
        self.timestamp = timestamp
        self.limit = limit
        self.instance = instance
    }
}

extension ModelUpdateRequest: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(RequestType.modelUpdate)
        try container.encode(model)
        try container.encode(timestamp?.timeIntervalSince1970)
        try container.encode(limit)
        try container.encode(instance)
    }
}

extension ModelUpdateRequest: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        guard try container.decode(RequestType.self) == .modelUpdate else {
            throw StateError.invalidDataSupplied
        }
        model = try container.decode()
        timestamp = try container.decode(Double?.self).map { Date(timeIntervalSince1970: $0) }
        limit = try container.decode()
        instance = try container.decode()
    }
}
