import Foundation

public final class InstanceUpdateBuilder: Database {

    private let model: ModelKey

    private let instance: InstanceKey

    private let time: Date?

    private let database: any Database

    private let encoder: any GenericEncoder

    private var properties: [PropertyKey : (date: Date, conversion: (any GenericEncoder) throws -> Data)]

    init(model: ModelKey, instance: InstanceKey, time: Date?, database: any Database, encoder: any GenericEncoder) {
        self.model = model
        self.instance = instance
        self.properties = [:]
        self.time = time
        self.database = database
        self.encoder = encoder
    }

    private func path<P: RawRepresentable>(of property: P) -> Path where P.RawValue == PropertyKey {
        Path(model: model, instance: instance, property: property.rawValue)
    }

    func update() throws -> InstanceUpdate {
        let properties = try properties.map { (key, value) in
            let data = try value.conversion(encoder)
            return PropertyChange(id: key, date: value.date, data: data)
        }
        return .init(model: model, instance: instance, properties: properties)
    }

    // MARK: Database

    public func get<Value>(_ path: Path) -> Value? where Value : Decodable, Value : Encodable {
        guard let time, let database = database as? HistoryDatabase else {
            guard let value = database.get(path, of: Value.self) else {
                return nil
            }
            properties[path.property] = (Date(), { try $0.encode(value) })
            return value
        }

        guard let (value, saved) = database.get(path, at: nil, of: Value.self), saved > time else {
            return nil
        }
        properties[path.property] = (saved, { try $0.encode(value) })
        return value
    }

    public func set<Value>(_ value: Value, for path: Path) where Value : Decodable, Value : Encodable {
        fatalError()
    }

    public func all<T>(model: ModelKey, where predicate: (InstanceKey, InstanceStatus) -> T?) -> [T] {
        fatalError()
    }
}
