import Foundation

public struct PropertyUpdate {

    public let id: PropertyKey

    public let date: Date

    public let data: Data

    public init(id: PropertyKey, date: Date, data: Data) {
        self.id = id
        self.date = date
        self.data = data
    }

    public init<P: RawRepresentable>(id: P, date: Date, data: Data) where P.RawValue == PropertyKey {
        self.init(id: id.rawValue, date: date, data: data)
    }
}

extension PropertyUpdate: Equatable {

}

extension PropertyUpdate: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(id)
        try container.encode(date.timeIntervalSince1970)
        try container.encode(data)
    }
}

extension PropertyUpdate: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.id = try container.decode()
        let timestamp: Double = try container.decode()
        self.date = .init(timeIntervalSince1970: timestamp)
        self.data = try container.decode()
    }
}
