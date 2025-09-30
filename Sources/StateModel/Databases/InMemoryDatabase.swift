import Foundation

/**
 A simple database implementation that only caches the latest values in memory.

 This implementation does not provide a history, see ``InMemoryHistoryDatabase`` for an alternative.
 */
public final class InMemoryDatabase: Database {

    private var cache: [Path: EncodedSample] = [:]

    private var history: [Record] = []

    /**
     Create an empty database.
     */
    public init() { }

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

    public func get<Value: DatabaseValue>(_ path: Path) -> Value? {
        guard let raw = cache[path] else {
            return nil
        }
        return decode(raw.data)
    }

    public func set<Value: DatabaseValue>(_ value: Value, for path: Path) {
        let sample = EncodedSample(data: encode(value))
        // TODO: Prevent duplicates?
        cache[path] = sample
        history.append(Record(path: path, sample: sample))
    }

    // MARK: Instances

    public func all<T>(model: ModelKey, where predicate: (_ instance: InstanceKey, _ status: InstanceStatus) -> T?) -> [T] {
        cache.compactMap { (path, value) -> T? in
            guard path.model == model,
                  path.property == PropertyKey.instanceId,
                  let value: InstanceStatus = decode(value.data) else {
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
