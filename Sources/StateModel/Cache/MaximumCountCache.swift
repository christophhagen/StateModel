import Foundation

/**
 A cache for arbitrary types with LRU eviction when the capacity is reached.

 A predefined fraction of all contained elements will be removed, based on their last access.
 */
public final class MaximumCountCache: DatabaseCache {

    private struct Entry {
        var value: Any
        var lastAccess: TimeInterval
    }

    private var storage: [Path : Entry] = [:]

    /// The total maximum of items
    private let maxCount: Int

    /// The maximum number of items after cleanup
    private let desiredCountAfterEviction: Int

    /// The number of items currently in the cache
    public var count: Int { storage.count }

    /**
     Create a new cache.

     Specify the maximum size and the ratio of the cache to keep for each cleanup.
     - Parameter maxCount: The maximum number of elements in the cache.
     - Parameter evictionFraction: The fraction of `maxCount` to evict once the cache reaches maximum capacity.
     */
    public convenience init(maxCount: Int = 1000, evictionFraction: Double = 0.2) {
        precondition(evictionFraction > 0 && evictionFraction <= 1, "evictionFraction must be in (0,1]")
        self.init(maxCount: maxCount, elementsToKeep: maxCount - Int(Double(maxCount) * evictionFraction))
    }

    /**
     Create a new cache.

     Specify the maximum size and the number of elements to keep when the maximum size is reached
     - Parameter maxCount: The maximum number of elements in the cache.
     - Parameter evictionFraction: The fraction of `maxCount` to evict once the cache reaches maximum capacity.
     */
    public init(maxCount: Int, elementsToKeep: Int) {
        precondition(maxCount > 0, "maxCount must be positive")
        precondition(elementsToKeep >= 0 && elementsToKeep < maxCount, "elementsToKeep must be in [0,maxCount)")
        self.maxCount = maxCount
        self.desiredCountAfterEviction = elementsToKeep
    }

    public func set<T: DatabaseValue>(_ value: T, for key: Path) {
        if storage.count >= maxCount {
            evictLeastRecentlyUsed()
        }

        let now = Date().timeIntervalSinceReferenceDate
        storage[key] = Entry(value: value, lastAccess: now)
    }

    public func get<Value: DatabaseValue>(_ path: Path) -> Value? {
        guard var entry = storage[path] else { return nil }
        entry.lastAccess = Date().timeIntervalSinceReferenceDate
        storage[path] = entry
        return entry.value as? Value
    }

    /**
     Remove the cache items that are least recently used,
     leaving only a specific number of items in the cache
     */
    private func evictLeastRecentlyUsed() {
        removeLeastRecentlyUsed(toReachCount: desiredCountAfterEviction)
    }

    /**
     Remove items from the cache to reach the specified count.

     The least recently accessed items will be removed.
     */
    public func removeLeastRecentlyUsed(toReachCount count: Int) {
        let removeCount = storage.count - count
        guard removeCount > 0 else { return }

        guard count > 0 else {
            removeAll()
            return
        }

        // Sort keys by lastAccess ascending (least recently used first)
        let sortedKeys = storage.keys.sorted {
            storage[$0]!.lastAccess < storage[$1]!.lastAccess
        }

        for key in sortedKeys.prefix(removeCount) {
            storage.removeValue(forKey: key)
        }
    }

    /**
     Remove all elements from the cache.
     */
    public func removeAll() {
        storage.removeAll()
    }
}
