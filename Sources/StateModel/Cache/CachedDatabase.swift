
/**
 A simple database wrapper that uses a cache to reduce queries to the database.
 */
public final class CachedDatabase: Database {

    public let database: any Database

    public let cache: DatabaseCache

    /**
     Create a caching database.

     The cache is expected to manage its size.
     - Parameter database: The database to cache.
     - Parameter cache: The cache to use.
     */
    public init(wrapping database: any Database, cache: DatabaseCache) {
        self.database = database
        self.cache = cache
    }

    public func get<Value: DatabaseValue>(_ path: Path) -> Value? {
        cache.get(path) ?? database.get(path)
    }

    public func set<Value: DatabaseValue>(_ value: Value, for path: Path) {
        cache.set(value, for: path)
        database.set(value, for: path)
    }

    public func all<T>(model: ModelKey, where predicate: (InstanceKey, InstanceStatus) -> T?) -> [T] {
        database.all(model: model, where: predicate)
    }
}
