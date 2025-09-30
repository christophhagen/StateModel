import Foundation

/**
 A simple database implementation that only caches the latest values in memory
 */
public final class InMemoryHistoryDatabase: HistoryDatabase {

    /// A simple in-memory cache
    /// The values are sorted by their timestamps, the last value is the most recent
    /// The values are encoded, since otherwise it's not possible to insert values from other databases,
    /// because the type is only known when accessing the values
    private var cache: [Path: [EncodedSample]] = [:]

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

    public func get<Value: DatabaseValue>(_ path: Path, at date: Date?) -> (value: Value, date: Date)? {
        guard let raw = cache[path]?.at(date) else {
            return nil
        }
        guard let value: Value = decode(raw.data) else {
            return nil
        }
        return (value, raw.timestamp)
    }

    public func set<Value: DatabaseValue>(_ value: Value, for path: Path, at date: Date?) {
        let sample = EncodedSample(data: encode(value), timestamp: date)
        // TODO: Prevent duplicates?
        cache[path, default: []].insert(sample)
        history.append(Record(path: path, sample: sample))
    }

    // MARK: Instances

    public func all<T>(model: ModelKey, at date: Date?, where predicate: (InstanceKey, InstanceStatus, Date) -> T?) -> [T] {
        cache.compactMap { (path, values) -> T? in
            guard path.model == model,
                  path.property == PropertyKey.instanceId,
                  let sample = values.at(date),
                  let value: InstanceStatus = decode(sample.data) else {
                return nil
            }
            return predicate(path.instance, value, sample.timestamp)
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
        if cache[record.path]?.contains(record.timestamp) ?? false {
            return
        }
        cache[record.path, default: []].insert(record.sample)
    }
}
