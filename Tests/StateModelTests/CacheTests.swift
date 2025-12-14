import Foundation
import Testing
import StateModel

private class CacheTestDatabase: Database {

    var numberOfSets = 0

    var numberOfGets = 0

    let db = InMemoryDatabase()

    func set<Value: DatabaseValue>(_ value: Value, for path: Path) {
        db.set(value, for: path)
        numberOfSets += 1
    }
    
    func get<Value: DatabaseValue>(_ path: Path) -> Value? {
        numberOfGets += 1
        return db.get(path)
    }
    
    func all<T>(model: ModelKey, where predicate: (InstanceKey, InstanceStatus) -> T?) -> [T] {
        db.all(model: model, where: predicate)
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
}
