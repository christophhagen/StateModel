import Foundation

/**
 A simple database implementation that only caches the latest values in memory
 */
public final class InMemoryDatabase<ModelKey: ModelKeyType, InstanceKey: InstanceKeyType, PropertyKey: PropertyKeyType>: Database {

    public typealias KeyPath = Path<ModelKey, InstanceKey, PropertyKey>

    public typealias Record = StateModel.Record<ModelKey, InstanceKey, PropertyKey>

    private var cache: [KeyPath: EncodedSample] = [:]

    private var history: [Record] = []

    // MARK: Encoding

    private let encoder: JSONEncoder = .init()

    private let decoder: JSONDecoder = .init()

    private func encode<T>(_ value: T) -> Data where T: Encodable {
        try! encoder.encode(value)
    }

    private func decode<T>(_ data: Data) -> T? where T: Decodable {
        try? decoder.decode(T.self, from: data)
    }

    // MARK: Properties

    public func get<Value>(model: ModelKey, instance: InstanceKey, property: PropertyKey) -> Value? where Value: Codable {
        let path = Path(model: model, instance: instance, property: property)
        guard let raw = cache[path] else {
            return nil
        }
        return decode(raw.data)
    }

    public func set<Value>(_ value: Value, model: ModelKey, instance: InstanceKey, property: PropertyKey) where Value: Codable {
        let sample = EncodedSample(data: encode(value))
        // TODO: Prevent duplicates?
        let path = Path(model: model, instance: instance, property: property)
        cache[path] = sample
        history.append(Record(path: path, sample: sample))
    }

    // MARK: Instances

    public func select<T, V>(model: ModelKey, property: PropertyKey, where predicate: (_ instanceId: InstanceKey, _ value: V) -> T?) -> [T] where V: Decodable {
        cache.compactMap { (path, value) -> T? in
            guard path.model == model,
                  path.property == property,
                  let value: V = decode(value.data) else {
                return nil
            }
            return predicate(path.instance, value)
        }
    }

    // MARK: Change tracking

    public func getHistory(until date: Date = .distantPast) -> [Record] {
        let index = history.firstIndex(where: { $0.timestamp > date }) ?? history.endIndex
        return Array(history[index...])
    }

    public func getEncodedHistory(until date: Date = .distantPast) -> Data {
        encode(getHistory(until: date))
    }

    public func insert(records: Data) -> Bool {
        guard let modifications: [Record] = decode(records) else {
            return false
        }

        for record in modifications {
            insert(record)
        }

        // TODO: Combine history more efficiently
        history = (modifications + history).sorted()

        return true
    }

    private func insert(_ record: Record) {
        if let current = cache[record.path], current.timestamp > record.timestamp {
            return
        }
        cache[record.path] = record.sample
    }
}
