import Foundation

/**
 A simple database wrapper that uses a cache to reduce queries to the database.
 */
public final class CachedTimestampedDatabase {

    public let database: any TimestampedDatabase

    public let cache: DatabaseCache

    /**
     Create a caching database.

     The cache is expected to manage its size.
     - Parameter database: The database to cache.
     - Parameter cache: The cache to use.
     */
    public init(wrapping database: any TimestampedDatabase, cache: DatabaseCache) {
        self.database = database
        self.cache = cache
    }
}

extension CachedTimestampedDatabase: TimestampedDatabase {

    public func get<Value: DatabaseValue>(_ path: Path) -> Timestamped<Value>? {
        cache.get(path) ?? database.get(path)
    }

    public func set<Value: DatabaseValue>(_ value: Value, for path: Path, at date: Date?) {
        let date = date ?? .init()
        // We only update the cache if the value is newer, or if there is no cached value
        if let cached: Timestamped<Value> = cache.get(path), cached.date > date {

        } else {
            // If we insert a value with a future timestamp (e.g. by inserting a value manually)
            // then the value would be returned if we call get() with a `nil` date.

            let entry = Timestamped(value: value, date: date)
            cache.set(entry, for: path)
        }
        // We don't provide the current date here,
        // because we want to preserve the information that the current time is inserted.
        // It may be important for some implementations
        database.set(value, for: path, at: date)
    }

    public func all<T>(model: ModelKey, where predicate: (_ instance: InstanceKey, _ status: InstanceStatus, _ date: Date) -> T?) -> [T] {
        database.all(model: model, where: predicate)
    }
}
