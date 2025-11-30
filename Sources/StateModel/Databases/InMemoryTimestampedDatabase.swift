import Foundation

/**
 A simple database implementation that only caches the latest values in memory
 */
public final class InMemoryTimestampedDatabase {

    /// A simple in-memory cache
    /// The values are sorted by their timestamps, the last value is the most recent
    /// The values are encoded, since otherwise it's not possible to insert values from other databases,
    /// because the type is only known when accessing the values
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
        cache[record.path] = record.sample
    }
}

extension InMemoryTimestampedDatabase: TimestampedDatabase {

    // MARK: Properties

    public func get<Value: DatabaseValue>(_ path: Path) -> Timestamped<Value>? {
        guard let raw = cache[path] else {
            return nil
        }
        guard let value: Value = decode(raw.data) else {
            return nil
        }
        return .init(value: value, date: raw.timestamp)
    }

    public func set<Value: DatabaseValue>(_ value: Value, for path: Path, at date: Date?) {
        let sample = EncodedSample(data: encode(value), timestamp: date)
        cache[path] = sample
        history.append(Record(path: path, sample: sample))
    }

    // MARK: Instances

    public func all<T>(model: ModelKey, where predicate: (InstanceKey, InstanceStatus, Date) -> T?) -> [T] {
        cache.compactMap { (path, sample) -> T? in
            guard path.model == model,
                  path.property == PropertyKey.instanceId,
                  let value: InstanceStatus = decode(sample.data) else {
                return nil
            }
            return predicate(path.instance, value, sample.timestamp)
        }
    }
}
