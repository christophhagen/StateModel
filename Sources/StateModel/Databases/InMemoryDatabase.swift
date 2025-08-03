import Foundation

/**
 A simple database implementation that only caches the latest values in memory
 */
public final class InMemoryDatabase<ModelKey: ModelKeyType, InstanceKey: InstanceKeyType, PropertyKey: PropertyKeyType>: Database {

    public typealias KeyPath = Path<ModelKey, InstanceKey, PropertyKey>

    public typealias Record = StateModel.Record<ModelKey, InstanceKey, PropertyKey>

    private var cache: [KeyPath: Sample] = [:]

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

    public func get<Value>(_ path: KeyPath) -> Value? where Value: Codable {
        guard let raw = cache[path] else {
            return nil
        }
        return decode(raw.data)
    }

    public func set<Value>(_ value: Value, for path: KeyPath) where Value: Codable {
        let sample = Sample(data: encode(value))
        // TODO: Prevent duplicates?
        cache[path] = sample
        history.append(Record(path: path, sample: sample))
    }

    // MARK: Instances

    public func select<Instance: ModelProtocol>(where predicate: (Instance) -> Bool) -> [Instance] where Instance.Storage == InMemoryDatabase {
        cache.compactMap { (path, value) in
            guard path.model == Instance.modelId,
                  path.property == PropertyKey.instanceId,
                  let status: InstanceStatus = decode(value.data),
                  status == .created else {
                return nil
            }
            let instance = Instance(database: self, id: path.instance)
            guard predicate(instance) else {
                return nil
            }
            return instance
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
