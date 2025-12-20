import Foundation

/**
 A simple database wrapper that uses a cache to reduce queries to the database.
 */
public final class CachedHistoryDatabase {

    public let database: any HistoryDatabase

    public let cache: DatabaseCache

    /**
     Create a caching database.

     The cache is expected to manage its size.
     - Parameter database: The database to cache.
     - Parameter cache: The cache to use.
     */
    public init(wrapping database: any HistoryDatabase, cache: DatabaseCache) {
        self.database = database
        self.cache = cache
    }
}

extension CachedHistoryDatabase: HistoryDatabase {

    public func get<Value: DatabaseValue>(_ path: Path, at date: Date?) -> Timestamped<Value>? {
        if let cached: Timestamped<Value> = cache.get(path) {
            if let date, cached.date > date {
                // If the specified date is before the cached value,
                // then the historic value must be queried from the database.
                return database.get(path, at: date)
            }
            // We return the cached value, if either the current date is specified,
            // or if the cached date is before the requested date, because we assume
            // that there is no newer value in the database.
            return cached
        }
        return database.get(path, at: date)
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

    public func all<T>(model: ModelKey, at date: Date?, where predicate: (_ instance: InstanceKey, _ status: InstanceStatus, _ date: Date) -> T?) -> [T] {
        database.all(model: model, at: date, where: predicate)
    }
}
