import Foundation

public struct InstanceStatusRequest {

    public let model: ModelKey

    /// The earliest time for relevant updates
    public let timestamp: Date?

    public init(model: ModelKey, timestamp: Date?) {
        self.model = model
        self.timestamp = timestamp
    }
}

extension InstanceStatusRequest: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(RequestType.instanceStatus)
        try container.encode(model)
        try container.encode(timestamp?.timeIntervalSince1970)
    }
}

extension InstanceStatusRequest: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        guard try container.decode(RequestType.self) == .instanceStatus else {
            throw StateError.invalidDataSupplied
        }
        self.model = try container.decode()
        self.timestamp = try container.decode(Double?.self).map { Date(timeIntervalSince1970: $0) }
    }
}
