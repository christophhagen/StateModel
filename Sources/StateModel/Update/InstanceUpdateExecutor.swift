import Foundation

public struct InstanceUpdateExecutor {

    private let model: ModelKey

    private let instance: InstanceKey

    private let properties: [PropertyUpdate]

    private let decoder: any GenericDecoder

    private let database: any Database

    init(model: ModelKey,
         instance: InstanceKey,
         properties: [PropertyUpdate],
         decoder: any GenericDecoder,
         database: any Database
    ) {
        self.model = model
        self.instance = instance
        self.properties = properties
        self.decoder = decoder
        self.database = database
    }

    public func update<P: RawRepresentable, T: DatabaseValue>(_ property: P, of type: T.Type) throws(StateError) where P.RawValue == PropertyKey {
        try set(T.self, for: property.rawValue)
    }

    public func update<P: RawRepresentable, M: ModelProtocol>(_ property: P, of type: M?.Type) throws(StateError) where P.RawValue == PropertyKey {
        try set(Int?.self, for: property.rawValue)
    }

    public func update<P: RawRepresentable, S: SequenceInitializable>(_ property: P, of type: S.Type) throws(StateError) where P.RawValue == PropertyKey {
        try set([Int].self, for: property.rawValue)
    }

    public func updateStatus() throws(StateError) {
        try set(InstanceStatus.self, for: PropertyKey.instanceId)
    }

    private func decode<D: Decodable>(_ type: D.Type = D.self, for property: PropertyKey) throws(StateError) -> (date: Date, value: D)? {
        guard let update = properties.first(where: { $0.id == property }) else {
            return nil
        }
        do {
            let value = try decoder.decode(D.self, from: update.data)
            return (update.date, value)
        } catch {
            throw StateError.propertyDecodingFailed(property: property, error: error.localizedDescription)
        }
    }

    private func set<D: DatabaseValue>(_ type: D.Type, for property: PropertyKey) throws(StateError) {
        guard let (date, value) = try decode(D.self, for: property) else {
            return
        }
        if let database = database as? HistoryDatabase {
            database.set(value, model: model, instance: instance, property: property, at: date)
        } else {
            database.set(value, model: model, instance: instance, property: property)
        }
    }

}
