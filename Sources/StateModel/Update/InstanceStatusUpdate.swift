import Foundation

public struct InstanceStatusUpdate {

    public let instance: InstanceKey

    public let status: InstanceStatus

    public let date: Date

    init(instance: InstanceKey, status: InstanceStatus, date: Date) {
        self.instance = instance
        self.status = status
        self.date = date
    }
}

extension InstanceStatusUpdate: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(instance)
        try container.encode(status)
        try container.encode(date.timeIntervalSince1970)
    }
}

extension InstanceStatusUpdate: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.instance = try container.decode()
        self.status = try container.decode()
        let timestamp: Double = try container.decode()
        self.date = .init(timeIntervalSince1970: timestamp)
    }
}
