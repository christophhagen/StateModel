import Foundation
import Testing
import StateModel

private class CacheTestDatabase: HistoryDatabase {

    var numberOfSets = 0

    var numberOfGets = 0

    let db = InMemoryHistoryDatabase()

    func set<Value: DatabaseValue>(_ value: Value, for path: Path, at date: Date?) {
        db.set(value, for: path, at: date)
        numberOfSets += 1
    }
    
    func get<Value: DatabaseValue>(_ path: Path, at date: Date?) -> Timestamped<Value>? {
        numberOfGets += 1
        print("DB: \(path) at \(date)")
        return db.get(path, at: date)
    }
    
    func all<T>(model: ModelKey, at date: Date?, where predicate: (InstanceKey, InstanceStatus, Date) -> T?) -> [T] {
        db.all(model: model, at: date, where: predicate)
    }
}

private class TestCache: DatabaseCache {

    let cache: MaximumCountCache

    var numberOfSets = 0

    var numberOfGets = 0

    init(maxCount: Int = 1000, evictionFraction: Double = 0.2) {
        self.cache = .init(maxCount: maxCount, evictionFraction: evictionFraction)
    }

    func get<Value: DatabaseValue>(_ path: Path) -> Value? {
        numberOfGets += 1
        return cache.get(path)
    }
    
    func set<Value: DatabaseValue>(_ value: Value, for path: Path) {
        numberOfSets += 1
        cache.set(value, for: path)
    }
}

@Suite("Cache tests")
struct CacheTests {

    @Test("Access database once")
    func testAccessDatabaseOnce() async throws {
        let cache = MaximumCountCache(maxCount: 5)
        let uncached = CacheTestDatabase()
        let database = CachedDatabase(wrapping: uncached, cache: cache)

        #expect(uncached.numberOfGets == 0)
        #expect(uncached.numberOfSets == 0)

        let path = Path(model: 1, instance: 2, property: 3)
        database.set(123, for: path)

        #expect(uncached.numberOfSets == 1)
        #expect(uncached.numberOfGets == 0)

        // Get value from cache
        _ = database.get(path, of: Int.self)

        #expect(uncached.numberOfSets == 1)
        #expect(uncached.numberOfGets == 0)

        // Clear cache

        cache.removeAll()

        // Get value from database
        _ = database.get(path, of: Int.self)

        #expect(uncached.numberOfSets == 1)
        #expect(uncached.numberOfGets == 1)
    }

    @Test("Storage")
    func testStorageInCache() throws {
        let cache = MaximumCountCache(maxCount: 1000)
        let uncached = InMemoryDatabase()
        let database = CachedDatabase(wrapping: uncached, cache: cache)

        let path = Path(model: 1, instance: 1, property: 1)

        let value = "abc"
        database.set(value, for: path)
        #expect(cache.count == 1)

        let retrieved: String? = database.get(path)
        #expect(retrieved == value)

        struct Complex: Codable, Equatable {
            let a: Int
            let b: String
        }

        let value2 = Complex(a: 123, b: "abc")
        let path2 = Path(model: 1, instance: 1, property: 2)
        database.set(value2, for: path2)
        #expect(cache.count == 2)

        // change value in database, to see if it's returned from the cache
        let value3 = Complex(a: 456, b: "def")
        database.database.set(value3, for: path2)

        let retrieved2: Complex? = database.get(path2)
        #expect(retrieved2 == value2)

        // Clear the cache and get value from the database
        cache.removeAll()

        let retrieved3: Complex? = database.get(path2)
        #expect(retrieved3 == value3)
    }

    @Test("Eviction")
    func testCacheEviction() throws {
        let cache = MaximumCountCache(maxCount: 1000, evictionFraction: 0.5)
        let uncached = InMemoryDatabase()
        let database = CachedDatabase(wrapping: uncached, cache: cache)

        #expect(cache.count == 0)
        for value in 1...1000 {
            database.set(value, for: Path(model: 1, instance: 1, property: value))
        }

        #expect(cache.count == 1000)

        database.set(1, for: Path(model: 1, instance: 1, property: 1001))

        #expect(cache.count == 501)
    }

    @Test("Timestamped caching")
    func testTimestampedCaching() throws {
        let cache = TestCache(maxCount: 1000, evictionFraction: 0.5)
        let uncached = CacheTestDatabase()
        let database = CachedTimestampedDatabase(wrapping: uncached, cache: cache)

        #expect(cache.numberOfSets == 0)
        #expect(cache.numberOfGets == 0)
        #expect(uncached.numberOfSets == 0)
        #expect(uncached.numberOfGets == 0)

        // Write first value
        let path = Path(model: 1, instance: 2, property: 3)
        database.set(123, for: path, at: nil)

        #expect(cache.numberOfSets == 1)
        #expect(cache.numberOfGets == 1) // Cache check
        #expect(uncached.numberOfSets == 1)
        #expect(uncached.numberOfGets == 0)

        // Get value from cache
        do {
            let queried: Timestamped<Int>? = database.get(path)
            #expect(queried?.value == 123)
        }

        #expect(cache.numberOfSets == 1)
        #expect(cache.numberOfGets == 2)
        #expect(uncached.numberOfSets == 1)
        #expect(uncached.numberOfGets == 0)

        // Write past value
        database.set(42, for: path, at: Date().addingTimeInterval(-1))

        #expect(cache.numberOfSets == 1) // Not set due to older date
        #expect(cache.numberOfGets == 3) // Increment due to update check
        #expect(uncached.numberOfSets == 2) // Write old value
        #expect(uncached.numberOfGets == 0)

        // Get newer value from cache
        do {
            let queried: Timestamped<Int>? = database.get(path)
            #expect(queried?.value == 123)
        }

        #expect(cache.numberOfSets == 1)
        #expect(cache.numberOfGets == 4) // Increment due to cache check
        #expect(uncached.numberOfSets == 2)
        #expect(uncached.numberOfGets == 0)

        // Write future value
        // Write past value
        database.set(234, for: path, at: nil)

        #expect(cache.numberOfSets == 2) // Cache insert
        #expect(cache.numberOfGets == 5) // Increment due to update check
        #expect(uncached.numberOfSets == 3) // Write newer value
        #expect(uncached.numberOfGets == 0)

        // Get future value from cache
        do {
            let queried: Timestamped<Int>? = database.get(path)
            #expect(queried?.value == 234)
        }
    }

    @Test("History caching")
    func testHistoryCaching() throws {
        let cache = TestCache(maxCount: 1000, evictionFraction: 0.5)
        let uncached = CacheTestDatabase()
        let database = CachedHistoryDatabase(wrapping: uncached, cache: cache)

        #expect(cache.numberOfSets == 0)
        #expect(cache.numberOfGets == 0)
        #expect(uncached.numberOfSets == 0)
        #expect(uncached.numberOfGets == 0)

        let path = Path(model: 1, instance: 2, property: 3)
        database.set(123, for: path)

        #expect(cache.numberOfSets == 1)
        #expect(cache.numberOfGets == 0)
        #expect(uncached.numberOfSets == 1)
        #expect(uncached.numberOfGets == 0)

        // Get value from cache
        let queried = database.get(path, of: Int.self)
        #expect(queried == 123)

        #expect(cache.numberOfSets == 1)
        #expect(cache.numberOfGets == 1)
        #expect(uncached.numberOfSets == 1)
        #expect(uncached.numberOfGets == 0)

        let history = database.view(at: Date().addingTimeInterval(-100))
        let queried2: Int? = history.get(path)
        #expect(queried2 == nil)

        #expect(cache.numberOfSets == 1)
        #expect(cache.numberOfGets == 2)
        #expect(uncached.numberOfSets == 1)
        #expect(uncached.numberOfGets == 1)
    }

    @Test("Cache future values")
    func testCacheFutureValues() throws {
        let cache = TestCache(maxCount: 1000, evictionFraction: 0.5)
        let uncached = CacheTestDatabase()
        let database = CachedHistoryDatabase(wrapping: uncached, cache: cache)

        #expect(cache.numberOfSets == 0)
        #expect(cache.numberOfGets == 0)
        #expect(uncached.numberOfSets == 0)
        #expect(uncached.numberOfGets == 0)

        let path = Path(model: 1, instance: 2, property: 3)
        database.set(123, for: path)

        #expect(cache.numberOfSets == 1)
        #expect(cache.numberOfGets == 1) // Check cache for newer value before update
        #expect(uncached.numberOfSets == 1)
        #expect(uncached.numberOfGets == 0)

        // Get value from cache
        let queried = database.get(path, of: Int.self)
        #expect(queried == 123)

        #expect(cache.numberOfSets == 1)
        #expect(cache.numberOfGets == 2) // Increment due to cache check
        #expect(uncached.numberOfSets == 1)
        #expect(uncached.numberOfGets == 0)

        print("A")
        // Set a value in the future
        database.set(234, for: path, at: Date().addingTimeInterval(100))
        #expect(cache.numberOfSets == 2)
        #expect(cache.numberOfGets == 3) // Incremented due to insert comparison
        #expect(uncached.numberOfSets == 2) // Increment due to insert
        #expect(uncached.numberOfGets == 0)

        print("B")
        let queried2: Int? = database.get(path)
        // We expect the future value to be returned from the cache
        #expect(queried2 == 234)

        #expect(cache.numberOfSets == 2)
        #expect(cache.numberOfGets == 4) // Incremented due to cache check
        #expect(uncached.numberOfSets == 2)
        #expect(uncached.numberOfGets == 0)
    }
}
